import 'dart:convert';

import 'package:flutter/material.dart';

import '../../secure_key_store.dart';
import '../../settings_provider.dart';
import '../tool_registry.dart';
import 'search/brave_client.dart';
import 'search/ddg_client.dart';
import 'search/tavily_client.dart';

/// Dispatcher for the single LLM-visible `web_search` tool.
///
/// The LLM sees one tool with one name. What actually runs is picked
/// here at execute time, based on the user's Settings toggles + stored
/// API keys. Priority:
///
/// 1. Tavily — if its toggle is on AND a key is stored. Returns
///    LLM-cleaned article bodies, best signal-to-noise for grounding.
/// 2. Brave  — same conditions. Snippet-only results from an
///    independent index.
/// 3. DuckDuckGo — always-available keyless fallback. Narrow Instant
///    Answer coverage + fragile HTML scrape; kept so the feature
///    still works before the user configures anything.
class WebSearchTool extends Tool {
  final SettingsProvider? _settings;

  WebSearchTool({SettingsProvider? settings}) : _settings = settings;

  @override
  String get name => 'web_search';

  @override
  String get displayName => 'Web Search';

  @override
  String get statusLabel => 'Searching the web…';

  @override
  String get description =>
      'Search the internet for real-time information. Use this when the '
      'user asks about current events, recent news, live data, or anything '
      'that requires up-to-date information beyond your training data.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': 'The search query.',
          },
        },
        'required': ['query'],
      };

  @override
  IconData get icon => Icons.search;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    final query = args['query'] as String? ?? '';
    if (query.isEmpty) {
      return jsonEncode({'error': 'Empty search query'});
    }

    final settings = _settings;
    final tavilyActive = settings != null &&
        settings.hasTavilyKey &&
        settings.isToolEnabled(SearchBackendNames.tavily,
            defaultValue: false);
    final braveActive = settings != null &&
        settings.hasBraveKey &&
        settings.isToolEnabled(SearchBackendNames.brave, defaultValue: false);

    if (tavilyActive) {
      final key = await SecureKeyStore.instance.readSearchKey('tavily');
      if (key != null && key.isNotEmpty) {
        try {
          final result =
              await TavilyClient.search(apiKey: key, query: query);
          return jsonEncode(result);
        } catch (e) {
          // Fall through to the next backend rather than failing the
          // whole turn — the user's real intent is "find something",
          // not "use Tavily specifically".
          final next = await _tryBrave(query, settings, braveActive);
          return next ?? await _ddg(query);
        }
      }
    }

    if (braveActive) {
      final result = await _tryBrave(query, settings, true);
      if (result != null) return result;
    }

    return _ddg(query);
  }

  Future<String?> _tryBrave(
      String query, SettingsProvider? settings, bool active) async {
    if (!active) return null;
    final key = await SecureKeyStore.instance.readSearchKey('brave');
    if (key == null || key.isEmpty) return null;
    try {
      final result = await BraveClient.search(apiKey: key, query: query);
      return jsonEncode(result);
    } catch (_) {
      return null;
    }
  }

  Future<String> _ddg(String query) async {
    final result = await DdgClient.search(query);
    return jsonEncode(result);
  }
}
