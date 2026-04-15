import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'cairn_meta.dart';
import 'constants.dart';
import 'db/conversation_dao.dart';
import 'db/database.dart';
import 'library_provider.dart';
import 'persona_provider.dart';
import 'settings_provider.dart';
import 'streaming_chat_mixin.dart';
import 'title_deriver.dart';
import 'tools/tool_registry.dart';

/// Holds the currently-open conversation, its messages, and the
/// recent conversation list. Also owns the live-streaming assistant
/// reply while it's being generated.
///
/// Persistence: every user turn and every finalized assistant turn is
/// written to the [AppDatabase]. Streaming chunks update an in-memory
/// draft; the final text is committed to the DB on completion.
class ChatProvider extends ChangeNotifier {
  final AppDatabase _db;
  final ConversationDao _convDao;
  final SettingsProvider _settings;
  final LibraryProvider _library;
  final PersonaProvider _personas;
  final ToolRegistry _toolRegistry;
  final _uuid = const Uuid();

  ChatProvider(
    this._db,
    this._settings,
    this._library,
    this._personas,
    this._toolRegistry,
  ) : _convDao = ConversationDao(_db);

  // ---- public state ----

  /// Recent chat conversations (explain sessions are excluded).
  List<Conversation> conversations = const [];

  /// Messages of the currently open conversation.
  List<Message> messages = const [];

  /// Current conversation id, or null for a brand-new-unsaved chat.
  String? currentConversationId;

  bool loading = false;
  bool sending = false;
  String? lastError;

  /// Cancel handle for the in-flight assistant reply. Non-null while
  /// [sending] is true. UI stop button calls [abortCurrentReply].
  CancelToken? _activeCancelToken;

  bool get canAbort => sending && _activeCancelToken != null;

  /// Abort the currently-streaming assistant reply. Partial text is
  /// kept and committed as the final message in the background —
  /// [sending] flips to false immediately so the composer unlocks
  /// without waiting for the DB write to finish.
  void abortCurrentReply() {
    final token = _activeCancelToken;
    if (token == null) return;
    token.cancel();
    sending = false;
    activeToolStatus = null;
    _activeCancelToken = null;
    notifyListeners();
  }

  /// Non-null while tools are being executed during streaming.
  ToolStatus? activeToolStatus;

  /// Selected persona for the next new conversation.
  String? selectedPersonaId;

  /// Whether the currently-open conversation has older messages that
  /// haven't been loaded into [messages] yet. Set by
  /// [openConversation] / [loadMoreMessages] based on whether the
  /// most recent DB page was full; flipped to false once pagination
  /// exhausts the history.
  bool hasMoreOlderMessages = false;

  /// True while a [loadMoreMessages] call is in flight. The UI
  /// shows a spinner in the list header based on this flag.
  bool loadingMoreMessages = false;

  /// Message ids for which chat auto-save has already fired successfully.
  /// Used by the UI to render the save button as "already saved" without
  /// requerying the library. Populated lazily when a conversation is
  /// opened or when auto-save fires in-session. Cleared on
  /// [startNewConversation].
  final Set<String> autoSavedMsgIds = <String>{};

  /// Persona ID of the currently open conversation (null = legacy).
  String? _currentPersonaId;

  /// When set, the chat page should scroll to this message after opening.
  /// Consumed (cleared) by the UI once it scrolls.
  String? scrollToMessageId;

  /// Id of the user message whose assistant reply failed to generate.
  /// UI reads this to render a small retry button under that bubble.
  /// Cleared when the user retries or starts a new turn.
  String? failedUserMsgId;

  /// True when NO provider in settings has embedding capability AND the
  /// current conversation's user-question transcript is approaching the
  /// compress threshold. UI reads this to show a "start a new
  /// conversation" nudge tag above the composer. When any embedding
  /// provider exists, cross-conversation recall handles long context
  /// organically and this always returns false.
  bool get contextPressureWarn {
    final hasEmbedding = _settings.providers
        .any((p) => p.embeddingCapability == EmbeddingCapability.yes);
    if (hasEmbedding) return false;
    final userChars = messages
        .where((m) => m.role == MessageRole.user)
        .fold<int>(0, (s, m) => s + m.content.length);
    return userChars >= NoEmbedContext.warnChars;
  }

