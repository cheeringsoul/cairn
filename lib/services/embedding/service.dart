import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../http_client.dart';
import '../db/database.dart';
import '../llm/provider_factory.dart';
import '../llm/llm_provider.dart';
import '../secure_key_store.dart';

/// Outcome of probing a provider's embedding capability.
///
/// [capability]:
///   - `'yes'`  provider has a working /embeddings endpoint
///   - `'no'`   provider doesn't support embeddings (or probing
///              definitively proved it doesn't)
///   - `'rate_limited'` transient failure (network / 5xx / timeout);
///              probe again later, don't treat as no-capability
///
/// When `capability == 'yes'`, [model] is the model name to use and
/// [latency] is the observed round-trip time of the probe call (used
/// as the first data point in HealthMonitor's rolling average).
class EmbeddingProbeResult {
  final String capability;
  final String? model;
  final Duration? latency;

  const EmbeddingProbeResult({
    required this.capability,
    this.model,
    this.latency,
  });

  static const rateLimited = EmbeddingProbeResult(capability: EmbeddingCapability.rateLimited);
  static const no = EmbeddingProbeResult(capability: EmbeddingCapability.no);
}

/// Single-shot client for calling the embedding endpoint of any
/// configured LLM provider. Stateless — it doesn't cache results or
/// track health; that's the HealthMonitor's job.
///
/// Two entry points:
///
///   * [embed] computes a vector for the given text. Throws on any
///     failure — callers (HealthMonitor, FanoutQueue, ChatProvider)
///     interpret the error to update quarantine / retry state.
///
///   * [probe] tries to determine whether a newly added provider
///     supports embeddings. Walks a two-layer fallback: first the
///     provider's /embeddings endpoint with a guessed model name;
///     if that returns 4xx (unknown route / unknown model), asks
///     the provider's chat endpoint "do you support embeddings?"
///     and parses the reply.
class EmbeddingService {
  /// Per-kind default embedding model. Used as the first-guess for
  /// [probe] and as the initial stored value in
  /// `provider_configs.embedding_model`. Kinds not listed here are
  /// assumed to have no embedding endpoint (e.g. 'anthropic',
  /// 'moonshot', 'baichuan', 'stepfun', 'groq', 'custom').
  static const Map<String, String> defaultEmbeddingModels = {
    'openai': 'text-embedding-3-small',
    'qwen': 'text-embedding-v3',
    'gemini': 'text-embedding-004',
    'zhipu': 'embedding-2',
    'mistral': 'mistral-embed',
    'doubao': 'doubao-embedding-text-240715',
    'minimax': 'embo-01',
    'siliconflow': 'BAAI/bge-m3',
  };

  /// Provider kinds known to have no embedding endpoint. Probe
  /// short-circuits to `capability='no'` for these, saving an HTTP
  /// round-trip and an LLM call.
  static const Set<String> knownNoEmbeddingKinds = {
    'anthropic',
    'deepseek',
    'moonshot',
    'baichuan',
    'stepfun',
    'groq',
    'grok',
  };

  static const _probeTimeoutSeconds = EmbeddingTiming.probeTimeout;
  static const _embedTimeout = EmbeddingTiming.embedTimeout;

  final http.Client _http;

  EmbeddingService({http.Client? httpClient})
      : _http = httpClient ?? createPlatformClient();

  // ---- core embed call ----

  /// Compute an embedding vector for [text] using [provider]. Uses
  /// the provider's stored `embeddingModel` (or [overrideModel] if
  /// supplied, e.g. during probing). Returns the vector plus the
  /// observed wall-clock duration of the HTTP call, which callers
  /// feed into the rolling latency average.
  ///
  /// Anthropic is a special case: the official Anthropic API has no
  /// /embeddings endpoint, so this method throws immediately if
  /// someone misconfigures an Anthropic row with
  /// `embeddingCapability == 'yes'`.
  Future<(List<double> vector, Duration elapsed)> embed(
    ProviderConfig provider,
    String text, {
    String? overrideModel,
  }) async {
    if (knownNoEmbeddingKinds.contains(provider.kind)) {
      throw StateError(
          '${provider.kind} does not provide an /embeddings endpoint.');
    }

    final model = overrideModel ??
        provider.embeddingModel ??
        defaultEmbeddingModels[provider.kind];
    if (model == null || model.isEmpty) {
      throw StateError('No embedding model configured for '
          '${provider.displayName} (kind=${provider.kind}).');
    }

    final apiKey = await SecureKeyStore.instance.readApiKey(provider.id);
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('Missing API key for ${provider.displayName}.');
    }

    final stopwatch = Stopwatch()..start();
    final response = await _http
        .post(
          Uri.parse('${provider.baseUrl}/embeddings'),
          headers: _embeddingHeaders(apiKey),
          body: jsonEncode({'model': model, 'input': text}),
        )
        .timeout(_embedTimeout);
    stopwatch.stop();

    if (response.statusCode != 200) {
      throw http.ClientException(
        'embeddings HTTP ${response.statusCode}: ${response.body}',
        Uri.parse('${provider.baseUrl}/embeddings'),
      );
    }

