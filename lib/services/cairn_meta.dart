import 'dart:convert';

/// Structured sidecar metadata the model appends to an assistant reply
/// in a fenced ```cairn-meta``` block. See docs/KNOWLEDGE-GRAPH.md.
///
/// All fields are optional — some older saved items won't have them,
/// and on conversational replies the model is instructed to omit the
/// block entirely.
class CairnMeta {
  final String? type; // open-ended: vocab, insight, concept, recipe, …
  final String? entity; // canonical subject: the word, concept, or topic
  final List<String> tags;
  final String? summary;
  final bool? reviewable; // AI judgment: worth memorizing via spaced repetition?
  final String? title; // AI-generated concise title for the knowledge unit

  const CairnMeta({
    this.type,
    this.entity,
    this.tags = const [],
    this.summary,
    this.reviewable,
    this.title,
  });

  bool get isEmpty =>
      (type == null || type!.isEmpty) &&
      (entity == null || entity!.isEmpty) &&
      tags.isEmpty &&
      (summary == null || summary!.isEmpty) &&
      (title == null || title!.isEmpty);

  /// JSON encoding used for the `saved_items.tags` TEXT column.
  String encodeTags() => jsonEncode(tags);

  /// Decode a tag list previously stored via [encodeTags]. Returns an
  /// empty list on null / malformed input.
  static List<String> decodeTags(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return const [];
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return const [];
  }
}

// Matches a fully-formed trailing cairn-meta block. Used at save time
// when we have the complete assistant reply.
final _parseRe = RegExp(
  r'```cairn-meta\s*\n([\s\S]*?)\n?```\s*$',
);

// Matches the opening fence and everything after. Used at render time
// so the block is hidden as soon as the model starts emitting it,
// before the closing fence has streamed in.
final _stripRe = RegExp(r'\n*```cairn-meta[\s\S]*$');

// Matches a bare trailing JSON object that looks like cairn-meta
// (contains "type" and "entity" keys). Catches cases where the model
// outputs the metadata without the code fence wrapper.
final _stripBareJsonRe = RegExp(
  r'\n*\{[^{}]*"type"\s*:\s*"[^"]*"[^{}]*"entity"\s*:\s*"[^"]*"[^{}]*\}\s*$',
);

/// Removes any (possibly partial) cairn-meta block from [text] so it
/// isn't shown to the user. Safe on streaming/partial input.
String stripCairnMetaForDisplay(String text) {
  var cleaned = text.replaceFirst(_stripRe, '');
  cleaned = cleaned.replaceFirst(_stripBareJsonRe, '');
  return cleaned.trimRight();
}

/// Result of parsing a fully-streamed reply: [body] is the text with
/// the cairn-meta block removed; [meta] is the parsed metadata or null
/// if the block was absent or malformed.
class ParsedReply {
  final String body;
  final CairnMeta? meta;
  const ParsedReply(this.body, this.meta);
}

/// Extracts a trailing cairn-meta block from a complete assistant
/// reply. Malformed JSON is tolerated — the block is stripped from the
/// body either way so the user never sees the raw fence, but [meta]
/// will be null in that case.
ParsedReply parseCairnMeta(String text) {
  // Try fenced ```cairn-meta``` block first.
  final m = _parseRe.firstMatch(text);
  if (m != null) {
    final body = text.replaceFirst(_parseRe, '').trimRight();
    return _tryParseJson(m.group(1)!.trim(), body);
  }
  // Fallback: try bare trailing JSON with cairn-meta-like keys.
  final bm = _stripBareJsonRe.firstMatch(text);
  if (bm != null) {
    final body = text.replaceFirst(_stripBareJsonRe, '').trimRight();
    return _tryParseJson(bm.group(0)!.trim(), body);
  }
  return ParsedReply(text, null);
}

ParsedReply _tryParseJson(String jsonStr, String body) {
  try {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map) return ParsedReply(body, null);
    final type = (decoded['type'] as Object?)?.toString();
    final entity = (decoded['entity'] as Object?)?.toString();
    final summary = (decoded['summary'] as Object?)?.toString();
    final title = (decoded['title'] as Object?)?.toString();
    final rawReviewable = decoded['reviewable'];
    final reviewable = rawReviewable is bool ? rawReviewable : null;
    final rawTags = decoded['tags'];
    final tags = rawTags is List
        ? rawTags
            .map((e) => e.toString().trim().toLowerCase())
            .where((t) => t.isNotEmpty)
            .toList()
        : const <String>[];
    return ParsedReply(
      body,
      CairnMeta(
        type: type == null || type.isEmpty ? null : type,
        entity: entity == null || entity.isEmpty ? null : entity,
        tags: tags,
        summary: summary == null || summary.isEmpty ? null : summary,
        reviewable: reviewable,
        title: title == null || title.isEmpty ? null : title,
      ),
    );
  } catch (_) {
    return ParsedReply(body, null);
  }
}

/// System-prompt addendum that tells the model to emit a cairn-meta
/// block. Appended to both chat and explain-session system prompts.
const cairnMetaSystemInstruction = '''
If your reply contains a self-contained knowledge unit worth remembering (a word explanation, a concept, a fact, an insight, or an actionable item), append EXACTLY ONE fenced block at the very end of your reply, after all other content:

```cairn-meta
{"type":"...","entity":"...","tags":["..."],"summary":"...","title":"...","reviewable":true}
```

Rules:
- "type" is a short lowercase label that best categorizes this unit. Common examples: vocab, insight, action, fact, question, concept, recipe, reference — but use whatever fits best. Keep it to one word.
- "entity" is the canonical subject — the word, concept, or topic this reply is about (e.g. "compel", "HashMap", "backpressure"). Lowercase, singular form.
- 3-5 lowercase short tags. For vocabulary, include BOTH the source-language keyword AND a cross-language hint (e.g. include both "pellere" and a Chinese or English gloss) so retrieval works across languages.
- "summary" is one sentence, <= 20 words.
- "title": a concise 3-8 word title capturing the core topic of this knowledge unit. Use the same language as the user's question (Chinese if the question is Chinese, English if English). Avoid generic phrases like "介绍" or "的含义" — prefer concrete subject matter. Examples: "React Native FlatList 无限滚动性能优化", "Backpressure in Reactive Streams", "Dart 异步错误处理最佳实践".
- "reviewable" is a boolean. Set to true if this knowledge unit is worth memorizing through spaced repetition (vocabulary, key concepts, important insights). Set to false for reference material, links, technical details that are better looked up than memorized, or trivially simple content.
- Omit the block entirely for conversational / utility replies (small talk, rewriting a sentence, formatting help, clarifying questions).
- The block MUST be the last thing in your reply. Never write anything after it.
''';
