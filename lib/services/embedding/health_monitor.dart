import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../db/database.dart';
import 'service.dart';

/// Per-provider embedding health state maintained by [EmbeddingHealthMonitor].
class _ProviderHealth {
  final String providerId;

  /// Ring buffer of recent successful probe/call latencies. Rolling
  /// average over this list is used as the "fastness" score for
  /// query-time provider selection.
  final List<Duration> recentLatencies = [];

  /// Set to true the instant a real query / probe fails. Kept until
  /// the next scheduled probe re-verifies health. Quarantined
  /// providers are filtered out of query selection.
  bool quarantined = false;

  /// The dart:async Timer that fires the next probe for this provider.
  /// Separate timer per provider so their probe schedules stay
  /// independent and never collide (by design — see the bootstrap
  /// offset logic in [EmbeddingHealthMonitor._scheduleBootstrap]).
  Timer? timer;

  _ProviderHealth(this.providerId);

  Duration get rollingAvgLatency {
    if (recentLatencies.isEmpty) {
      // No measurements yet → treat as infinitely slow so freshly
      // added providers with zero data points don't beat healthy
      // ones that actually have measurements.
      return const Duration(seconds: 999);
    }
    final totalMicros = recentLatencies
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a + b);
    return Duration(microseconds: totalMicros ~/ recentLatencies.length);
  }
}

/// Supervises embedding-capable providers in the background:
///
///   1. Maintains a rolling-average latency per provider (last 5
///      successful embed calls). The query path picks the fastest
///      one.
///   2. Runs a probe every 10 minutes to keep the latency data
///      current and to rehabilitate quarantined providers that
///      recovered since the last failure.
///   3. Immediately quarantines any provider whose real query call
///      throws. The next probe tick re-checks it.
///
/// ## Probe stagger
///
/// All providers run on independent Timers so their probes never
/// collide. Bootstrap offset for the i-th provider (by creation
/// order) is:
///
///   p1: +3s      (first provider probed almost immediately)
///   p2: +60s
///   p3: +120s
///   pN: min(60 * (N-1), 570)s
///
/// After the first probe fires, the next one is scheduled at
/// `now + 10min`, carrying the stagger forward forever.
///
/// ## Lifetime
///
/// Created once by main.dart's MultiProvider. [start] is called
/// after SettingsProvider finishes loading its provider list; it
/// schedules all the initial Timers. [stop] cancels everything
/// (used on dispose).
///
/// [addProvider] / [removeProvider] handle providers being added
/// or deleted after the initial start — new providers get a
/// +3s bootstrap offset of their own, deletions cancel the timer.
class EmbeddingHealthMonitor {
  final EmbeddingService _embeddingService;

  // Reference to the current provider list, kept in sync via
  // [setProviders] whenever SettingsProvider emits a change. The
  // monitor looks up a provider by id at probe time so stale rows
  // (e.g. a provider deleted between schedule and fire) are handled
  // gracefully.
  List<ProviderConfig> _providers = const [];

  final Map<String, _ProviderHealth> _health = {};

  static const _probeIntervalSeconds = EmbeddingTiming.probeInterval;
  static const _bootstrapFirstOffset = EmbeddingTiming.bootstrapFirstOffset;
  static const _bootstrapOffsetStep = EmbeddingTiming.bootstrapOffsetStep;
  static const _bootstrapMaxOffset = EmbeddingTiming.bootstrapMaxOffset;
  static const _rollingWindowSize = EmbeddingTiming.rollingSampleCount;

  EmbeddingHealthMonitor(this._embeddingService);

  /// Initialize monitoring for all currently-capable providers. Call
  /// this once after [SettingsProvider.load] finishes.
  void start(List<ProviderConfig> providers) {
    stop();
    _providers = providers;

    final capable = providers
        .where((p) => p.embeddingCapability == EmbeddingCapability.yes)
        .toList();

    for (int i = 0; i < capable.length; i++) {
      _scheduleBootstrap(capable[i], i);
    }
  }

  /// Cancel all timers and drop internal state. Called on dispose
  /// or when restarting the monitor (e.g. SettingsProvider reloaded).
  void stop() {
    for (final h in _health.values) {
      h.timer?.cancel();
    }
    _health.clear();
  }

  /// Update the cached provider list. SettingsProvider calls this
  /// after any mutation (add/delete/update) so the monitor's
  /// bookkeeping stays in sync.
  void setProviders(List<ProviderConfig> providers) {
    _providers = providers;
  }

