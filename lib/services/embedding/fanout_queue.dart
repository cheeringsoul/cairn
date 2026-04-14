import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../db/database.dart';
import 'codec.dart';
import 'health_monitor.dart';
import 'input_composer.dart';
import 'service.dart';

/// Async, event-driven worker that computes embeddings for
/// `saved_items` rows and fans them out across every
/// embedding-capable provider.
///
/// ## Two work modes
///
///   1. **Catch-up tick** — every 5 seconds the worker wakes up,
///      pulls up to 10 rows whose `embedding_status = 'pending'`,
///      and for each row asks every capable provider to produce
///      a vector. Each (item, model) pair that succeeds becomes
///      a row in `item_embeddings`. When a row is covered by
///      every currently-capable provider, its
///      `embedding_status` is flipped to `'ready'`.
///
///   2. **Backfill for a newly-added provider** — when the user
///      adds a provider mid-life, [backfillProvider] walks the
///      entire `saved_items` table and computes a vector for
///      that one provider. This is independent from the catch-up
///      tick (which processes multiple providers per row but
///      only pending rows); the backfill works through all rows
///      for a single provider regardless of status. Completion
///      sets `provider_configs.embedding_backfilled_at = now`
///      which is the signal the HealthMonitor uses to admit
///      the provider into the query pool.
///
/// Both modes record latency/failure events into the
/// HealthMonitor so the probe loop and the query selector stay
/// in sync with real traffic.
///
/// ## Why not real parallelism?
///
/// The fan-out uses `Future.wait` to issue per-provider embed
/// calls concurrently for a single item — typically 1-5 in
/// flight at once, which is what the provider API rate limits
/// comfortably absorb. A more aggressive design (e.g. pooled
/// workers across items) is possible but unnecessary at
/// expected knowledge-base sizes (low thousands of rows).
class EmbeddingFanoutQueue {
  final EmbeddingService _embeddingService;
  final EmbeddingHealthMonitor _healthMonitor;
  final AppDatabase _db;

  Timer? _tickTimer;
  bool _running = false;

  // Backfill state: provider id → total/completed counts. Used by
  // the Settings UI to render progress bars; updated in-place by
  // [backfillProvider].
  final Map<String, ({int total, int completed})> _backfillProgress = {};

  static const _tickInterval = FanoutLimits.tickInterval;
  static const _batchSize = FanoutLimits.batchSize;
  static const _backfillConcurrency = FanoutLimits.backfillConcurrency;

  EmbeddingFanoutQueue(
    this._embeddingService,
    this._healthMonitor,
    this._db,
  );

  // ---- lifecycle ----

  /// Start the periodic catch-up tick. Safe to call multiple times
  /// (idempotent).
  void start() {
    if (_tickTimer != null) return;
    _tickTimer = Timer.periodic(
      _tickInterval,
      (_) => _tick(),
    );
    // Kick off immediately so the worker doesn't idle for 5s on
    // startup when there's likely pending work from the previous
    // session.
    _tick();
  }

  void stop() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  // ---- catch-up tick ----

  /// Drain up to [_batchSize] pending rows, fan-out to every capable
  /// provider. Guards against re-entry so overlapping timer fires
  /// don't double-process the same row.
  Future<void> _tick() async {
    if (_running) return;
    _running = true;
    try {
      final pendingItems = await (_db.select(_db.savedItems)
            ..where((s) => s.embeddingStatus.equals(EmbeddingStatus.pending))
            ..limit(_batchSize))
          .get();

      if (pendingItems.isEmpty) return;

      final providers = await _db.select(_db.providerConfigs).get();
      final capable = providers
          .where((p) =>
              p.embeddingCapability == EmbeddingCapability.yes && p.embeddingModel != null)
          .toList();

      if (capable.isEmpty) {
        // No usable providers. Rows stay 'pending' and will be
        // revisited next tick.
        return;
      }

      for (final item in pendingItems) {
        await _processItem(item, capable);
      }
    } catch (e) {
      debugPrint('[FanoutQueue] tick error: $e');
    } finally {
      _running = false;
    }
  }

