// lib/services/title_deriver.dart

import 'constants.dart';

class TitleDeriver {
  TitleDeriver._();

  /// Collapse whitespace, truncate at [maxLength], append ellipsis.
  static String truncate(String s, {required int maxLength}) {
    final clean = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= maxLength) return clean;
    return '${clean.substring(0, maxLength)}…';
  }

  /// Derive a saved-item title when no AI-generated title is
  /// available. Prefers the preceding user question; falls back to
  /// the first sentence of the body; finally to [emptyFallback].
  static String fromChatContext({
    String? precedingUserQuestion,
    String? body,
    required String emptyFallback,
  }) {
    final q = precedingUserQuestion?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    if (q.isNotEmpty) {
      return truncate(q, maxLength: TitleLimits.fallback);
    }
    if (body != null && body.trim().isNotEmpty) {
      return firstSentence(body, fallback: emptyFallback);
    }
    return emptyFallback;
  }

  /// Extract the first sentence from markdown body, stripping common
  /// prefixes (heading / list markers / emphasis).
  static String firstSentence(String body, {required String fallback}) {
    final lines = body.split('\n');
    String first = '';
    for (final raw in lines) {
      final line = raw
          .replaceAll(RegExp(r'^\s*#+\s*'), '')
          .replaceAll(RegExp(r'^\s*[-*+]\s+'), '')
          .replaceAll(RegExp(r'^\s*\d+\.\s+'), '')
          .replaceAll(RegExp(r'[*_`]'), '')
          .trim();
      if (line.isNotEmpty) {
        first = line;
        break;
      }
    }
    if (first.isEmpty) return fallback;
    final m = RegExp(r'^(.+?[.!?。！？])').firstMatch(first);
    var sentence = m != null ? m.group(1)! : first;
    if (sentence.length > TitleLimits.fallback) {
      sentence = '${sentence.substring(0, TitleLimits.fallback)}…';
    }
    return sentence;
  }
}