  /// Called when a new provider is added at runtime via the
  /// Settings UI. Immediately schedules a +3s bootstrap probe.
  /// No-op if the provider isn't embedding-capable — the next
  /// Settings addProvider flow will call this again after
  /// capability is detected.
  void addProvider(ProviderConfig provider) {
    if (provider.embeddingCapability != EmbeddingCapability.yes) return;
    if (_health.containsKey(provider.id)) return;
    _scheduleBootstrap(provider, 0); // +3s, regardless of index
  }

  /// Called when a provider is removed. Cancels the timer but does
  /// NOT touch the `item_embeddings` rows — per design, embedding
  /// data survives provider deletion so re-adding later is cheap.
  void removeProvider(String providerId) {
    final h = _health.remove(providerId);
    h?.timer?.cancel();
  }

  // ---- scheduling ----

  void _scheduleBootstrap(ProviderConfig provider, int indexInList) {
    final offset = indexInList == 0
        ? _bootstrapFirstOffset
        : Duration(
            seconds: math.min(
              indexInList * _bootstrapOffsetStep.inSeconds,
              _bootstrapMaxOffset.inSeconds,
            ),
          );
    _scheduleProbe(provider.id, offset);
  }

  void _scheduleProbe(String providerId, Duration delay) {
    final health = _health.putIfAbsent(
      providerId,
      () => _ProviderHealth(providerId),
    );
    health.timer?.cancel();
    health.timer = Timer(delay, () => _runProbe(providerId));
  }

  Future<void> _runProbe(String providerId) async {
    final provider = _lookupProvider(providerId);
    if (provider == null) {
      // Provider was deleted between scheduling and firing. Clean up.
      _health.remove(providerId);
      return;
    }
    if (provider.embeddingCapability != 'yes') {
      // Provider's capability was downgraded (e.g. API key revoked
      // and capability flipped to 'no'). Stop probing it.
      _health.remove(providerId)?.timer?.cancel();
      return;
    }

    try {
      final (_, elapsed) = await _embeddingService.embed(provider, 'test');
      _recordSuccess(providerId, elapsed);
    } catch (e) {
      debugPrint('[HealthMonitor] probe failed for $providerId: $e');
      _recordFailure(providerId);
    }

    // Schedule next probe regardless of success / failure.
    if (_health.containsKey(providerId)) {
      _scheduleProbe(
        providerId,
        _probeIntervalSeconds,
      );
    }
  }

  // ---- observations from real traffic ----

  /// Called by ChatProvider / FanoutQueue after a successful embed
  /// call to keep the rolling latency fresh.
  void recordSuccess(String providerId, Duration elapsed) =>
      _recordSuccess(providerId, elapsed);

  /// Called by ChatProvider / FanoutQueue when a real embed call
  /// throws. Immediately quarantines the provider so the next query
  /// picks a different one.
  void recordFailure(String providerId) => _recordFailure(providerId);

  void _recordSuccess(String providerId, Duration elapsed) {
    final h = _health.putIfAbsent(
      providerId,
      () => _ProviderHealth(providerId),
    );
    h.recentLatencies.add(elapsed);
    if (h.recentLatencies.length > _rollingWindowSize) {
      h.recentLatencies.removeAt(0);
    }
    h.quarantined = false;
  }

  void _recordFailure(String providerId) {
    final h = _health.putIfAbsent(
      providerId,
      () => _ProviderHealth(providerId),
    );
    h.quarantined = true;
  }

  // ---- query selection ----

  /// Returns the ids of healthy embedding-capable providers, sorted
  /// by rolling-average latency ascending. Filters out:
  ///   - providers that aren't yet backfill-complete (`embeddingBackfilledAt == null`)
  ///   - quarantined providers
  ///
  /// ChatProvider.sendMessage walks this list trying each in order
  /// until one succeeds. All-failures = fall back to "no recall".
  List<String> selectHealthyOrderedByLatency() {
    final eligible = <ProviderConfig>[];
    for (final p in _providers) {
      if (p.embeddingCapability != 'yes') continue;
      if (p.embeddingBackfilledAt == null) continue;
      final h = _health[p.id];
      if (h == null || h.quarantined) continue;
      eligible.add(p);
    }

    eligible.sort((a, b) {
      final la = _health[a.id]!.rollingAvgLatency;
      final lb = _health[b.id]!.rollingAvgLatency;
      return la.compareTo(lb);
    });

    return eligible.map((p) => p.id).toList();
  }

  /// Whether [providerId] is currently considered healthy. Used by
  /// the UI (e.g. Settings page badges).
  bool isHealthy(String providerId) {
    final h = _health[providerId];
    return h != null && !h.quarantined && h.recentLatencies.isNotEmpty;
  }

  // ---- helpers ----

  ProviderConfig? _lookupProvider(String providerId) {
    for (final p in _providers) {
      if (p.id == providerId) return p;
    }
    return null;
  }
}
