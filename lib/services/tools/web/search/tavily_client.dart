import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin client for Tavily's `/search` endpoint. Tavily is an LLM-first
/// search API: it returns pre-fetched + cleaned article bodies rather
/// than bare SERP snippets, so the LLM can ground on real content
/// without a second fetch step.
///
/// Docs: https://docs.tavily.com/docs/rest-api/api-reference
class TavilyClient {
  static const _endpoint = 'https://api.tavily.com/search';

  /// Run a search. Returns a JSON-encodable map with the same shape the
  /// dispatcher expects from every backend:
  /// `{query, results: [{title, url, snippet, content?}]}`.
  static Future<Map<String, dynamic>> search({
    required String apiKey,
    required String query,
    int maxResults = 5,
  }) async {
    final body = jsonEncode({
      'api_key': apiKey,
      'query': query,
      'search_depth': 'advanced',
      'max_results': maxResults,
      'include_answer': false,
      'include_raw_content': false,
    });

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
          'Tavily ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = (decoded['results'] as List?) ?? const [];
    final results = <Map<String, String>>[];
    for (final r in raw) {
      if (r is! Map) continue;
      results.add({
        'title': r['title'] as String? ?? '',
        'url': r['url'] as String? ?? '',
        'snippet': r['content'] as String? ?? '',
      });
    }

    return {
      'query': query,
      'backend': 'tavily',
      'results': results,
    };
  }
}
