import 'package:http/http.dart' as http;

/// Extracts title and body text from a URL by fetching HTML and
/// stripping tags. Simple regex-based extraction — no full DOM parser.
class UrlExtractor {
  static const _fetchTimeoutSeconds = 15;
  static const _maxBodyChars = 5000;

  /// Fetch a URL and extract readable text content.
  /// Returns (title, body) or throws on failure.
  static Future<(String title, String body)> extract(String url) async {
    final uri = Uri.parse(url);
    final response = await http.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0 (compatible; CairnBot/1.0)',
    }).timeout(const Duration(seconds: _fetchTimeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch URL (${response.statusCode})');
    }

    final html = response.body;
    final title = _extractTitle(html);
    final body = _extractBody(html);

    if (body.trim().isEmpty) {
      throw Exception('Could not extract text from this page');
    }

    return (title, body);
  }

  static String _extractTitle(String html) {
    final m = RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false, dotAll: true)
        .firstMatch(html);
    if (m == null) return 'Untitled';
    return _decodeEntities(m.group(1)!.trim());
  }

  static String _extractBody(String html) {
    var text = html;

    // Remove script and style blocks.
    text = text.replaceAll(
        RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '');
    text = text.replaceAll(
        RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), '');
    text = text.replaceAll(
        RegExp(r'<nav[^>]*>.*?</nav>', caseSensitive: false, dotAll: true), '');
    text = text.replaceAll(
        RegExp(r'<header[^>]*>.*?</header>', caseSensitive: false, dotAll: true), '');
    text = text.replaceAll(
        RegExp(r'<footer[^>]*>.*?</footer>', caseSensitive: false, dotAll: true), '');

    // Try to extract <article> or <main> content first.
    final article = RegExp(
            r'<(?:article|main)[^>]*>(.*?)</(?:article|main)>',
            caseSensitive: false,
            dotAll: true)
        .firstMatch(text);
    if (article != null) {
      text = article.group(1)!;
    }

    // Convert block elements to newlines.
    text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    text = text.replaceAll(RegExp(r'</(p|div|li|h[1-6]|tr|blockquote)>',
        caseSensitive: false), '\n');

    // Strip remaining tags.
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');

    // Decode HTML entities.
    text = _decodeEntities(text);

    // Collapse whitespace.
    text = text
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((l) => l.isNotEmpty)
        .join('\n');

    if (text.length > _maxBodyChars) {
      text = '${text.substring(0, _maxBodyChars)}\n\n[Truncated]';
    }

    return text;
  }

  static String _decodeEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1)!);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    });
  }
}
