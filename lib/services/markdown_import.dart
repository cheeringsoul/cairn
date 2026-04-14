import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'constants.dart';
import 'db/database.dart';
import 'library_provider.dart';
import 'title_deriver.dart';

/// Minimal markdown importer: one picked .md file → one SavedItem in
/// the Notes folder.
///
/// Title derivation:
///   1. First `# H1` line, if any
///   2. Otherwise first non-empty line (trimmed, capped at 80 chars)
///   3. Otherwise the file name without extension
///
/// The matched title line is stripped from the body so we don't
/// duplicate it. Everything else is stored verbatim.
class MarkdownImport {
  final LibraryProvider library;
  MarkdownImport(this.library);

  /// Prompts the user to pick one or more .md files and imports each
  /// as a SavedItem in Notes. Returns the created items.
  Future<List<SavedItem>> pickAndImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown', 'txt'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return const [];

    final imported = <SavedItem>[];
    for (final f in result.files) {
      final content = await _readContent(f);
      if (content == null || content.trim().isEmpty) continue;
      final parsed = _parse(content, fallbackName: f.name);
      final item = await library.saveItem(
        title: TitleDeriver.truncate(parsed.title, maxLength: TitleLimits.fallback),
        body: parsed.body,
        metaStatus: MetaStatus.pending,
      );
      imported.add(item);
    }
    return imported;
  }

  Future<String?> _readContent(PlatformFile f) async {
    if (f.bytes != null) return utf8.decode(f.bytes!, allowMalformed: true);
    if (f.path != null) return File(f.path!).readAsString();
    return null;
  }

  _Parsed _parse(String raw, {required String fallbackName}) {
    final lines = raw.split('\n');

    // Look for the first H1.
    for (var i = 0; i < lines.length; i++) {
      final m = RegExp(r'^\s*#\s+(.+?)\s*$').firstMatch(lines[i]);
      if (m != null) {
        final title = m.group(1)!.trim();
        final body = [...lines.take(i), ...lines.skip(i + 1)]
            .join('\n')
            .trim();
        return _Parsed(title, body);
      }
    }

    // Fall back to the first non-empty line.
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final title = line.length > 80 ? '${line.substring(0, 80)}…' : line;
      final body =
          [...lines.take(i), ...lines.skip(i + 1)].join('\n').trim();
      return _Parsed(title, body);
    }

    // Empty-ish file — use the file name.
    return _Parsed(_stripExt(fallbackName), raw);
  }

  String _stripExt(String name) {
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? name : name.substring(0, dot);
  }
}

class _Parsed {
  final String title;
  final String body;
  _Parsed(this.title, this.body);
}
