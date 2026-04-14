import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../tool_registry.dart';

/// Searches the web using the DuckDuckGo Instant Answer API (free,
/// no API key required). Falls back to a simple HTML scrape of
/// DuckDuckGo lite for broader queries.
class WebSearchTool extends Tool {
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

    // Try DuckDuckGo Instant Answer API first — it gives structured
    // results for many factual queries.
    final iaResult = await _instantAnswer(query);
    if (iaResult != null) return iaResult;

    // Fall back to DuckDuckGo HTML lite for general queries.
    return _htmlSearch(query);
  }

  Future<String?> _instantAnswer(String query) async {
    final uri = Uri.parse('https://api.duckduckgo.com/')
        .replace(queryParameters: {'q': query, 'format': 'json', 'no_html': '1'});
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final abstractText = data['AbstractText'] as String? ?? '';
      final answer = data['Answer'] as String? ?? '';
      final relatedTopics = data['RelatedTopics'] as List? ?? [];

      if (abstractText.isEmpty && answer.isEmpty && relatedTopics.isEmpty) {
        return null;
      }

      final results = <Map<String, String>>[];
      if (answer.isNotEmpty) {
        results.add({'type': 'answer', 'text': answer});
      }
      if (abstractText.isNotEmpty) {
        results.add({
          'type': 'abstract',
          'text': abstractText,
          'source': data['AbstractSource'] as String? ?? '',
          'url': data['AbstractURL'] as String? ?? '',
        });
      }
      for (final topic in relatedTopics.take(5)) {
        if (topic is Map && topic['Text'] != null) {
          results.add({
            'type': 'related',
            'text': topic['Text'] as String? ?? '',
            'url': topic['FirstURL'] as String? ?? '',
          });
        }
      }

      if (results.isEmpty) return null;
      return jsonEncode({'query': query, 'results': results});
    } catch (_) {
      return null;
    }
  }

  Future<String> _htmlSearch(String query) async {
    final uri = Uri.parse('https://html.duckduckgo.com/html/')
        .replace(queryParameters: {'q': query});
    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'Cairn/1.0',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return jsonEncode({
          'query': query,
          'error': 'Search returned ${response.statusCode}',
        });
      }

      // Parse result snippets from the HTML response.
      final snippets = _parseHtmlResults(response.body);
      return jsonEncode({'query': query, 'results': snippets});
    } catch (e) {
      return jsonEncode({'query': query, 'error': '$e'});
    }
  }

  /// Very lightweight HTML parser that extracts result titles and snippets
  /// from DuckDuckGo HTML lite. No dependency on an HTML parser package.
  List<Map<String, String>> _parseHtmlResults(String html) {
    final results = <Map<String, String>>[];
    // DuckDuckGo HTML wraps each result in <div class="result">.
    // Titles are in <a class="result__a"> and snippets in
    // <a class="result__snippet">.
    final resultBlocks = RegExp(
      r'class="result__a"[^>]*href="([^"]*)"[^>]*>(.*?)</a>',
      dotAll: true,
    ).allMatches(html);

    final snippetBlocks = RegExp(
      r'class="result__snippet"[^>]*>(.*?)</a>',
      dotAll: true,
    ).allMatches(html);

    final snippetList = snippetBlocks.map((m) => _stripHtml(m.group(1) ?? '')).toList();

    var i = 0;
    for (final m in resultBlocks) {
      if (results.length >= 5) break;
      final url = m.group(1) ?? '';
      final title = _stripHtml(m.group(2) ?? '');
      final snippet = i < snippetList.length ? snippetList[i] : '';
      if (title.isNotEmpty) {
        results.add({'title': title, 'url': url, 'snippet': snippet});
      }
      i++;
    }
    return results;
  }

  String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]+>'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
}
