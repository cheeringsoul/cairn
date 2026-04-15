import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'constants.dart';
import 'db/database.dart';
import 'llm/llm_provider.dart';
import 'llm/provider_factory.dart';
import 'platform_utils.dart';
import 'settings_provider.dart';
import 'tools/tool_executor.dart';
import 'tools/tool_registry.dart';

// ---------------------------------------------------------------------------
// Tool status — reported to the UI during tool execution.
// ---------------------------------------------------------------------------

/// Lets callers abort a streaming reply mid-flight. Cancelling keeps
/// whatever text was produced so far and commits it as the final
/// assistant message, rather than dropping the draft.
class CancelToken {
  bool _cancelled = false;
  void Function()? _onCancel;
  bool get isCancelled => _cancelled;
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _onCancel?.call();
  }

  void _bind(void Function() onCancel) {
    _onCancel = onCancel;
    if (_cancelled) onCancel();
  }
}

enum ToolStatusKind { executing, done }

class ToolStatus {
  final ToolStatusKind kind;
  final List<String> toolNames;
  const ToolStatus(this.kind, this.toolNames);

  const ToolStatus.executing(this.toolNames) : kind = ToolStatusKind.executing;
  const ToolStatus.done() : kind = ToolStatusKind.done, toolNames = const [];
}

