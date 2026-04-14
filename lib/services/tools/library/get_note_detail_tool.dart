import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../tool_registry.dart';
import 'library_tool_support.dart';

/// Full note — title, body, user notes, tags, summary. Only call this
/// when a list-style endpoint's title + tags were not enough.
class GetNoteDetailTool extends Tool {
  final AppDatabase? _db;
  GetNoteDetailTool(this._db);

  @override
  String get name => 'get_note_detail';

  @override
  String get displayName => 'Library: Note Detail';

  @override
  String get statusLabel => 'Reading note…';

  @override
  String get description =>
      'Fetch the full contents of a specific note by id, including '
      'body and summary. Use only when the title + tags returned by '
      'list endpoints are insufficient — body text is expensive to '
      'include for every note, so prefer list endpoints first.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
        },
        'required': ['id'],
      };

  @override
  IconData get icon => Icons.article_outlined;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final db = _db;
    if (db == null) return missingDbError(name);
    final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    final id = (args['id'] as String?)?.trim() ?? '';
    if (id.isEmpty) return jsonEncode({'error': 'id is required'});

    final row = await (db.select(db.savedItems)
          ..where((i) => i.id.equals(id) & i.inLibrary.equals(true)))
        .getSingleOrNull();
    if (row == null) {
      return jsonEncode({'error': 'not found', 'id': id});
    }
    return jsonEncode({
      'id': row.id,
      'title': row.title,
      'body': row.body,
      'user_notes': row.userNotes,
      'summary': row.summary,
      'tags': decodeTags(row.tags),
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    });
  }
}