  /// Request navigation to a specific conversation + message.
  /// The UI layer listens for this and switches to the chat tab.
  bool pendingNavigation = false;

  /// Open a conversation and request scroll to a specific message.
  Future<void> navigateToMessage(String convId, String? msgId) async {
    await openConversation(convId);
    scrollToMessageId = msgId;
    pendingNavigation = true;
    notifyListeners();
  }

  // ---- loading ----

  Future<void> loadConversations() async {
    conversations = await _convDao.recentChats();
    notifyListeners();
  }

  /// DB-level conversation search (replaces in-memory filtering).
  Future<List<Conversation>> searchConversations(String query) =>
      _convDao.searchChats(query);

  /// Search message content across all conversations. Returns
  /// results with conversation info, matched message id, and snippet.
  Future<List<ChatSearchResult>> searchMessageContent(String query) =>
      _convDao.searchMessageContent(query);

  Future<void> openConversation(String id) async {
    currentConversationId = id;
    loading = true;
    hasMoreOlderMessages = false;
    loadingMoreMessages = false;
    failedUserMsgId = null;
    notifyListeners();

    // Load only the most recent page. For conversations shorter
    // than [ConversationDao.messagePageSize] this is the whole
    // conversation; for longer ones the user scrolls up to trigger
    // [loadMoreMessages].
    messages = await _convDao.latestMessages(id);
    hasMoreOlderMessages = messages.length == ConversationDao.messagePageSize;

    final conv = await _convDao.getById(id);
    _currentPersonaId = conv?.personaId;
    // Populate autoSavedMsgIds so the UI renders the saved bookmark
    // for messages that are currently in the user's Library. Only
    // in_library=true rows count — silently auto-captured knowledge
    // (in_library=false) should leave the bubble bookmark unfilled.
    autoSavedMsgIds.clear();
    final assistantIds = messages
        .where((m) => m.role == MessageRole.assistant)
        .map((m) => m.id)
        .toList();
    if (assistantIds.isNotEmpty) {
      final savedIds = await _library.inLibraryMsgIds(assistantIds);
      autoSavedMsgIds.addAll(savedIds);
    }
    loading = false;
    notifyListeners();
  }

  /// Prepend the previous [ConversationDao.messagePageSize] messages
  /// to [messages]. Triggered by [ChatPage] when the user scrolls
  /// near the top of the list. Idempotent-on-concurrent-calls: a
  /// second invocation while one is in flight is a no-op.
  ///
  /// UI concerns (preserving scroll position so the viewport
  /// doesn't jump) are handled by the caller — ChatPage measures
  /// `maxScrollExtent` before and after and applies the delta.
  Future<void> loadMoreMessages() async {
    final convId = currentConversationId;
    if (convId == null) return;
    if (!hasMoreOlderMessages) return;
    if (loadingMoreMessages) return;
    if (messages.isEmpty) return;

    loadingMoreMessages = true;
    notifyListeners();

    try {
      final cursor = messages.first.createdAt;
      final older =
          await _convDao.messagesOlderThan(convId, cursor);
      if (older.isEmpty) {
        hasMoreOlderMessages = false;
      } else {
        messages = [...older, ...messages];
        hasMoreOlderMessages =
            older.length == ConversationDao.messagePageSize;

        // Lazy autoSavedMsgIds population for the new page. We only
        // need this for assistant messages — user messages never
        // carry a saved_item row.
        final newAssistantIds = older
            .where((m) => m.role == MessageRole.assistant)
            .map((m) => m.id)
            .toList();
        if (newAssistantIds.isNotEmpty) {
          final savedIds = await _library.inLibraryMsgIds(newAssistantIds);
          autoSavedMsgIds.addAll(savedIds);
        }
      }
    } finally {
      loadingMoreMessages = false;
      notifyListeners();
    }
  }

