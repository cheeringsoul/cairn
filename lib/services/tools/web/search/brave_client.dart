import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin client for Brave Search API's `/res/v1/web/search` endpoint.
/// Brave operates its own independent index (not a Google/Bing
/// scraper), so it's the most resilient option when a SERP-style
/// backend is needed. Results are snippet-only; callers that need
/// full article bodies should fetch separately.
///
/// Docs: https://api.search.brave.com/app/documentation/web-search/get-started
class BraveClient {
  static const _endpoint = 'https://api.search.brave.com/res/v1/web/search';

  static Future<Map<String, dynamic>> search({
    required String apiKey,
    required String query,
    int maxResults = 5,
  }) async {
    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'q': query,
      'count': '$maxResults',
    });

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'X-Subscription-Token': apiKey,
    }).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
          'Brave ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final web = decoded['web'] as Map<String, dynamic>? ?? const {};
    final raw = (web['results'] as List?) ?? const [];
    final results = <Map<String, String>>[];
    for (final r in raw) {
      if (r is! Map) continue;
      results.add({
        'title': r['title'] as String? ?? '',
        'url': r['url'] as String? ?? '',
        'snippet': r['description'] as String? ?? '',
      });
    }

    return {
      'query': query,
      'backend': 'brave',
      'results': results,
    };
  }
}
