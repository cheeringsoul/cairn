import 'package:drift/drift.dart';

import '../constants.dart';
import 'database.dart';

/// Centralized data-access for the saved_items + item_tags tables.
///
/// Providers delegate query logic here instead of building Drift
/// queries inline, which keeps the provider layer focused on state
/// management and makes queries testable in isolation.
class SavedItemDao {
  final AppDatabase _db;

  SavedItemDao(this._db);

  // ---- queries ----

  Future<SavedItem> getById(String id) =>
      (_db.select(_db.savedItems)..where((i) => i.id.equals(id))).getSingle();

  Future<SavedItem?> getByIdOrNull(String id) =>
      (_db.select(_db.savedItems)..where((i) => i.id.equals(id)))
          .getSingleOrNull();

  /// Look up a saved item by its source message id. Used by chat auto-save
  /// to avoid writing a duplicate row when the same assistant message
  /// triggers [LibraryProvider.saveItem] twice (defensive — normally the
  /// provider guards with an in-memory set, but this is the authoritative
  /// source of truth).
  Future<SavedItem?> findBySourceMsgId(String msgId) =>
      (_db.select(_db.savedItems)
            ..where((i) => i.sourceMsgId.equals(msgId))
            ..limit(1))
          .getSingleOrNull();

  Future<List<SavedItem>> getByIds(List<String> ids) =>
      (_db.select(_db.savedItems)..where((i) => i.id.isIn(ids))).get();

  /// Items due for spaced-repetition review (nextReviewAt <= [now]).
  /// Only returns library items — auto-captured chat knowledge does
  /// not force reviews on the user.
  Future<List<SavedItem>> dueForReview(DateTime now) =>
      (_db.select(_db.savedItems)
            ..where((i) =>
                i.inLibrary.equals(true) &
                i.nextReviewAt.isNotNull() &
                i.nextReviewAt.isSmallerOrEqualValue(now))
            ..orderBy([(i) => OrderingTerm.asc(i.nextReviewAt)]))
          .get();

  /// Items with pending or failed meta analysis. Runs against both
  /// library items AND auto-captured knowledge — both pools need
  /// AI-generated entity/tags/summary to be useful for recall.
  Future<List<SavedItem>> pendingAnalysis() =>
      (_db.select(_db.savedItems)
            ..where((i) =>
                i.metaStatus.equals(MetaStatus.pending) |
                i.metaStatus.equals(MetaStatus.failed)))
          .get();

  /// Library items that have entity or tags set (used for Connections
  /// clustering). The embedding recall path queries saved_items more
  /// broadly (including auto-captured rows) — do not confuse the two.
  Future<List<SavedItem>> withEntityOrTags() =>
      (_db.select(_db.savedItems)
            ..where((i) =>
                i.inLibrary.equals(true) &
                (i.entity.isNotNull() | i.tags.isNotNull()))
            ..orderBy([(i) => OrderingTerm.desc(i.updatedAt)]))
          .get();

  /// Library items in a date range, ordered by creation date descending.
  /// Used by the knowledge report — which summarizes what the user
  /// collected, not what was silently auto-captured.
  Future<List<SavedItem>> inDateRange(DateTime from, DateTime to) =>
      (_db.select(_db.savedItems)
            ..where((i) =>
                i.inLibrary.equals(true) &
                i.createdAt.isBiggerOrEqualValue(from) &
                i.createdAt.isSmallerOrEqualValue(to))
            ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
          .get();

  // ---- writes ----

  Future<void> insertItem(SavedItemsCompanion item) =>
      _db.into(_db.savedItems).insert(item);

  Future<void> updateFields(String id, SavedItemsCompanion companion) =>
      (_db.update(_db.savedItems)..where((i) => i.id.equals(id)))
          .write(companion);

  Future<void> deleteById(String id) =>
      (_db.delete(_db.savedItems)..where((i) => i.id.equals(id))).go();

  Future<void> deleteByIds(List<String> ids) =>
      (_db.delete(_db.savedItems)..where((i) => i.id.isIn(ids))).go();

  /// Delete auto-captured (non-library) items that originated from a
  /// specific conversation. Called when the user deletes a conversation
  /// to free storage. Items the user manually promoted to the Library
  /// are preserved. Foreign-key cascades clean up item_embeddings and
  /// item_tags automatically.
  Future<void> deletePoolItemsByConvId(String convId) =>
      (_db.delete(_db.savedItems)
            ..where((i) =>
                i.sourceConvId.equals(convId) &
                i.inLibrary.equals(false)))
          .go();

  /// Update meta-analysis status only.
  Future<void> setMetaStatus(String id, String status) =>
      updateFields(id, SavedItemsCompanion(metaStatus: Value(status)));

  /// Update review scheduling fields.
  Future<void> updateReviewSchedule(
    String id, {
    required DateTime lastReviewedAt,
    required int reviewCount,
    required DateTime nextReviewAt,
  }) =>
      updateFields(
        id,
        SavedItemsCompanion(
          lastReviewedAt: Value(lastReviewedAt),
          reviewCount: Value(reviewCount),
          nextReviewAt: Value(nextReviewAt),
        ),
      );

  Future<void> clearReviewSchedule(String id) => updateFields(
        id,
        const SavedItemsCompanion(
          nextReviewAt: Value(null),
          lastReviewedAt: Value(null),
          reviewCount: Value(0),
        ),
      );

  // ---- indexes ----

  /// All distinct tags in the user's Library. Auto-captured chat
  /// knowledge tags are excluded — the Library tag picker must match
  /// what the Library page displays.
  Future<List<String>> distinctTags() async {
    final rows = await _db.customSelect(
      'SELECT DISTINCT t.tag FROM item_tags t '
      'JOIN saved_items s ON t.item_id = s.id '
      'WHERE s.in_library = 1 '
      'ORDER BY t.tag',
    ).get();
    return rows.map((r) => r.read<String>('tag')).toList();
  }

  /// All distinct item types present in the Library.
  Future<List<String>> distinctTypes() async {
    final rows = await _db.customSelect(
      'SELECT DISTINCT item_type FROM saved_items '
      "WHERE in_library = 1 AND item_type IS NOT NULL AND item_type != '' "
      'ORDER BY item_type',
    ).get();
    return rows.map((r) => r.read<String>('item_type')).toList();
  }

  /// Item IDs that have a specific tag.
  Future<Set<String>> itemIdsForTag(String tag) async {
    final rows = await (_db.select(_db.itemTags)
          ..where((t) => t.tag.equals(tag)))
        .get();
    return rows.map((r) => r.itemId).toSet();
  }

  /// All tag rows (for bulk loading in clustering).
  Future<List<ItemTag>> allItemTags() => _db.select(_db.itemTags).get();

  /// Tags for items in a given ID set.
  Future<List<ItemTag>> tagsForItems(List<String> itemIds) =>
      (_db.select(_db.itemTags)..where((t) => t.itemId.isIn(itemIds))).get();

  /// Returns the set of message ids that have a corresponding
  /// [SavedItem] with in_library = true. Used by ChatProvider during
  /// openConversation to populate autoSavedMsgIds in a single query
  /// instead of N sequential round-trips.
  Future<Set<String>> inLibraryMsgIds(List<String> msgIds) async {
    if (msgIds.isEmpty) return const {};
    final rows = await (_db.select(_db.savedItems)
          ..where((i) =>
              i.sourceMsgId.isIn(msgIds) & i.inLibrary.equals(true)))
        .get();
    return rows.map((r) => r.sourceMsgId!).toSet();
  }
}
