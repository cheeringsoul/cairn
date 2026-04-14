import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'constants.dart';

import 'cairn_meta.dart';
import 'db/database.dart';
import 'db/saved_item_dao.dart';
import 'embedding/codec.dart';
import 'embedding/health_monitor.dart';
import 'embedding/service.dart';
import 'llm/llm_provider.dart';
import 'llm/provider_factory.dart';
import 'settings_provider.dart';

/// Owns the saved-items + folders state for the Library tab.
///
/// All CRUD goes through here so the UI can stay reactive.
/// Search uses FTS5 for full-text matching; tag filtering uses the
/// normalized item_tags table. Semantic recall (cross-conversation
/// memory injected into the chat system prompt) goes through
/// [recallRelated] → [recallByVector] which is powered by the
/// embedding infrastructure in `embedding_service.dart` /
/// `embedding_health_monitor.dart`.
class LibraryProvider extends ChangeNotifier {
  final AppDatabase _db;
  final SavedItemDao _dao;
  final SettingsProvider _settings;
  final EmbeddingService? _embeddingService;
  final EmbeddingHealthMonitor? _healthMonitor;
  final _uuid = const Uuid();

  LibraryProvider(
    this._db,
    this._settings, {
    EmbeddingService? embeddingService,
    EmbeddingHealthMonitor? healthMonitor,
  })  : _embeddingService = embeddingService,
        _healthMonitor = healthMonitor,
        _dao = SavedItemDao(_db);

  // ---- state ----

  List<Folder> folders = const [];
  List<SavedItem> items = const [];
  String? currentFolderId; // null = All
  String? currentType; // null = no type filter
  String? currentTag; // null = no tag filter
  String _search = '';

  String get search => _search;

  /// All distinct item types across saved items (e.g. vocab, insight).
  List<String> allTypes = const [];

  /// All distinct tags that appear across every saved item. Used by the
  /// Library tag filter.
  List<String> allTags = const [];

  /// Whether the tag/type indexes need refreshing. Set to true on
  /// data mutations (save, delete, meta update); cleared after rebuild.
  bool _indexesDirty = true;

  // ---- loading ----

  Future<void> load() async {
    folders = await (_db.select(_db.folders)
          ..orderBy([
            (f) => OrderingTerm.asc(f.sortOrder),
            (f) => OrderingTerm.asc(f.createdAt),
          ]))
        .get();
    await _reloadItems();
    // Retry items that never got tagged (pending or failed).
    _retryUntaggedItems();
  }

  /// Find items with metaStatus pending or failed and re-analyze them.
  void _retryUntaggedItems() async {
    final rows = await _dao.pendingAnalysis();
    if (rows.isNotEmpty) {
      analyzeItems(rows);
    }
  }

  Future<void> selectFolder(String? folderId) async {
    currentFolderId = folderId;
    await _reloadItems();
  }

  Future<void> selectType(String? type) async {
    currentType = type;
    await _reloadItems();
  }

  Future<void> selectTag(String? tag) async {
    currentTag = tag;
    await _reloadItems();
  }

  Future<void> setSearch(String query) async {
    _search = query;
    await _reloadItems();
  }

  Future<void> _reloadItems() async {
    // When a text search is active, use FTS5 for fast full-text matching.
    Set<String>? ftsIds;
    if (_search.trim().isNotEmpty) {
      final ids = await _db.ftsSearch(_search.trim());
      ftsIds = ids.toSet();
      if (ftsIds.isEmpty) {
        items = const [];
        await _maybeRebuildIndexes();
        notifyListeners();
        return;
      }
    }

    // When a tag filter is active, query the normalized item_tags table.
    Set<String>? tagIds;
    if (currentTag != null && currentTag!.isNotEmpty) {
      tagIds = await _dao.itemIdsForTag(currentTag!);
      if (tagIds.isEmpty) {
        items = const [];
        await _maybeRebuildIndexes();
        notifyListeners();
        return;
      }
    }

    // Intersect FTS and tag ID sets if both are active.
    Set<String>? filterIds;
    if (ftsIds != null && tagIds != null) {
      filterIds = ftsIds.intersection(tagIds);
    } else {
      filterIds = ftsIds ?? tagIds;
    }

    final q = _db.select(_db.savedItems);
    // Library UI only shows user-curated items. Auto-captured chat
    // knowledge (in_library=false) lives in saved_items for the sake
    // of the embedding recall pool but must stay invisible here.
    q.where((i) => i.inLibrary.equals(true));
    if (filterIds != null) {
      q.where((i) => i.id.isIn(filterIds!));
    }
    if (currentFolderId != null) {
      q.where((i) => i.folderId.equals(currentFolderId!));
    }
    if (currentType != null && currentType!.isNotEmpty) {
      q.where((i) => i.itemType.equals(currentType!));
    }
    q.orderBy([(i) => OrderingTerm.desc(i.updatedAt)]);
    items = await q.get();
    await _maybeRebuildIndexes();
    notifyListeners();
  }

