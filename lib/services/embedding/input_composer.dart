import '../constants.dart';
import '../db/database.dart';

/// Composes the text fed to the embedding model for a [SavedItem].
///
/// Extracted from [EmbeddingFanoutQueue] so it can be reused by
/// future reindex tooling and unit-tested independently.
class EmbeddingInputComposer {
  EmbeddingInputComposer._();

  /// Stacks the most semantically dense fields first (title, entity,
  /// summary) so truncation at the tail hurts recall least.
  static String compose(SavedItem item) {
    final buf = StringBuffer();
    buf.writeln(item.title);
    if (item.entity != null && item.entity!.isNotEmpty) {
      buf.writeln('Entity: ${item.entity}');
    }
    if (item.summary != null && item.summary!.isNotEmpty) {
      buf.writeln('Summary: ${item.summary}');
    }
    buf.writeln();
    buf.write(item.body);

    final text = buf.toString();
    return text.length > EmbeddingLimits.inputMaxChars
        ? text.substring(0, EmbeddingLimits.inputMaxChars)
        : text;
  }
}