  void startNewConversation() {
    currentConversationId = null;
    _currentPersonaId = null;
    messages = const [];
    lastError = null;
    failedUserMsgId = null;
    autoSavedMsgIds.clear();
    hasMoreOlderMessages = false;
    loadingMoreMessages = false;
    notifyListeners();
  }

  void selectPersona(String? personaId) {
    selectedPersonaId = personaId;
    notifyListeners();
  }

  // ---- sending ----

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    // New sends while a reply is streaming are blocked at the UI
    // layer — the send button becomes a stop button. Defensive guard
    // here keeps a second call from racing the in-flight turn.
    if (sending) return;
    // Starting a fresh turn clears any retry-pending state from the
    // previous failure.
    failedUserMsgId = null;

    final (provider, model) = StreamingChatMixin.resolveProvider(_settings);

    sending = true;
    lastError = null;
    final token = CancelToken();
    _activeCancelToken = token;

    try {
      // Create the conversation row on first send.
      final isNewConversation = currentConversationId == null;
      final convId = currentConversationId ??= _uuid.v4();
      final now = DateTime.now();
      if (isNewConversation) {
        // Lock in the persona for this conversation.
        _currentPersonaId =
            selectedPersonaId ?? _personas.defaultPersona?.id;
        await _db.into(_db.conversations).insert(
              ConversationsCompanion.insert(
                id: convId,
                title: Value(_deriveTitle(trimmed)),
                personaId: Value(_currentPersonaId),
                providerId: Value(provider.id),
                model: Value(model),
                createdAt: now,
                updatedAt: now,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }

      // Immediately show user message + assistant draft in the UI so the
      // user doesn't stare at a blank screen while we assemble the prompt.
      final userMsg = Message(
        id: _uuid.v4(),
        conversationId: convId,
        role: MessageRole.user,
        content: trimmed,
        createdAt: now,
      );
      final draftId = _uuid.v4();
      final draftMsg = Message(
        id: draftId,
        conversationId: convId,
        role: MessageRole.assistant,
        content: '',
        createdAt: now,
      );
      messages = [...messages, userMsg, draftMsg];
      notifyListeners();

      // Persist user message and recall related items in parallel.
      // The DB insert is fast (~1ms) but recall involves a network
      // call to the embedding API (~100-300ms) — running them
      // concurrently shaves that off the total latency.
      final recallFuture = _library.recallRelated(trimmed);
      await _db.into(_db.messages).insert(userMsg);
      final recalled = await recallFuture;
      final systemPrompt = _buildSystemPrompt(
        recallContext: LibraryProvider.formatRecallContext(recalled),
      );

      // Resolve enabled tools.
      final enabledNames = _settings.enabledToolNames(
        _toolRegistry.allTools
            .map((t) => (name: t.name, enabledByDefault: t.enabledByDefault))
            .toList(),
      );

      final hasEmbeddingFallback = _settings.providers
          .any((p) => p.embeddingCapability == EmbeddingCapability.yes);

      final finalContent = await StreamingChatMixin.streamAndCommit(
        db: _db,
        conversationId: convId,
        userText: trimmed,
        systemPrompt: systemPrompt,
        existingMessages: messages,
        provider: provider,
        model: model,
        draftId: draftId,
        // UI callbacks no-op once the turn is aborted — abort flips
        // sending=false immediately and the partial commit continues
        // in the background; we must not overwrite whatever the user
        // has moved on to (a new turn's messages/tool status/error).
        onMessagesChanged: (msgs) {
          if (token.isCancelled) return;
          messages = msgs;
          notifyListeners();
        },
        onUsage: (u) => _settings.recordUsage(u,
            providerId: provider.id, model: model, kind: UsageKind.chat),
        onError: (err) {
          if (token.isCancelled) return;
          lastError = err;
          failedUserMsgId = userMsg.id;
        },
        toolRegistry: enabledNames.isNotEmpty ? _toolRegistry : null,
        enabledToolNames: enabledNames,
        onToolStatus: (status) {
          if (token.isCancelled) return;
          activeToolStatus = status.kind == ToolStatusKind.done ? null : status;
          notifyListeners();
        },
        hasEmbeddingFallback: hasEmbeddingFallback,
        cancelToken: token,
      );
      if (!token.isCancelled) activeToolStatus = null;

      // Auto-save the assistant reply to the library when it carries a
      // cairn-meta knowledge block that the model marked as worth
      // remembering. This is the P0-1 core flow — users no longer need to
      // manually tap "save" on every reply worth keeping.
      if (finalContent != null && finalContent.isNotEmpty) {
        // Fire-and-forget: auto-save is best-effort and should not
        // delay the UI from becoming interactive after the reply.
        unawaited(_autoSaveIfWorthIt(
          conversationId: convId,
          messageId: draftId,
          userQuestion: trimmed,
          content: finalContent,
        ));
      }
    } catch (e) {
      if (!token.isCancelled) {
        lastError = '$e';
        failedUserMsgId =
            currentConversationId != null && messages.isNotEmpty &&
                    messages.last.role == MessageRole.user
                ? messages.last.id
                : failedUserMsgId;
      }
    } finally {
      // Only clear top-level state when this is still the active
      // turn. After abortCurrentReply() a new turn may already own
      // [_activeCancelToken]; we must not clobber its [sending] flag
      // or token reference when the background partial-commit
      // eventually returns here.
      if (identical(_activeCancelToken, token)) {
        sending = false;
        _activeCancelToken = null;
        notifyListeners();
      }
      await loadConversations();
    }
  }

  /// Retry the last failed user turn. Drops the previously-persisted
  /// user message and re-runs [sendMessage] from scratch so the
  /// existing pipeline (recall, tools, streaming) is reused as-is.
  Future<void> retryFailedSend() async {
    if (sending) return;
    final failedId = failedUserMsgId;
    if (failedId == null) return;
    final idx = messages.indexWhere((m) => m.id == failedId);
    if (idx < 0) {
      failedUserMsgId = null;
      notifyListeners();
      return;
    }
    final text = messages[idx].content;
    await _convDao.deleteMessage(failedId);
    messages = messages.where((m) => m.id != failedId).toList();
    failedUserMsgId = null;
    lastError = null;
    notifyListeners();
    await sendMessage(text);
  }

  /// Delete the last assistant message and re-request a reply for the
  /// preceding user turn.
  Future<void> regenerateLast() async {
    if (messages.isEmpty || messages.last.role != MessageRole.assistant) return;
    final last = messages.last;
    await _convDao.deleteMessage(last.id);
    messages = messages.take(messages.length - 1).toList();
    notifyListeners();

    final lastUser = messages.lastWhere(
      (m) => m.role == MessageRole.user,
      orElse: () => Message(
        id: '',
        conversationId: '',
        role: MessageRole.user,
        content: '',
        createdAt: DateTime.now(),
      ),
    );
    if (lastUser.id.isEmpty) return;
    await _convDao.deleteMessage(lastUser.id);
    messages = messages.where((m) => m.id != lastUser.id).toList();
    notifyListeners();
    await sendMessage(lastUser.content);
  }

  Future<void> editUserMessage(String messageId, String newText) async {
    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx < 0 || messages[idx].role != 'user') return;
    final convId = messages[idx].conversationId;

    final toRemove = messages.sublist(idx).map((m) => m.id).toList();
    await _convDao.deleteMessages(toRemove);
    messages = messages.sublist(0, idx);
    currentConversationId = convId;
    notifyListeners();

    await sendMessage(newText);
  }

