import 'dart:convert';

import 'package:http/http.dart' as http;

/// Key-less fallback that wraps DuckDuckGo. Tries the Instant Answer
/// API first (cleanly structured but narrow coverage) and falls back
/// to scraping the HTML lite endpoint for everything else.
///
/// Results are not as good as a real search API — this is the bottom
/// of the dispatcher fallback chain. Kept so the `web_search` tool
/// still works when the user hasn't configured any paid backend.
class DdgClient {
  static Future<Map<String, dynamic>> search(String query) async {
    final instant = await _instantAnswer(query);
    if (instant != null) return instant;
    return _htmlSearch(query);
  }

  static Future<Map<String, dynamic>?> _instantAnswer(String query) async {
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
      return {'query': query, 'backend': 'ddg', 'results': results};
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> _htmlSearch(String query) async {
    final uri = Uri.parse('https://html.duckduckgo.com/html/')
        .replace(queryParameters: {'q': query});
    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'Cairn/1.0',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return {
          'query': query,
          'backend': 'ddg',
          'error': 'Search returned ${response.statusCode}',
        };
      }

      final snippets = _parseHtmlResults(response.body);
      return {'query': query, 'backend': 'ddg', 'results': snippets};
    } catch (e) {
      return {'query': query, 'backend': 'ddg', 'error': '$e'};
    }
  }

  /// Very lightweight HTML parser for DuckDuckGo HTML lite. Relies on
  /// the `result__a` / `result__snippet` class names, which are
  /// fragile — this is why we prefer Tavily / Brave when available.
  static List<Map<String, String>> _parseHtmlResults(String html) {
    final results = <Map<String, String>>[];
    final resultBlocks = RegExp(
      r'class="result__a"[^>]*href="([^"]*)"[^>]*>(.*?)</a>',
      dotAll: true,
    ).allMatches(html);

    final snippetBlocks = RegExp(
      r'class="result__snippet"[^>]*>(.*?)</a>',
      dotAll: true,
    ).allMatches(html);

    final snippetList =
        snippetBlocks.map((m) => _stripHtml(m.group(1) ?? '')).toList();

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

  static String _stripHtml(String html) => html
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
