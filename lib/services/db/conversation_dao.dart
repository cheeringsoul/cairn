import 'package:drift/drift.dart';

import '../constants.dart';
import 'database.dart';

/// Centralized data-access for conversations and messages.
class ConversationDao {
  final AppDatabase _db;

  ConversationDao(this._db);

  // ---- conversations ----

  Future<List<Conversation>> recentChats({int limit = 50}) =>
      (_db.select(_db.conversations)
            ..where((c) => c.kind.equals(ConversationKind.chat) & c.archived.equals(false))
            ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)])
            ..limit(limit))
          .get();

  /// Search conversations by title (DB-level LIKE, not in-memory).
  Future<List<Conversation>> searchChats(String query, {int limit = 20}) =>
      (_db.select(_db.conversations)
            ..where((c) =>
                c.kind.equals(ConversationKind.chat) &
                c.archived.equals(false) &
                c.title.like('%$query%'))
            ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)])
            ..limit(limit))
          .get();

  /// Search message content across all chat conversations. Returns
  /// the conversation, the matched message id, and a text snippet.
  Future<List<ChatSearchResult>> searchMessageContent(
    String query, {
    int limit = 20,
  }) async {
    final rows = await _db.customSelect(
      'SELECT m.id AS msg_id, m.content, m.conversation_id, '
      '  c.title, c.updated_at '
      'FROM messages m '
      'JOIN conversations c ON c.id = m.conversation_id '
      "WHERE c.kind = 'chat' AND c.archived = 0 "
      '  AND m.content LIKE ? '
      'ORDER BY m.created_at DESC '
      'LIMIT ?',
      variables: [
        Variable.withString('%$query%'),
        Variable.withInt(limit),
      ],
    ).get();

    final seen = <String>{};
    final results = <ChatSearchResult>[];
    for (final row in rows) {
      final convId = row.read<String>('conversation_id');
      if (seen.contains(convId)) continue;
      seen.add(convId);

      final content = row.read<String>('content');
      final snippet = _extractSnippet(content, query);
      results.add(ChatSearchResult(
        conversationId: convId,
        conversationTitle: row.read<String>('title'),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('updated_at') * 1000),
        matchedMessageId: row.read<String>('msg_id'),
        snippet: snippet,
      ));
    }
    return results;
  }

  static String _extractSnippet(String content, String query, {int radius = 40}) {
    final lower = content.toLowerCase();
    final idx = lower.indexOf(query.toLowerCase());
    if (idx < 0) return content.substring(0, content.length.clamp(0, 80));
    final start = (idx - radius).clamp(0, content.length);
    final end = (idx + query.length + radius).clamp(0, content.length);
    var snippet = content.substring(start, end).replaceAll(RegExp(r'\s+'), ' ');
    if (start > 0) snippet = '...$snippet';
    if (end < content.length) snippet = '$snippet...';
    return snippet;
  }

  Future<Conversation?> getById(String id) =>
      (_db.select(_db.conversations)..where((c) => c.id.equals(id)))
          .getSingleOrNull();

  Future<void> insert(ConversationsCompanion companion) =>
      _db.into(_db.conversations).insert(companion);

  Future<void> touchUpdatedAt(String id) =>
      (_db.update(_db.conversations)..where((c) => c.id.equals(id)))
          .write(ConversationsCompanion(updatedAt: Value(DateTime.now())));

  Future<void> archive(String id) =>
      (_db.update(_db.conversations)..where((c) => c.id.equals(id)))
          .write(const ConversationsCompanion(archived: Value(true)));

  Future<void> deleteWithMessages(String id) async {
    await (_db.delete(_db.messages)
          ..where((m) => m.conversationId.equals(id)))
        .go();
    await (_db.delete(_db.conversations)..where((c) => c.id.equals(id))).go();
  }

  // ---- messages ----

  /// Default page size returned by the paginated helpers. Long-chat
  /// performance work (see docs/plans/implementation-plan.md §6.1)
  /// targets 60fps on conversations up to 500 messages; loading 50
  /// at a time keeps the initial render cost bounded.
  static const messagePageSize = 50;

  /// Load every message in the conversation, chronologically. Used
  /// only in places that need the complete history at once (e.g.
  /// the regenerate-last flow may walk backwards from the end).
  /// For rendering and sendMessage, prefer [latestMessages].
  Future<List<Message>> messagesFor(String conversationId) =>
      (_db.select(_db.messages)
            ..where((m) => m.conversationId.equals(conversationId))
            ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
          .get();

  /// Load the most-recent [limit] messages for [conversationId], in
  /// chronological (oldest → newest) order. This is the default
  /// "open conversation" call — the UI shows the tail of the
  /// conversation and lazily loads older pages when the user
  /// scrolls up.
  Future<List<Message>> latestMessages(
    String conversationId, {
    int limit = messagePageSize,
  }) async {
    final rows = await (_db.select(_db.messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
          ..limit(limit))
        .get();
    // DESC query for "latest", but the UI wants ascending chronological
    // order so new-at-bottom behavior matches the rest of the chat
    // flow. Reverse in-memory — cheaper than re-querying.
    return rows.reversed.toList();
  }

  /// Load [limit] messages strictly older than [olderThan], in
  /// chronological order. Used by [ChatProvider.loadMoreMessages]
  /// when the user scrolls past the top of the currently-loaded
  /// page. Safe to call repeatedly: returns an empty list when
  /// there are no more older messages.
  ///
  /// Cursor-based pagination (by createdAt, not offset) is chosen
  /// so incoming new messages during the session don't shift the
  /// window underneath us.
  Future<List<Message>> messagesOlderThan(
    String conversationId,
    DateTime olderThan, {
    int limit = messagePageSize,
  }) async {
    final rows = await (_db.select(_db.messages)
          ..where((m) =>
              m.conversationId.equals(conversationId) &
              m.createdAt.isSmallerThanValue(olderThan))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
          ..limit(limit))
        .get();
    return rows.reversed.toList();
  }

  Future<void> insertMessage(Message msg) =>
      _db.into(_db.messages).insert(msg);

  Future<void> deleteMessage(String id) =>
      (_db.delete(_db.messages)..where((m) => m.id.equals(id))).go();

  Future<void> deleteMessages(List<String> ids) =>
      (_db.delete(_db.messages)..where((m) => m.id.isIn(ids))).go();
}

class ChatSearchResult {
  final String conversationId;
  final String conversationTitle;
  final DateTime updatedAt;
  final String matchedMessageId;
  final String snippet;

  const ChatSearchResult({
    required this.conversationId,
    required this.conversationTitle,
    required this.updatedAt,
    required this.matchedMessageId,
    required this.snippet,
  });
}