  /// Only rebuild tag/type indexes when data has actually changed.
  Future<void> _maybeRebuildIndexes() async {
    if (!_indexesDirty) return;
    allTags = await _dao.distinctTags();
    allTypes = await _dao.distinctTypes();
    _indexesDirty = false;
  }

  /// Mark indexes as needing refresh (called after mutations).
  void _invalidateIndexes() {
    _indexesDirty = true;
  }

  // ---- folders ----

  Future<Folder> createFolder(String name, {String icon = '📁'}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final max = folders.isEmpty
        ? 0
        : folders.map((f) => f.sortOrder).reduce((a, b) => a > b ? a : b);
    await _db.into(_db.folders).insert(FoldersCompanion.insert(
          id: id,
          name: name,
          icon: Value(icon),
          isSystem: const Value(false),
          sortOrder: Value(max + 1),
          createdAt: now,
        ));
    await load();
    return folders.firstWhere((f) => f.id == id);
  }

  Future<void> deleteFolder(String folderId) async {
    // Orphan items to "no folder" rather than deleting them.
    await (_db.update(_db.savedItems)
          ..where((i) => i.folderId.equals(folderId)))
        .write(const SavedItemsCompanion(folderId: Value(null)));
    await (_db.delete(_db.folders)..where((f) => f.id.equals(folderId))).go();
    if (currentFolderId == folderId) currentFolderId = null;
    await load();
  }

  // ---- items ----

