import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// Parsed feed metadata.
class ParsedFeed {
  final String title;
  final String? siteUrl;
  final List<ParsedFeedItem> items;

  const ParsedFeed({
    required this.title,
    this.siteUrl,
    required this.items,
  });
}

/// A single item from an RSS/Atom feed.
class ParsedFeedItem {
  final String title;
  final String url;
  final String body;
  final DateTime? publishedAt;

  const ParsedFeedItem({
    required this.title,
    required this.url,
    required this.body,
    this.publishedAt,
  });
}

/// Fetches and parses RSS 2.0 and Atom 1.0 feeds.
class FeedService {
  static Future<ParsedFeed> fetch(String feedUrl) async {
    final uri = Uri.parse(feedUrl);
    final response = await http.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0 (compatible; CairnBot/1.0)',
    }).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch feed (${response.statusCode})');
    }

    final doc = XmlDocument.parse(response.body);
    final root = doc.rootElement;

    if (root.name.local == 'feed') {
      return _parseAtom(root);
    } else if (root.name.local == 'rss') {
      return _parseRss(root);
    } else if (root.name.local == 'RDF') {
      return _parseRss1(root);
    }
    throw Exception('Unknown feed format: ${root.name.local}');
  }

  /// Try to discover an RSS/Atom feed URL from a regular web page.
  static Future<String?> discoverFeedUrl(String pageUrl) async {
    final uri = Uri.parse(pageUrl);
    final response = await http.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0 (compatible; CairnBot/1.0)',
    }).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return null;

    final html = response.body;
    // Look for <link rel="alternate" type="application/rss+xml" href="...">
    final re = RegExp(
      r'''<link[^>]+type=["']application/(rss|atom)\+xml["'][^>]+href=["']([^"']+)["']''',
      caseSensitive: false,
    );
    final match = re.firstMatch(html);
    if (match == null) return null;

    final href = match.group(2)!;
    if (href.startsWith('http')) return href;
    // Resolve relative URL
    return uri.resolve(href).toString();
  }

  // ---- RSS 2.0 ----

  static ParsedFeed _parseRss(XmlElement root) {
    final channel = root.findElements('channel').first;
    final title = _text(channel, 'title') ?? 'Untitled';
    final siteUrl = _text(channel, 'link');
    final items = channel.findElements('item').map((item) {
      return ParsedFeedItem(
        title: _text(item, 'title') ?? '',
        url: _text(item, 'link') ?? '',
        body: _text(item, 'content:encoded') ??
            _text(item, 'description') ??
            '',
        publishedAt: _parseDate(_text(item, 'pubDate')),
      );
    }).toList();

    return ParsedFeed(title: title, siteUrl: siteUrl, items: items);
  }

  // ---- RSS 1.0 (RDF) ----

  static ParsedFeed _parseRss1(XmlElement root) {
    final title = _text(root, 'title') ?? 'Untitled';
    final siteUrl = _text(root, 'link');
    final items = root.findElements('item').map((item) {
      return ParsedFeedItem(
        title: _text(item, 'title') ?? '',
        url: _text(item, 'link') ?? '',
        body: _text(item, 'description') ?? '',
        publishedAt: _parseDate(_text(item, 'dc:date')),
      );
    }).toList();

    return ParsedFeed(title: title, siteUrl: siteUrl, items: items);
  }

  // ---- Atom 1.0 ----

  static ParsedFeed _parseAtom(XmlElement root) {
    final title = _text(root, 'title') ?? 'Untitled';
    final siteLink = root.findElements('link').where((l) {
      final rel = l.getAttribute('rel');
      return rel == null || rel == 'alternate';
    }).firstOrNull;
    final siteUrl = siteLink?.getAttribute('href');

    final items = root.findElements('entry').map((entry) {
      final link = entry.findElements('link').where((l) {
        final rel = l.getAttribute('rel');
        return rel == null || rel == 'alternate';
      }).firstOrNull;

      return ParsedFeedItem(
        title: _text(entry, 'title') ?? '',
        url: link?.getAttribute('href') ?? '',
        body: _text(entry, 'content') ??
            _text(entry, 'summary') ??
            '',
        publishedAt: _parseDate(
            _text(entry, 'published') ?? _text(entry, 'updated')),
      );
    }).toList();

    return ParsedFeed(title: title, siteUrl: siteUrl, items: items);
  }

  // ---- helpers ----

  static String? _text(XmlElement parent, String name) {
    final el = parent.findElements(name).firstOrNull;
    return el?.innerText.trim();
  }

  static DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {}
    // Try RFC 822 format (common in RSS 2.0)
    try {
      return _parseRfc822(s);
    } catch (_) {}
    return null;
  }

  static DateTime _parseRfc822(String s) {
    // "Mon, 01 Jan 2024 12:00:00 GMT"
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final parts = s.replaceAll(',', '').split(RegExp(r'\s+'));
    // Skip day name if present
    final offset = parts[0].length <= 3 && months.containsKey(parts[0])
        ? 0
        : 1;
    final day = int.parse(parts[offset]);
    final month = months[parts[offset + 1]] ?? 1;
    final year = int.parse(parts[offset + 2]);
    final timeParts = parts[offset + 3].split(':');
    return DateTime.utc(
      year,
      month,
      day,
      int.parse(timeParts[0]),
      timeParts.length > 1 ? int.parse(timeParts[1]) : 0,
      timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
    );
  }

  /// Strip HTML tags from feed content to get plain text.
  static String stripHtml(String html) {
    var text = html;
    text = text.replaceAll(
        RegExp(r'<script[^>]*>.*?</script>',
            caseSensitive: false, dotAll: true),
        '');
    text = text.replaceAll(
        RegExp(r'<style[^>]*>.*?</style>',
            caseSensitive: false, dotAll: true),
        '');
    text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    text = text.replaceAll(
        RegExp(r'</(p|div|li|h[1-6])>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&nbsp;', ' ');
    // Collapse whitespace
    text = text
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((l) => l.isNotEmpty)
        .join('\n');
    // Cap at 2000 chars for AI analysis
    if (text.length > 2000) {
      text = '${text.substring(0, 2000)}…';
    }
    return text;
  }
}
