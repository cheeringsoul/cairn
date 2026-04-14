import 'dart:convert';

import '../../db/database.dart';

/// List-shape record: `{id, title, tags, created_at}`.
/// Intentionally excludes `body` — list endpoints stay cheap so the
/// model can call several in parallel. Full body comes from
/// `get_note_detail`.
Map<String, dynamic> listItemMap(SavedItem it) => {
      'id': it.id,
      'title': it.title,
      'tags': decodeTags(it.tags),
      'created_at': it.createdAt.toIso8601String(),
    };

List<String> decodeTags(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final v = jsonDecode(raw);
    if (v is List) return v.whereType<String>().toList();
  } catch (_) {}
  return const [];
}

String missingDbError(String toolName) => jsonEncode({
      'error':
          '$toolName is unavailable because the library database is not wired '
              'into the tool registry in this context.',
    });