  /// Save a new item. The caller picks the folder — REQUIREMENTS says
  /// the folder defaults are driven by the entry point, not prompts.
  ///
  /// [inLibrary] controls whether the item appears in the user-facing
  /// Library page. Manual saves (bookmark button, import, share intent)
  /// pass `true` (the default). Auto-captured chat knowledge passes
  /// `false` — those rows feed the embedding recall pool but stay out
  /// of the Library UI.
  Future<SavedItem> saveItem({
    required String title,
    required String body,
    String? folderId,
    String? sourceConvId,
    String? sourceMsgId,
    String? sourceHighlight,
    String? explainConvId,
    String userNotes = '',
    CairnMeta? meta,
    String? metaStatus,
    bool inLibrary = true,
    bool titleLocked = false,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.into(_db.savedItems).insert(SavedItemsCompanion.insert(
          id: id,
          title: title,
          body: body,
          userNotes: Value(userNotes),
          folderId: Value(folderId),
          sourceConvId: Value(sourceConvId),
          sourceMsgId: Value(sourceMsgId),
          sourceHighlight: Value(sourceHighlight),
          explainConvId: Value(explainConvId),
          itemType: Value(meta?.type),
          entity: Value(meta?.entity),
          tags: Value(
              meta == null || meta.tags.isEmpty ? null : meta.encodeTags()),
          summary: Value(meta?.summary),
          metaStatus: Value(metaStatus),
          nextReviewAt: Value(
              meta != null && _shouldAutoEnroll(meta)
                  ? now.add(const Duration(days: 1))
                  : null),
          inLibrary: Value(inLibrary),
          titleLocked: Value(titleLocked),
          createdAt: now,
          updatedAt: now,
        ));
    // Sync normalized tag index.
    if (meta != null && meta.tags.isNotEmpty) {
      await _db.syncItemTags(id, meta.tags);
    }
    _invalidateIndexes();
    // Only reload the library list when a user-facing item was added —
    // auto-captured rows are invisible to the Library UI so no need to
    // spin up a notifyListeners cycle.
    if (inLibrary) {
      await _reloadItems();
    }
    final savedItem = await _dao.getById(id);

    // Share Intent and Markdown Import create items with
    // metaStatus='pending' and no pre-filled cairn-meta. Kick off
    // background AI analysis immediately so the item becomes
    // tagged / recall-ready without waiting for the next app
    // restart (when _retryUntaggedItems would sweep pending rows).
    // Chat auto-save already passes a `meta` object, so those
    // paths naturally skip this trigger.
    if (metaStatus == MetaStatus.pending && meta == null) {
      unawaited(analyzeItem(savedItem));
    }

    return savedItem;
  }

  Future<void> updateItem(
    String id, {
    String? title,
    String? body,
    String? userNotes,
    String? folderId,
  }) async {
    await (_db.update(_db.savedItems)..where((i) => i.id.equals(id))).write(
      SavedItemsCompanion(
        title: title == null ? const Value.absent() : Value(title),
        // User explicitly changed the title → lock it so AI analysis
        // won't overwrite their choice.
        titleLocked: title == null ? const Value.absent() : const Value(true),
        body: body == null ? const Value.absent() : Value(body),
        userNotes:
            userNotes == null ? const Value.absent() : Value(userNotes),
        folderId: folderId == null ? const Value.absent() : Value(folderId),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await _reloadItems();
  }

  Future<void> deleteItem(String id) async {
    await _dao.deleteById(id);
    _invalidateIndexes();
    await _reloadItems();
  }

  Future<void> deleteItems(List<String> ids) async {
    if (ids.isEmpty) return;
    await _dao.deleteByIds(ids);
    _invalidateIndexes();
    await _reloadItems();
  }

  /// Check whether a saved item already exists for a given chat message.
  /// Returns the row regardless of its `in_library` state — callers
  /// must inspect [SavedItem.inLibrary] to decide how to react.
  Future<SavedItem?> findBySourceMsgId(String msgId) =>
      _dao.findBySourceMsgId(msgId);

  /// Batch lookup: returns the set of message ids that have a
  /// corresponding saved_item with in_library = true. Single SQL
  /// query instead of N sequential round-trips.
  Future<Set<String>> inLibraryMsgIds(List<String> msgIds) =>
      _dao.inLibraryMsgIds(msgIds);

  /// Delete auto-captured knowledge pool items that originated from
  /// [convId]. Preserves any items the user promoted to the Library.
  Future<void> deletePoolItemsByConvId(String convId) async {
    await _dao.deletePoolItemsByConvId(convId);
    _invalidateIndexes();
  }

  /// Promote an existing row to the user-facing library. Used when the
  /// user taps the save bookmark on a message that was already
  /// auto-captured (row exists with `in_library = false`). No-op when
  /// the row is already in the library.
  Future<void> addToLibrary(String itemId) async {
    await _dao.updateFields(
      itemId,
      SavedItemsCompanion(
        inLibrary: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
    _invalidateIndexes();
    await _reloadItems();
  }

  /// Remove an item from the user-facing library without deleting it
  /// from the knowledge pool. The row (and its embeddings) survive, so
  /// embedding-based recall continues to see the content — we just
  /// hide it from the Library UI and the review queue.
  Future<void> removeFromLibrary(String itemId) async {
    await _dao.updateFields(
      itemId,
      SavedItemsCompanion(
        inLibrary: const Value(false),
        nextReviewAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
    _invalidateIndexes();
    await _reloadItems();
  }

  // ---- background analysis ----

  /// Item IDs currently being analyzed by the LLM.
  final Set<String> analyzingItemIds = {};

  bool isAnalyzing(String itemId) => analyzingItemIds.contains(itemId);

  /// Send item content to the LLM to generate cairn-meta, then update
  /// the item in the DB. Runs in the background — does not block the UI.
  Future<void> analyzeItem(SavedItem item) async {
    if (_settings.providers.isEmpty) return;
    analyzingItemIds.add(item.id);
    notifyListeners();

    try {
      final provider = _settings.providers.firstWhere(
        (p) => p.id == _settings.defaultProviderId,
        orElse: () => _settings.providers.first,
      );
      final model = _settings.defaultModel.isNotEmpty
          ? _settings.defaultModel
          : provider.defaultModel;
      final adapter = await buildProvider(provider);

      final prompt =
          'Analyze the following note and produce ONLY a JSON object '
          '(no markdown fences, no explanation) with these fields:\n'
          '- "type": a short lowercase label that best categorizes this unit '
          '(e.g. vocab, insight, action, fact, question, concept, recipe, '
          'reference — use whatever fits best, one word)\n'
          '- "entity": the canonical subject (lowercase, singular)\n'
          '- "tags": 3-5 lowercase short tags for retrieval\n'
          '- "summary": one sentence, <= 20 words\n'
          '- "title": a concise 3-8 word title capturing the core topic. '
          'Use the same language as the note body. Avoid generic prefixes.\n'
          '- "cleaned_body": the note body with corrected and beautified '
          'markdown formatting — fix heading levels, remove excessive blank '
          'lines (keep at most one between paragraphs), normalize list '
          'markers, fix broken links/emphasis, ensure consistent style. '
          'Preserve ALL original content and meaning, only fix formatting.\n\n'
          'Title: ${item.title}\n\n${item.body}';

      final buf = StringBuffer();
      await for (final chunk in adapter.streamChat(
        messages: [LlmMessage(role: 'user', content: prompt)],
        model: model,
        systemPrompt: 'You are a metadata extraction assistant. '
            'Output ONLY valid JSON, nothing else.',
        onUsage: (u) => _settings.recordUsage(u,
            providerId: provider.id, model: model, kind: UsageKind.analyze),
      )) {
        buf.write(chunk);
      }

      final raw = buf.toString().trim();
      final parsed = _parseAnalysisResult(raw);
      final meta = parsed.$1;
      final cleanedBody = parsed.$2;
      if (meta != null && !meta.isEmpty) {
        await _updateItemMeta(item.id, meta);
        if (cleanedBody != null && cleanedBody.trim().isNotEmpty) {
          await updateItem(item.id, body: cleanedBody.trim());
        }
      } else {
        await _setMetaStatus(item.id, MetaStatus.failed);
      }
    } catch (e) {
      debugPrint('analyzeItem failed for ${item.id}: $e');
      await _setMetaStatus(item.id, MetaStatus.failed);
    } finally {
      analyzingItemIds.remove(item.id);
      notifyListeners();
    }
  }

  /// Kick off background analysis for multiple items.
  void analyzeItems(List<SavedItem> items) {
    for (final item in items) {
      analyzeItem(item); // fire-and-forget
    }
  }

  (CairnMeta?, String?) _parseAnalysisResult(String raw) {
    try {
      // Strip markdown fences if the LLM wrapped the JSON anyway.
      var json = raw;
      json = json.replaceAll(RegExp(r'^```\w*\n?'), '');
      json = json.replaceAll(RegExp(r'\n?```\s*$'), '');
      json = json.trim();

      final decoded = jsonDecode(json);
      if (decoded is! Map) return (null, null);
      final type = (decoded['type'] as Object?)?.toString();
      final entity = (decoded['entity'] as Object?)?.toString();
      final summary = (decoded['summary'] as Object?)?.toString();
      final title = (decoded['title'] as Object?)?.toString();
      final cleanedBody = (decoded['cleaned_body'] as Object?)?.toString();
      final rawTags = decoded['tags'];
      final tags = rawTags is List
          ? rawTags
              .map((e) => e.toString().trim().toLowerCase())
              .where((t) => t.isNotEmpty)
              .toList()
          : const <String>[];
      return (
        CairnMeta(
          type: type == null || type.isEmpty ? null : type,
          entity: entity == null || entity.isEmpty ? null : entity,
          tags: tags,
          summary: summary == null || summary.isEmpty ? null : summary,
          title: title == null || title.isEmpty ? null : title,
        ),
        cleanedBody,
      );
    } catch (_) {
      return (null, null);
    }
  }

  Future<void> _updateItemMeta(String id, CairnMeta meta) async {
    final now = DateTime.now();
    final current = await _dao.getById(id);

    // AI title overwrites only when: AI produced a title AND user
    // hasn't locked the title.
    final shouldUpdateTitle = meta.title != null &&
        meta.title!.isNotEmpty &&
        !current.titleLocked;

    await _dao.updateFields(
      id,
      SavedItemsCompanion(
        itemType: Value(meta.type),
        entity: Value(meta.entity),
        tags: Value(meta.tags.isEmpty ? null : meta.encodeTags()),
        summary: Value(meta.summary),
        title: shouldUpdateTitle ? Value(meta.title!) : const Value.absent(),
        metaStatus: const Value(MetaStatus.done),
        nextReviewAt: Value(
            _shouldAutoEnroll(meta)
                ? now.add(const Duration(days: 1))
                : null),
        updatedAt: Value(now),
      ),
    );
    // Sync normalized tag index.
    await _db.syncItemTags(id, meta.tags);
    _invalidateIndexes();
    await _reloadItems();
  }

  Future<void> _setMetaStatus(String id, String status) async {
    await _dao.setMetaStatus(id, status);
  }

  // ---- lookup helpers ----

  /// Decide whether a saved item should auto-enroll in spaced repetition.
  /// AI's `reviewable` field is the primary signal; type policy is fallback.
  static bool _shouldAutoEnroll(CairnMeta meta) {
    return meta.reviewable != false;
  }

  Folder? folderById(String? id) {
    if (id == null) return null;
    for (final f in folders) {
      if (f.id == id) return f;
    }
    return null;
  }

  // ---- memory recall ----

  /// Entry point used by ChatProvider / ExplainController to fetch
  /// cross-conversation memory. Computes an embedding for
  /// [userMessage] via the fastest healthy embedding provider, then
  /// queries [recallByVector] for the semantically closest
  /// saved_items. Returns an empty list on any failure (no provider
  /// configured, all providers down, no vectors yet, etc.) — the
  /// chat flow interprets an empty list as "don't inject recall
  /// context" and continues normally.
  ///
  /// Failure handling walks the provider list in latency order:
  /// the first success wins; each failure quarantines that provider
  /// via [EmbeddingHealthMonitor.recordFailure] so it's skipped for
  /// subsequent attempts until the next probe tick.
  Future<List<SavedItem>> recallRelated(String userMessage,
      {int limit = 5}) async {
    final service = _embeddingService;
    final monitor = _healthMonitor;
    if (service == null || monitor == null) {
      // Embedding infrastructure not wired in (e.g. test harness
      // constructing LibraryProvider without the optional deps).
      return const [];
    }

    final orderedProviderIds = monitor.selectHealthyOrderedByLatency();
    if (orderedProviderIds.isEmpty) return const [];

    // Short-circuit: if there are no vectors in the DB at all, skip
    // the embedding API call entirely.
    final hasVectors = await (_db.select(_db.itemEmbeddings)..limit(1)).get();
    if (hasVectors.isEmpty) return const [];

    final providersById = {
      for (final p in _settings.providers) p.id: p,
    };

    for (final providerId in orderedProviderIds) {
      final provider = providersById[providerId];
      if (provider == null || provider.embeddingModel == null) continue;
      try {
        final (queryVec, elapsed) =
            await service.embed(provider, userMessage);
        monitor.recordSuccess(providerId, elapsed);
        return await recallByVector(
          queryVector: queryVec,
          model: provider.embeddingModel!,
          limit: limit,
        );
      } catch (e) {
        debugPrint('[LibraryProvider] recall embed failed for '
            '$providerId: $e — trying next');
        monitor.recordFailure(providerId);
        continue;
      }
    }

    // All healthy providers failed. Return empty → chat proceeds
    // without recall context (see walk-B design in
    // docs/plans/implementation-plan.md §6.1).
    return const [];
  }

  /// Semantic similarity search against `item_embeddings`. Loads
  /// every row for the given [model], computes similarity in Dart
  /// memory using dot product on pre-normalized vectors (the expected
  /// knowledge-base size — low thousands of items — makes a SQLite
  /// vector extension overkill), sorts descending, and returns the
  /// Top [limit] as fully-hydrated [SavedItem]s.
  ///
  /// The query vector is normalized internally so callers don't need
  /// to remember to do it.
  ///
  /// The result preserves similarity order (NOT updated_at order).
  /// No `in_library` filter — both user-curated items and
  /// silently-captured chat knowledge participate in recall.
  Future<List<SavedItem>> recallByVector({
    required List<double> queryVector,
    required String model,
    int limit = EmbeddingLimits.recallTopK,
  }) async {
    final rows = await (_db.select(_db.itemEmbeddings)
          ..where((e) => e.model.equals(model)))
        .get();
    if (rows.isEmpty) return const [];

    // Normalize the query to match stored unit vectors.
    final normalizedQuery = List<double>.from(queryVector);
    EmbeddingCodec.normalize(normalizedQuery);

    // Score every candidate. Stored vectors are already unit-length
    // (normalized at write time by EmbeddingCodec.encode), so the
    // dot product equals cosine similarity.
    final scored = <({String itemId, double score})>[];
    for (final row in rows) {
      final itemVec =
          EmbeddingCodec.decode(Uint8List.fromList(row.vector));
      final sim = EmbeddingCodec.dot(normalizedQuery, itemVec);
      scored.add((itemId: row.itemId, score: sim));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final topIds = scored.take(limit).map((s) => s.itemId).toList();
    if (topIds.isEmpty) return const [];

    // Hydrate the items by id. The order of the SQL result is
    // unspecified, so we reorder based on topIds to preserve
    // similarity ranking.
    final items = await (_db.select(_db.savedItems)
          ..where((i) => i.id.isIn(topIds)))
        .get();
    final itemsById = {for (final i in items) i.id: i};
    return topIds
        .map((id) => itemsById[id])
        .whereType<SavedItem>()
        .toList();
  }

  /// Find saved items semantically related to [itemId] by comparing
  /// embedding vectors. Returns up to [limit] items sorted by
  /// similarity (highest first), excluding the item itself.
  ///
  /// Uses the first available embedding for the item. Returns empty
  /// if the item has no embedding yet or no other items have vectors.
  Future<List<({SavedItem item, double score})>> findRelatedItems(
    String itemId, {
    int limit = 5,
  }) async {
    // Load the item's own embedding(s).
    final itemEmbeddings = await (_db.select(_db.itemEmbeddings)
          ..where((e) => e.itemId.equals(itemId))
          ..limit(1))
        .get();
    if (itemEmbeddings.isEmpty) return const [];

    final model = itemEmbeddings.first.model;
    final queryVec = EmbeddingCodec.decode(
        Uint8List.fromList(itemEmbeddings.first.vector));

    // Load all vectors for the same model.
    final allRows = await (_db.select(_db.itemEmbeddings)
          ..where((e) => e.model.equals(model)))
        .get();

    // Score every candidate except self.
    final scored = <({String itemId, double score})>[];
    for (final row in allRows) {
      if (row.itemId == itemId) continue;
      final vec = EmbeddingCodec.decode(Uint8List.fromList(row.vector));
      final sim = EmbeddingCodec.dot(queryVec, vec);
      scored.add((itemId: row.itemId, score: sim));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final topEntries = scored.take(limit).toList();
    if (topEntries.isEmpty) return const [];

    // Hydrate items.
    final ids = topEntries.map((e) => e.itemId).toList();
    final items = await (_db.select(_db.savedItems)
          ..where((i) => i.id.isIn(ids)))
        .get();
    final itemsById = {for (final i in items) i.id: i};

    return topEntries
        .where((e) => itemsById.containsKey(e.itemId))
        .map((e) => (item: itemsById[e.itemId]!, score: e.score))
        .toList();
  }

  // ---- entity connections / clustering ----

  /// Build clusters of saved items that share tags or entities.
  /// Uses the normalized item_tags table for efficient lookups.
  Future<List<EntityCluster>> buildClusters() async {
    final allItems = await _dao.withEntityOrTags();
    if (allItems.isEmpty) return const [];

    // Load all tag associations in one query.
    final allTagRows = await _dao.allItemTags();
    final itemTagsMap = <String, Set<String>>{};
    for (final row in allTagRows) {
      (itemTagsMap[row.itemId] ??= {}).add(row.tag);
    }

    // Build inverted index: tag → set of item IDs.
    final tagToItems = <String, Set<String>>{};
    final itemMap = <String, SavedItem>{};
    for (final item in allItems) {
      itemMap[item.id] = item;
      final tags = itemTagsMap[item.id] ?? {};
      final entity = item.entity?.toLowerCase();
      final keys = <String>{...tags};
      if (entity != null && entity.isNotEmpty) keys.add(entity);
      for (final tag in keys) {
        (tagToItems[tag] ??= {}).add(item.id);
      }
    }

    // Union-find to merge items sharing common tags.
    final parent = <String, String>{};
    String find(String x) {
      while (parent[x] != x) {
        parent[x] = parent[parent[x]!]!;
        x = parent[x]!;
      }
      return x;
    }
    void union(String a, String b) {
      final ra = find(a), rb = find(b);
      if (ra != rb) parent[ra] = rb;
    }

    for (final item in allItems) {
      parent[item.id] = item.id;
    }

    for (final entry in tagToItems.entries) {
      if (entry.value.length < 2) continue;
      final ids = entry.value.toList();
      for (int i = 1; i < ids.length; i++) {
        union(ids[0], ids[i]);
      }
    }

    // Group items by root.
    final groups = <String, List<SavedItem>>{};
    for (final item in allItems) {
      final root = find(item.id);
      (groups[root] ??= []).add(item);
    }

    // Build clusters from groups with >= 2 items.
    final clusters = <EntityCluster>[];
    for (final group in groups.values) {
      if (group.length < 2) continue;

      final tagCounts = <String, int>{};
      for (final item in group) {
        final tags = itemTagsMap[item.id] ?? {};
        for (final t in tags) {
          tagCounts[t] = (tagCounts[t] ?? 0) + 1;
        }
        final entity = item.entity?.toLowerCase();
        if (entity != null && entity.isNotEmpty) {
          tagCounts[entity] = (tagCounts[entity] ?? 0) + 1;
        }
      }
      final shared = tagCounts.entries
          .where((e) => e.value >= 2)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final label = shared.isNotEmpty ? shared.first.key : group.first.entity ?? 'Related';
      final sharedTags = shared.map((e) => e.key).toList();

      clusters.add(EntityCluster(
        label: label,
        sharedTags: sharedTags,
        items: group,
      ));
    }

    clusters.sort((a, b) => b.items.length.compareTo(a.items.length));
    return clusters;
  }

  /// Generate a knowledge report for a given time range.
  Future<KnowledgeReport> generateReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final allItems = await _dao.inDateRange(from, to);

    final typeCounts = <String, int>{};
    final entities = <String>[];
    final itemIds = <String>[];

    for (final item in allItems) {
      final type = item.itemType ?? 'untyped';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      if (item.entity != null && item.entity!.isNotEmpty) {
        entities.add(item.entity!);
      }
      itemIds.add(item.id);
    }

    // Count tags via the normalized table.
    final tagCounts = <String, int>{};
    if (itemIds.isNotEmpty) {
      final tagRows = await _dao.tagsForItems(itemIds);
      for (final row in tagRows) {
        tagCounts[row.tag] = (tagCounts[row.tag] ?? 0) + 1;
      }
    }

    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return KnowledgeReport(
      from: from,
      to: to,
      totalItems: allItems.length,
      typeCounts: typeCounts,
      entities: entities,
      topTags: topTags.take(15).map((e) => (e.key, e.value)).toList(),
    );
  }

  /// Format recalled items into a system prompt fragment.
  static String formatRecallContext(List<SavedItem> items) {
    if (items.isEmpty) return '';
    final buf = StringBuffer();
    buf.writeln(
        'The user has previously saved the following related knowledge. '
        'Reference it naturally when relevant — do not repeat it verbatim, '
        'but connect new information to what they already know.');
    buf.writeln();
    for (final item in items) {
      final entity = item.entity ?? item.title;
      final type = item.itemType ?? 'note';
      final summary = item.summary ?? '';
      final tags = CairnMeta.decodeTags(item.tags);
      buf.writeln('- [$type] **$entity**: $summary'
          '${tags.isNotEmpty ? ' (tags: ${tags.join(", ")})' : ''}');
    }
    return buf.toString();
  }
}

/// Aggregated knowledge statistics for a time range.
class KnowledgeReport {
  final DateTime from;
  final DateTime to;
  final int totalItems;
  final Map<String, int> typeCounts;
  final List<String> entities;
  final List<(String, int)> topTags; // (tag, count)

  const KnowledgeReport({
    required this.from,
    required this.to,
    required this.totalItems,
    required this.typeCounts,
    required this.entities,
    required this.topTags,
  });
}

/// A cluster of related saved items grouped by shared tags/entities.
class EntityCluster {
  final String label;
  final List<String> sharedTags;
  final List<SavedItem> items;

  const EntityCluster({
    required this.label,
    required this.sharedTags,
    required this.items,
  });
}
