import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'db/database.dart';
import 'secure_key_store.dart';
import 'settings_provider.dart';

/// Fetches available models from a provider's /v1/models endpoint.
/// Models are pre-fetched when providers are configured and refreshed
/// in the background every 10 minutes.
class ModelService {
  static const _cacheValidityMinutes = 10;
  static const _refreshIntervalMinutes = 10;
  static const _fetchTimeoutSeconds = 8;
  static const _anthropicApiVersion = '2023-06-01';

  /// Cached results keyed by provider ID.
  static final _cache = <String, _CacheEntry>{};

  /// Notifies listeners when the cache is updated.
  static final ValueNotifier<int> cacheVersion = ValueNotifier(0);

  static Timer? _refreshTimer;
  static List<ProviderConfig> _providers = const [];

  /// Start background refresh for the given providers.
  /// Should be called once after settings are loaded and whenever
  /// the provider list changes.
  static void startBackgroundRefresh(List<ProviderConfig> providers) {
    _providers = providers;
    _refreshTimer?.cancel();
    // Eagerly fetch all providers now.
    for (final p in providers) {
      _fetchAndCache(p);
    }
    _refreshTimer = Timer.periodic(const Duration(minutes: _refreshIntervalMinutes), (_) {
      for (final p in _providers) {
        _fetchAndCache(p);
      }
    });
  }

  /// Stop the background refresh timer.
  static void stopBackgroundRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Force refresh all providers. Returns a future that completes
  /// when all fetches are done.
  static Future<void> refreshAll() async {
    await Future.wait([
      for (final p in _providers) _fetchAndCache(p),
    ]);
  }

  /// Get cached models synchronously. Returns empty list if not yet cached.
  static List<String> getCachedModels(ProviderConfig config) {
    return _cache[config.id]?.models ?? _fallback[config.kind] ?? [];
  }

  /// Get available models for the given provider config.
  /// Results are cached for 10 minutes.
  static Future<List<String>> getModels(ProviderConfig config) async {
    final cached = _cache[config.id];
    if (cached != null &&
        DateTime.now().difference(cached.time).inMinutes < _cacheValidityMinutes) {
      return cached.models;
    }

    try {
      final models = await _fetchModels(config);
      _cache[config.id] = _CacheEntry(models, DateTime.now());
      cacheVersion.value++;
      return models;
    } catch (_) {
      return _fallback[config.kind] ?? [];
    }
  }

  static Future<void> _fetchAndCache(ProviderConfig config) async {
    try {
      final models = await _fetchModels(config);
      _cache[config.id] = _CacheEntry(models, DateTime.now());
      cacheVersion.value++;
    } catch (_) {
      // Keep existing cache or use fallback on failure.
      _cache[config.id] ??=
          _CacheEntry(_fallback[config.kind] ?? [], DateTime.now());
    }
  }

  static Future<List<String>> _fetchModels(ProviderConfig config) async {
    final apiKey = await SecureKeyStore.instance.readApiKey(config.id);
    if (apiKey == null || apiKey.isEmpty) return _fallback[config.kind] ?? [];

    final uri = Uri.parse('${config.baseUrl}/models');
    final headers = <String, String>{};

    if (config.kind == ProviderKinds.anthropic) {
      headers['x-api-key'] = apiKey;
      headers['anthropic-version'] = _anthropicApiVersion;
    } else {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: _fetchTimeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body);

    // OpenAI / DeepSeek format: { "data": [{"id": "model-name"}, ...] }
    // Anthropic format: { "data": [{"id": "model-name"}, ...] }
    final data = json['data'] as List?;
    if (data == null || data.isEmpty) {
      return _fallback[config.kind] ?? [];
    }

    final models = data
        .map<String>((m) => m['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    // Sort: put chat models first, sort alphabetically.
    models.sort();
    return models;
  }

  static const _fallback = <String, List<String>>{
    'openai': [
      'gpt-4o',
      'gpt-4o-mini',
      'gpt-4.1',
      'gpt-4.1-mini',
      'gpt-4.1-nano',
      'o3-mini',
    ],
    'anthropic': [
      'claude-opus-4-6',
      'claude-sonnet-4-6',
      'claude-haiku-4-5',
    ],
    'deepseek': [
      'deepseek-chat',
      'deepseek-reasoner',
    ],
    'qwen': [
      'qwen-plus',
      'qwen-turbo',
      'qwen-max',
      'qwen-long',
    ],
    'zhipu': [
      'glm-4-flash',
      'glm-4-plus',
      'glm-4-long',
    ],
    'moonshot': [
      'moonshot-v1-8k',
      'moonshot-v1-32k',
      'moonshot-v1-128k',
    ],
    'doubao': [
      'doubao-1.5-pro-32k',
      'doubao-1.5-pro-256k',
      'doubao-1.5-lite-32k',
    ],
    'minimax': [
      'MiniMax-Text-01',
    ],
    'baichuan': [
      'Baichuan4',
      'Baichuan3-Turbo',
    ],
    'stepfun': [
      'step-1-8k',
      'step-1-32k',
      'step-2-16k',
    ],
    'siliconflow': [
      'deepseek-ai/DeepSeek-V3',
      'Qwen/Qwen2.5-72B-Instruct',
      'Pro/deepseek-ai/DeepSeek-R1',
    ],
    'gemini': [
      'gemini-2.5-flash',
      'gemini-2.5-pro',
      'gemini-2.0-flash',
    ],
    'mistral': [
      'mistral-large-latest',
      'mistral-small-latest',
    ],
    'groq': [
      'llama-3.3-70b-versatile',
      'llama-3.1-8b-instant',
      'gemma2-9b-it',
    ],
    'grok': [
      'grok-2-latest',
      'grok-2-1212',
      'grok-2-vision-1212',
      'grok-beta',
    ],
  };
}

class _CacheEntry {
  final List<String> models;
  final DateTime time;
  _CacheEntry(this.models, this.time);
}