    final vector = _parseEmbeddingResponse(response.body);
    if (vector == null) {
      throw const FormatException(
          'embeddings response missing data[0].embedding');
    }
    return (vector, stopwatch.elapsed);
  }

  // ---- capability probing ----

  /// Probe whether a provider supports an embedding endpoint. This
  /// is a non-throwing convenience on top of [embed] — all failures
  /// are collapsed into an [EmbeddingProbeResult].
  ///
  /// Strategy:
  ///   1. If kind has a default embedding model → HTTP probe with it
  ///   2. If HTTP probe returns 200 → done (`yes`)
  ///   3. If HTTP probe returns 4xx → ask the LLM via chat fallback
  ///   4. If HTTP probe throws network error → `rate_limited`
  ///      (transient; retry next probe cycle; do NOT LLM-fallback
  ///      because network errors say nothing about capability)
  Future<EmbeddingProbeResult> probe(ProviderConfig provider) async {
    // Short-circuit for providers known to have no embedding endpoint.
    if (knownNoEmbeddingKinds.contains(provider.kind)) {
      return EmbeddingProbeResult.no;
    }

    final guessedModel = defaultEmbeddingModels[provider.kind];

    // Layer 1: HTTP probe with the guessed model.
    if (guessedModel != null) {
      final result = await _httpProbeWithModel(provider, guessedModel);
      if (result != null) return result;
      // null means HTTP probe returned a 4xx we should fall back from
    }

    // Layer 2: LLM fallback — ask the provider's chat model directly
    // what embedding model it supports.
    try {
      final answer = await _askLlmAboutEmbeddingSupport(provider);
      if (answer != null && answer.hasEmbedding && answer.model != null) {
        // Verify by actually calling /embeddings with that model.
        final verified =
            await _httpProbeWithModel(provider, answer.model!);
        if (verified != null) return verified;
      }
    } catch (e) {
      debugPrint('[EmbeddingService] LLM probe fallback failed: $e');
    }

    return EmbeddingProbeResult.no;
  }

  /// Call `/embeddings` with a specific model and return:
  ///   * result with `yes` + model + latency → success
  ///   * result with `rate_limited` → network error / timeout / 5xx
  ///   * `null` → definitive 4xx (caller should try LLM fallback)
  Future<EmbeddingProbeResult?> _httpProbeWithModel(
    ProviderConfig provider,
    String model,
  ) async {
    try {
      final apiKey = await SecureKeyStore.instance.readApiKey(provider.id);
      if (apiKey == null || apiKey.isEmpty) return null;

      final stopwatch = Stopwatch()..start();
      final response = await _http
          .post(
            Uri.parse('${provider.baseUrl}/embeddings'),
            headers: _embeddingHeaders(apiKey),
            body: jsonEncode({'model': model, 'input': 'test'}),
          )
          .timeout(_probeTimeoutSeconds);
      stopwatch.stop();

      if (response.statusCode == 200) {
        final vector = _parseEmbeddingResponse(response.body);
        if (vector != null && vector.isNotEmpty) {
          return EmbeddingProbeResult(
            capability: EmbeddingCapability.yes,
            model: model,
            latency: stopwatch.elapsed,
          );
        }
        return null; // 200 but malformed — treat like 4xx, fall back
      }
      if (response.statusCode >= 500) {
        return EmbeddingProbeResult.rateLimited;
      }
      return null; // 4xx — fall back to LLM probe
    } on TimeoutException {
      return EmbeddingProbeResult.rateLimited;
    } catch (e) {
      debugPrint('[EmbeddingService] probe network error: $e');
      return EmbeddingProbeResult.rateLimited;
    }
  }

  /// Ask the provider's chat model whether it exposes an embedding
  /// endpoint and what model name to use. Accepts a strict-JSON
  /// reply shape: `{"has_embedding": true/false, "model": "..."}`.
  Future<_LlmProbeAnswer?> _askLlmAboutEmbeddingSupport(
    ProviderConfig provider,
  ) async {
    final adapter = await buildProvider(provider);

    // Drain the stream into a single response string. We don't need
    // streaming for this one-shot call.
    final buf = StringBuffer();
    await for (final chunk in adapter.streamChat(
      messages: const [
        LlmMessage(role: 'user', content: '''
Does your API expose an /embeddings endpoint for text retrieval?
If yes, what is the exact model name I should pass?

Reply strictly in JSON on a single line, no prose, no markdown:
{"has_embedding": true, "model": "..."}
or
{"has_embedding": false, "model": null}
'''),
      ],
      model: provider.defaultModel,
    )) {
      buf.write(chunk);
    }

    final raw = buf.toString().trim();
    if (raw.isEmpty) return null;

    // Extract the first JSON object in the reply (tolerant to markdown
    // fences or preamble the model may add despite instructions).
    final jsonStart = raw.indexOf('{');
    final jsonEnd = raw.lastIndexOf('}');
    if (jsonStart < 0 || jsonEnd <= jsonStart) return null;
    final jsonStr = raw.substring(jsonStart, jsonEnd + 1);

    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) return null;
      final has = decoded['has_embedding'];
      final model = decoded['model'];
      return _LlmProbeAnswer(
        hasEmbedding: has is bool && has,
        model: model is String && model.isNotEmpty ? model : null,
      );
    } catch (_) {
      return null;
    }
  }

  // ---- helpers ----

  Map<String, String> _embeddingHeaders(String apiKey) => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  /// Parse the OpenAI-shape embeddings response:
  ///   {"data": [{"embedding": [0.1, 0.2, ...]}]}
  /// Returns null if the shape doesn't match.
  List<double>? _parseEmbeddingResponse(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map) return null;
      final data = json['data'];
      if (data is! List || data.isEmpty) return null;
      final first = data.first;
      if (first is! Map) return null;
      final vec = first['embedding'];
      if (vec is! List) return null;
      return vec.map((e) => (e as num).toDouble()).toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _http.close();
  }
}

class _LlmProbeAnswer {
  final bool hasEmbedding;
  final String? model;
  const _LlmProbeAnswer({required this.hasEmbedding, this.model});
}