  Future<void> deleteMessage(String messageId) async {
    await _convDao.deleteMessage(messageId);
    messages = messages.where((m) => m.id != messageId).toList();
    notifyListeners();
  }

  Future<void> deleteConversation(String id) async {
    // Clean up auto-captured knowledge pool items that originated
    // from this conversation. User-promoted Library items survive.
    await _library.deletePoolItemsByConvId(id);
    await _convDao.deleteWithMessages(id);
    if (currentConversationId == id) {
      startNewConversation();
    }
    await loadConversations();
  }

  Future<void> hideConversation(String id) async {
    await _convDao.archive(id);
    if (currentConversationId == id) {
      startNewConversation();
    }
    await loadConversations();
  }

  // ---- helpers ----

  String _buildSystemPrompt({String recallContext = ''}) {
    final aboutMe = _settings.aboutMe.trim();
    final activePersonaId = selectedPersonaId ?? _personas.defaultPersona?.id;
    final persona = _personas.byId(activePersonaId);
    final personaInstruction = persona?.instruction.trim() ?? '';

    final buf = StringBuffer();
    if (aboutMe.isNotEmpty) {
      buf.writeln('The following is a note from the user about themselves. '
          'Use it to tailor your replies.');
      buf.writeln();
      buf.writeln(aboutMe);
      buf.writeln();
    }
    if (personaInstruction.isNotEmpty) {
      buf.writeln(personaInstruction);
      buf.writeln();
    }
    if (recallContext.isNotEmpty) {
      buf.writeln(recallContext);
      buf.writeln();
    }
    buf.write(cairnMetaSystemInstruction);
    return buf.toString().trim();
  }

