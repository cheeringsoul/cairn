import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'cairn_meta.dart';
import 'constants.dart';
import 'db/database.dart';
import 'library_provider.dart';
import 'settings_provider.dart';
import 'streaming_chat_mixin.dart';

/// A short-lived controller that owns a single explain session (the
/// word-lookup workbench conversation).
///
/// Each time the user taps "AI detailed explanation →" on the word
/// lookup sheet, we create one of these. It:
///   - creates a conversation row with kind='explain' and origin_* set
///   - injects the settings-configured template as the first user
///     message (replacing {word})
///   - streams the assistant reply
///   - lets the user follow up in the same session
///   - lets the user save the result into the Library (vocab folder)
///
/// Cleanup: explain sessions with no saved items and no activity in
/// 7 days are deleted on app launch (see AppDatabase cleanup hook).
class ExplainController extends ChangeNotifier {
  final AppDatabase _db;
  final SettingsProvider _settings;
  final LibraryProvider _library;
  final _uuid = const Uuid();

  final String word;
  final String? originConvId;
  final String? originMsgId;
  final String? originHighlight;

  late final String conversationId;
  List<Message> messages = const [];
  bool sending = false;
  bool initialized = false;
  String? lastError;

  /// The message id of the initial explain prompt. The UI uses this
  /// to display a shortened label instead of the full prompt template.
  String? initialPromptMsgId;

  ExplainController({
    required AppDatabase db,
    required SettingsProvider settings,
    required LibraryProvider library,
    required this.word,
    this.originConvId,
    this.originMsgId,
    this.originHighlight,
  })  : _db = db,
        _settings = settings,
        _library = library;

  /// Create the session and fire off the initial explain prompt.
  Future<void> start() async {
    if (initialized) return;
    initialized = true;

    conversationId = _uuid.v4();
    final now = DateTime.now();

    final (provider, model) = StreamingChatMixin.resolveProvider(_settings);

    await _db.into(_db.conversations).insert(
          ConversationsCompanion.insert(
            id: conversationId,
            title: Value('🔍 $word'),
            kind: const Value(ConversationKind.explain),
            providerId: Value(provider.id),
            model: Value(model),
            originConvId: Value(originConvId),
            originMsgId: Value(originMsgId),
            originHighlight: Value(originHighlight),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final prompt = _settings.explainPromptTemplate.replaceAll('{word}', word);
    initialPromptMsgId = _uuid.v4();
    await _send(prompt, userMsgId: initialPromptMsgId!, skipRecall: true);
  }

  /// Follow-up question within the same explain session.
  Future<void> askFollowUp(String text) async {
    if (sending) return;
    await _send(text.trim());
  }

  Future<void> _send(
    String text, {
    String? userMsgId,
    bool skipRecall = false,
  }) async {
    sending = true;
    lastError = null;
    notifyListeners();

    try {
      final (provider, model) = StreamingChatMixin.resolveProvider(_settings);
      final now = DateTime.now();

      // Immediately show user message + assistant draft in the UI.
      // The full prompt text is stored for AI history; the UI page
      // handles displaying a shortened version for the initial query.
      final userMsg = Message(
        id: userMsgId ?? _uuid.v4(),
        conversationId: conversationId,
        role: MessageRole.user,
        content: text,
        createdAt: now,
      );
      final draftId = _uuid.v4();
      final draftMsg = Message(
        id: draftId,
        conversationId: conversationId,
        role: MessageRole.assistant,
        content: '',
        createdAt: now,
      );
      messages = [...messages, userMsg, draftMsg];
      notifyListeners();

      // Persist user message to DB.
      await _db.into(_db.messages).insert(userMsg);

      // Build system prompt. Skip recall for the initial explain
      // request (just a dictionary lookup, no need to search the
      // knowledge base). Follow-up questions do recall normally.
      String recallContext = '';
      if (!skipRecall) {
        final recalled = await _library.recallRelated(text);
        recallContext = LibraryProvider.formatRecallContext(recalled);
      }
      final aboutMe = _settings.aboutMe.trim();
      final sysBuf = StringBuffer();
      if (aboutMe.isNotEmpty) {
        sysBuf.writeln(aboutMe);
        sysBuf.writeln();
      }
      if (recallContext.isNotEmpty) {
        sysBuf.writeln(recallContext);
        sysBuf.writeln();
      }
      sysBuf.write(cairnMetaSystemInstruction);
      final systemPrompt = sysBuf.toString().trim();

      await StreamingChatMixin.streamAndCommit(
        db: _db,
        conversationId: conversationId,
        userText: text,
        systemPrompt: systemPrompt,
        existingMessages: messages,
        provider: provider,
        model: model,
        draftId: draftId,
        onMessagesChanged: (msgs) {
          messages = msgs;
          notifyListeners();
        },
        onUsage: (u) => _settings.recordUsage(u,
            providerId: provider.id, model: model, kind: UsageKind.explain),
        onError: (err) {
          lastError = err;
        },
      );
    } catch (e) {
      lastError = '$e';
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  /// The last assistant message, or null if none yet.
  Message? get latestAnswer {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == 'assistant' && messages[i].content.isNotEmpty) {
        return messages[i];
      }
    }
    return null;
  }
}

/// Days after which orphaned explain sessions are pruned on app launch.
const _staleSessionDays = 7;

/// On app launch, prune explain sessions older than [_staleSessionDays]
/// that have no saved items pointing at them.
Future<void> cleanupStaleExplainSessions(AppDatabase db) async {
  final cutoff = DateTime.now().subtract(const Duration(days: _staleSessionDays));
  // Conversations that are explain, older than cutoff, and not referenced
  // by any saved item (source_conv_id or explain_conv_id).
  await db.customStatement(
    '''
    DELETE FROM messages WHERE conversation_id IN (
      SELECT c.id FROM conversations c
      WHERE c.kind = 'explain'
        AND c.updated_at < ?
        AND NOT EXISTS (
          SELECT 1 FROM saved_items s
          WHERE s.explain_conv_id = c.id OR s.source_conv_id = c.id
        )
    )
    ''',
    [cutoff.millisecondsSinceEpoch ~/ 1000],
  );
  await db.customStatement(
    '''
    DELETE FROM conversations
    WHERE kind = 'explain'
      AND updated_at < ?
      AND NOT EXISTS (
        SELECT 1 FROM saved_items s
        WHERE s.explain_conv_id = conversations.id
           OR s.source_conv_id = conversations.id
      )
    ''',
    [cutoff.millisecondsSinceEpoch ~/ 1000],
  );
}