/// Shared streaming-chat logic used by both [ChatProvider] and
/// [ExplainController]. Eliminates the duplicated insert-user-msg →
/// create-draft → stream-chunks → commit-final → error-handling pattern.
mixin StreamingChatMixin {
  static const _uuid = Uuid();

  /// Resolve the active provider config and model from settings.
  static (ProviderConfig, String) resolveProvider(SettingsProvider settings) {
    final provider = settings.providers.firstWhere(
      (p) => p.id == settings.defaultProviderId,
      orElse: () => settings.providers.isNotEmpty
          ? settings.providers.first
          : throw StateError('No provider configured'),
    );
    final model = settings.defaultModel.isNotEmpty
        ? settings.defaultModel
        : provider.defaultModel;
    return (provider, model);
  }

  /// Run the full stream-and-commit cycle:
  ///   1. Insert user message to DB
  ///   2. Create in-memory draft assistant message
  ///   3. Stream LLM chunks, updating draft via [onMessagesChanged]
  ///   4. Commit final assistant message to DB
  ///   5. Update conversation's updatedAt
  ///
  /// When [draftId] is provided the caller has already appended the user
  /// message and an empty assistant draft to [existingMessages] and
  /// persisted the user message to DB — steps 1 & 2 are skipped so the
  /// user message appears in the UI without waiting for prompt assembly.
  ///
  /// When [toolRegistry] is provided and non-null, the model may invoke
  /// tools. The mixin handles the multi-round loop: stream → collect
  /// tool calls → execute → append results → re-stream. Tool-call
  /// messages are transient and not persisted to the database.
  ///
  /// [enabledToolNames] filters which tools from the registry are
  /// actually offered to the model.
  ///
  /// Returns the final assistant content, or null on error (error is
  /// stored in [errorOut]).
  static Future<String?> streamAndCommit({
    required AppDatabase db,
    required String conversationId,
    required String userText,
    required String systemPrompt,
    required List<Message> existingMessages,
    required ProviderConfig provider,
    required String model,
    required void Function(List<Message> messages) onMessagesChanged,
    required void Function(TokenUsage usage) onUsage,
    required void Function(String? error) onError,
    String? draftId,
    ToolRegistry? toolRegistry,
    Set<String>? enabledToolNames,
    void Function(ToolStatus status)? onToolStatus,
    bool hasEmbeddingFallback = true,
    CancelToken? cancelToken,
  }) async {
    List<Message> msgs;
    final String activeDraftId;

    if (draftId != null) {
      // Caller already showed user message + draft in the UI.
      msgs = List.of(existingMessages);
      activeDraftId = draftId;
    } else {
      final now = DateTime.now();

      // 1. Persist user message.
      final userMsg = Message(
        id: _uuid.v4(),
        conversationId: conversationId,
        role: 'user',
        content: userText,
        createdAt: now,
      );
      await db.into(db.messages).insert(userMsg);
      msgs = [...existingMessages, userMsg];

      // 2. Create draft assistant message.
      activeDraftId = _uuid.v4();
      msgs = [
        ...msgs,
        Message(
          id: activeDraftId,
          conversationId: conversationId,
          role: 'assistant',
          content: '',
          createdAt: DateTime.now(),
        ),
      ];
      onMessagesChanged(msgs);
    }

    try {
      final adapter = await buildProvider(provider);
      final executor =
          toolRegistry != null ? ToolExecutor(toolRegistry) : null;

      // Tool definitions to send with the request.
      final toolDefs = toolRegistry != null && enabledToolNames != null
          ? toolRegistry.definitionsFor(enabledToolNames)
          : <ToolDefinition>[];

      // Build the LLM message history. We maintain a separate list
      // that includes transient tool-call messages (not persisted).
      //
      // When NO provider in the user's settings has embedding
      // capability, cross-conversation recall is silently disabled and
      // the full transcript is otherwise sent verbatim each turn. To
      // keep the window bounded we (a) drop past assistant turns — the
      // user's questions carry the intent trail — and (b) summarize
      // the older user turns once the transcript exceeds a char
      // threshold.
      final persisted = msgs.take(msgs.length - 1).toList(); // drop draft
      var history = hasEmbeddingFallback
          ? persisted
              .map((m) => LlmMessage(role: m.role, content: m.content))
              .toList()
          : await _buildUserOnlyHistory(persisted, adapter, model);

      // 3. Multi-round stream loop.
      final buffer = StringBuffer();
      final collectedActionLinks = <Map<String, String>>[];
      const maxToolRounds = 5;

      var aborted = false;
      for (var round = 0; round <= maxToolRounds; round++) {
        if (cancelToken?.isCancelled ?? false) {
          aborted = true;
          break;
        }
        final pendingToolCalls = <ToolCall>[];

        final completer = Completer<void>();
        StreamSubscription<StreamEvent>? sub;
        sub = adapter
            .streamChat(
          messages: history,
          model: model,
          systemPrompt: systemPrompt,
          tools: toolDefs.isNotEmpty ? toolDefs : null,
          onUsage: onUsage,
        )
            .listen(
          (event) {
            switch (event) {
              case TextDelta(:final text):
                buffer.write(text);
                final updated = Message(
                  id: activeDraftId,
                  conversationId: conversationId,
                  role: 'assistant',
                  content: buffer.toString(),
                  createdAt: DateTime.now(),
                );
                msgs[msgs.length - 1] = updated;
                onMessagesChanged(msgs);

              case ToolCallDelta(:final toolCall):
                pendingToolCalls.add(toolCall);
            }
          },
          onError: (Object e, StackTrace st) {
            if (!completer.isCompleted) completer.completeError(e, st);
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete();
          },
          cancelOnError: true,
        );
        cancelToken?._bind(() {
          sub?.cancel();
          if (!completer.isCompleted) completer.complete();
        });

        await completer.future;

        if (cancelToken?.isCancelled ?? false) {
          aborted = true;
          break;
        }

        // No tool calls → model finished its text reply.
        if (pendingToolCalls.isEmpty || executor == null) break;

        // Notify UI: tools are being executed.
        onToolStatus?.call(ToolStatus.executing(
          pendingToolCalls.map((tc) => tc.name).toList(),
        ));

        // Append assistant message with tool calls to history.
        history.add(LlmMessage(
          role: 'assistant',
          content: buffer.toString(),
          toolCalls: pendingToolCalls,
        ));

        // Execute tools in parallel.
        final results = await executor.executeAll(pendingToolCalls);
        for (final r in results) {
          // Harvest any action_links the tool wants rendered as
          // tap-to-open buttons after the assistant reply.
          try {
            final parsed = jsonDecode(r.content);
            if (parsed is Map && parsed['action_links'] is List) {
              for (final link in parsed['action_links'] as List) {
                if (link is Map &&
                    link['label'] is String &&
                    link['url'] is String) {
                  final url = link['url'] as String;
                  if (!isUrlOpenableHere(url)) continue;
                  collectedActionLinks.add({
                    'label': link['label'] as String,
                    'url': url,
                  });
                }
              }
            }
          } catch (_) {}
          history.add(LlmMessage(
            role: 'tool',
            content: r.content,
            toolCallId: r.callId,
          ));
        }

        onToolStatus?.call(const ToolStatus.done());

        // Clear buffer — the model will generate a fresh response
        // incorporating the tool results. We keep what's in the
        // buffer so far as the "pre-tool" text and let the model
        // continue from there.
        // Note: we do NOT clear the buffer. The model may have
        // produced text before the tool call, and the next round
        // continues from where it left off.
      }

      // 4. Commit final message. Skip persistence (and drop the draft
      // from the UI) when the assistant produced no text — e.g. all
      // tool rounds failed. Otherwise the empty row pollutes the next
      // turn's history and makes the model resume the dead task.
      var finalContent = buffer.toString().trim();
      if (finalContent.isEmpty) {
        if (!aborted) {
          onError('No response generated. Please try again.');
        }
        onMessagesChanged(
            msgs.where((m) => m.id != activeDraftId).toList());
        return null;
      }

      // Append action-link buttons collected from tool results.
      // Skipped on abort — the reply was cut off mid-stream and action
      // links may reference tool calls that never got to run.
      if (!aborted && collectedActionLinks.isNotEmpty) {
        final buttons = collectedActionLinks
            .map((l) => '- [${l['label']}](${l['url']})')
            .join('\n');
        finalContent = '$finalContent\n\n$buttons';
        msgs[msgs.length - 1] = Message(
          id: activeDraftId,
          conversationId: conversationId,
          role: 'assistant',
          content: finalContent,
          createdAt: DateTime.now(),
        );
      }
      final finalMsg = Message(
        id: activeDraftId,
        conversationId: conversationId,
        role: 'assistant',
        content: finalContent,
        createdAt: DateTime.now(),
      );
      await db.into(db.messages).insert(finalMsg);

      // 5. Touch conversation timestamp.
      await (db.update(db.conversations)
            ..where((c) => c.id.equals(conversationId)))
          .write(ConversationsCompanion(updatedAt: Value(DateTime.now())));

      onMessagesChanged(msgs);
      return finalContent;
    } on LlmException catch (e) {
      return await _commitPartialOnError(
        db: db,
        conversationId: conversationId,
        activeDraftId: activeDraftId,
        msgs: msgs,
        partial: msgs.last.content,
        errorMessage: e.message,
        onMessagesChanged: onMessagesChanged,
        onError: onError,
      );
    } catch (e) {
      return await _commitPartialOnError(
        db: db,
        conversationId: conversationId,
        activeDraftId: activeDraftId,
        msgs: msgs,
        partial: msgs.last.content,
        errorMessage: '$e',
        onMessagesChanged: onMessagesChanged,
        onError: onError,
      );
    }
  }

  /// Persist whatever the assistant managed to stream before the
  /// failure, so the user keeps the partial text they already saw in
  /// the UI. Drops the draft only when nothing was produced at all.
  static Future<String?> _commitPartialOnError({
    required AppDatabase db,
    required String conversationId,
    required String activeDraftId,
    required List<Message> msgs,
    required String partial,
    required String errorMessage,
    required void Function(List<Message>) onMessagesChanged,
    required void Function(String?) onError,
  }) async {
    onError(errorMessage);
    final trimmed = partial.trim();
    if (trimmed.isEmpty) {
      onMessagesChanged(msgs.where((m) => m.id != activeDraftId).toList());
      return null;
    }
    final finalMsg = Message(
      id: activeDraftId,
      conversationId: conversationId,
      role: 'assistant',
      content: trimmed,
      createdAt: DateTime.now(),
    );
    try {
      await db.into(db.messages).insert(finalMsg);
      await (db.update(db.conversations)
            ..where((c) => c.id.equals(conversationId)))
          .write(ConversationsCompanion(updatedAt: Value(DateTime.now())));
    } catch (_) {
      // Best-effort persistence — the in-memory message is still
      // shown to the user even if the DB write fails.
    }
    msgs[msgs.length - 1] = finalMsg;
    onMessagesChanged(msgs);
    return trimmed;
  }

  // --- No-embedding context strategy -------------------------------------

  static Future<List<LlmMessage>> _buildUserOnlyHistory(
    List<Message> persisted,
    LlmProvider adapter,
    String model,
  ) async {
    final userMsgs =
        persisted.where((m) => m.role == MessageRole.user).toList();
    if (userMsgs.isEmpty) return const [];

    final total = userMsgs.fold<int>(0, (s, m) => s + m.content.length);
    if (total <= NoEmbedContext.compressChars ||
        userMsgs.length <= NoEmbedContext.keepRecentTurns) {
      return userMsgs
          .map((m) => LlmMessage(role: MessageRole.user, content: m.content))
          .toList();
    }

    final olderCount = userMsgs.length - NoEmbedContext.keepRecentTurns;
    final older = userMsgs.take(olderCount).toList();
    final recent = userMsgs.skip(olderCount).toList();
    final summary = await _summarizeOlder(adapter, model, older);
    return [
      LlmMessage(
        role: MessageRole.user,
        content: '[历史对话摘要 — 覆盖前 ${older.length} 条用户提问]\n$summary',
      ),
      ...recent
          .map((m) => LlmMessage(role: MessageRole.user, content: m.content)),
    ];
  }

  static Future<String> _summarizeOlder(
    LlmProvider adapter,
    String model,
    List<Message> older,
  ) async {
    final transcript = older
        .map((m) => '- ${m.content.replaceAll('\n', ' ')}')
        .join('\n');
    final buf = StringBuffer();
    try {
      await for (final ev in adapter.streamChat(
        messages: [
          LlmMessage(
            role: MessageRole.user,
            content:
                '请用不超过 200 字的要点列表，概括下列用户历史提问的主题、关键事实与意图。不要回答这些问题，只做压缩：\n\n$transcript',
          ),
        ],
        model: model,
        systemPrompt:
            'You compress chat history. Output a terse bullet list in the user\'s language. No preamble.',
      )) {
        if (ev is TextDelta) buf.write(ev.text);
      }
    } catch (_) {
      // Summary call failed — fall back to a naive truncation so the
      // turn still proceeds without the full older history.
      final cap = transcript.length > 2000 ? 2000 : transcript.length;
      return transcript.substring(0, cap);
    }
    final s = buf.toString().trim();
    if (s.isNotEmpty) return s;
    final cap = transcript.length > 2000 ? 2000 : transcript.length;
    return transcript.substring(0, cap);
  }
}