  static const _maxTitleLength = TitleLimits.fallback;

  String _deriveTitle(String firstMessage) {
    final t = firstMessage.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.length > _maxTitleLength
        ? '${t.substring(0, _maxTitleLength)}…'
        : t;
  }

  /// Parse the assistant reply's cairn-meta block and, if the model
  /// flagged it as worth remembering, write the item into the
  /// knowledge pool with `in_library = false`. The row contributes to
  /// embedding-based cross-conversation recall but stays invisible in
  /// the Library UI — only explicit user action (tapping the bookmark)
  /// promotes it to the Library.
  ///
  /// Safe to call on any assistant message — bails out cleanly when:
  ///   - No cairn-meta block was present (conversational reply).
  ///   - Meta block was present but `reviewable: false`.
  ///   - A saved_item already exists for this message (defensive).
  ///   - saveItem throws (chat flow should never break because of
  ///     auto-save failures).
  Future<void> _autoSaveIfWorthIt({
    required String conversationId,
    required String messageId,
    required String userQuestion,
    required String content,
  }) async {
    try {
      final parsed = parseCairnMeta(content);
      if (parsed.meta == null) return;
      if (parsed.meta!.reviewable == false) return;

      // If the message already has a row in saved_items (either an
      // earlier auto-capture or a manual save), do nothing — we never
      // want to overwrite existing state or duplicate.
      final existing = await _library.findBySourceMsgId(messageId);
      if (existing != null) return;

      final title = parsed.meta?.title ??
          TitleDeriver.fromChatContext(
            precedingUserQuestion: userQuestion,
            body: parsed.body,
            emptyFallback: TitleDeriver.truncate(parsed.body,
                maxLength: TitleLimits.fallback),
          );

      await _library.saveItem(
        title: title,
        body: parsed.body,
        sourceConvId: conversationId,
        sourceMsgId: messageId,
        meta: parsed.meta,
        inLibrary: false, // knowledge pool only, NOT visible in Library
      );
      // Note: we do NOT add the message id to [autoSavedMsgIds]. That
      // set tracks "message is manually in the library" — the chat
      // bubble bookmark should stay in the unsaved state for auto-
      // captured rows so the user can later explicitly promote them.
    } catch (e) {
      // Auto-save is best-effort — never let it surface to the user or
      // break the chat flow. Log to debug output so the issue is still
      // visible during development.
      debugPrint('[ChatProvider] auto-save failed: $e');
    }
  }
}