  /// Process a single saved_item: for each capable provider that
  /// doesn't yet have a vector for this item, compute and store
  /// one. When every capable provider is covered, mark the item
  /// ready.
  Future<void> _processItem(
    SavedItem item,
    List<ProviderConfig> capable,
  ) async {
    final existing = await (_db.select(_db.itemEmbeddings)
          ..where((e) => e.itemId.equals(item.id)))
        .get();
    final coveredModels = existing.map((e) => e.model).toSet();

    final missing = capable
        .where((p) => !coveredModels.contains(p.embeddingModel))
        .toList();

    if (missing.isEmpty) {
      // Already fully covered — flip to ready and move on. This
      // can happen after the user deletes a provider (its rows
      // survive, so coverage may already be complete).
      await (_db.update(_db.savedItems)
            ..where((s) => s.id.equals(item.id)))
          .write(const SavedItemsCompanion(
              embeddingStatus: Value(EmbeddingStatus.ready)));
      return;
    }

    final text = EmbeddingInputComposer.compose(item);
    final results = await Future.wait(
      missing.map((p) => _computeAndStore(item.id, p, text)),
      eagerError: false,
    );
    final allSucceeded = results.every((ok) => ok);

    if (allSucceeded) {
      // Re-check coverage: we might have raced with a delete, but
      // the common case is clean.
      final afterExisting = await (_db.select(_db.itemEmbeddings)
            ..where((e) => e.itemId.equals(item.id)))
          .get();
      final afterCovered = afterExisting.map((e) => e.model).toSet();
      final stillCapable = capable.every(
          (p) => afterCovered.contains(p.embeddingModel));
      if (stillCapable) {
        await (_db.update(_db.savedItems)
              ..where((s) => s.id.equals(item.id)))
            .write(const SavedItemsCompanion(
                embeddingStatus: Value(EmbeddingStatus.ready)));
      }
    }
    // If at least one provider failed we leave the row as 'pending'
    // so the next tick retries it against the full capable set.
    // HealthMonitor.recordFailure already quarantined the flaky
    // provider, so the next retry either skips it (quarantined →
    // removed from the selection? no — the queue uses its own
    // list, not the selector) or succeeds. See note below.
    //
    // NOTE: _processItem intentionally queries all capable providers
    // regardless of quarantine state so that a provider recovering
    // mid-session can catch up on missed items without waiting for
    // a probe cycle.
  }

  Future<bool> _computeAndStore(
    String itemId,
    ProviderConfig provider,
    String text,
  ) async {
    try {
      final (vector, elapsed) =
          await _embeddingService.embed(provider, text);
      _healthMonitor.recordSuccess(provider.id, elapsed);

      await _db.into(_db.itemEmbeddings).insertOnConflictUpdate(
            ItemEmbeddingsCompanion.insert(
              itemId: itemId,
              model: provider.embeddingModel!,
              providerId: provider.id,
              vector: EmbeddingCodec.encode(vector),
              createdAt: Value(DateTime.now()),
            ),
          );
      return true;
    } catch (e) {
      debugPrint('[FanoutQueue] embed failed '
          '(item=$itemId provider=${provider.id}): $e');
      _healthMonitor.recordFailure(provider.id);
      return false;
    }
  }

  // ---- per-provider backfill ----

  /// Walk every saved_items row and compute a vector using [provider]'s
  /// embedding model, storing the result in `item_embeddings`. Used
  /// when the user adds a new embedding-capable provider mid-life.
  ///
  /// Sets `provider_configs.embedding_backfilled_at` on completion,
  /// which is the signal the HealthMonitor uses to admit the provider
  /// into the query pool. Until this returns, queries continue to
  /// use whatever other providers are currently healthy.
  ///
  /// Concurrency is bounded by [_backfillConcurrency] to stay under
  /// per-second rate limits on most provider APIs.
  Future<void> backfillProvider(ProviderConfig provider) async {
    if (provider.embeddingCapability != EmbeddingCapability.yes ||
        provider.embeddingModel == null) {
      debugPrint('[FanoutQueue] backfillProvider called for '
          'non-capable ${provider.id}, skipping');
      return;
    }

    // 1. Find rows that already have a vector for this model (could
    //    exist from a previous session if the user deleted and
    //    re-added the provider).
    final existingRows = await (_db.select(_db.itemEmbeddings)
          ..where((e) => e.model.equals(provider.embeddingModel!)))
        .get();
    final alreadyCovered = existingRows.map((e) => e.itemId).toSet();

    // 2. Load all saved_items that still need a vector.
    final allItems = await _db.select(_db.savedItems).get();
    final pending = allItems
        .where((i) => !alreadyCovered.contains(i.id))
        .toList();

    _backfillProgress[provider.id] = (
      total: allItems.length,
      completed: alreadyCovered.length,
    );

    // 3. Dispatch in chunks of [_backfillConcurrency].
    for (int i = 0; i < pending.length; i += _backfillConcurrency) {
      final chunk = pending.skip(i).take(_backfillConcurrency).toList();
      await Future.wait(
        chunk.map((item) =>
            _computeAndStore(item.id, provider, EmbeddingInputComposer.compose(item))),
        eagerError: false,
      );

      // Update progress counter. Counter counts "attempted", not
      // "succeeded" — failures leave the row without coverage from
      // this provider but the overall backfill still "completes"
      // (the provider is admitted to the pool, any still-missing
      // rows will be picked up by the regular catch-up tick).
      _backfillProgress[provider.id] = (
        total: allItems.length,
        completed: math.min(alreadyCovered.length + i + chunk.length,
            allItems.length),
      );
    }

    // 4. Mark the provider as backfilled so HealthMonitor admits it.
    await (_db.update(_db.providerConfigs)
          ..where((p) => p.id.equals(provider.id)))
        .write(ProviderConfigsCompanion(
            embeddingBackfilledAt: Value(DateTime.now())));

    _backfillProgress.remove(provider.id);
  }

  /// Current backfill progress for [providerId], or null if no
  /// backfill is in flight for that provider. Used by the Settings
  /// page to render a progress bar.
  ({int total, int completed})? backfillProgressFor(String providerId) =>
      _backfillProgress[providerId];
}

