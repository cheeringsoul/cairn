import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../tool_registry.dart';
import 'library_tool_support.dart';

/// Most recent library notes, reverse chronological. Returns only
/// `{id, title, tags, created_at}` — fetch the full body with
/// `get_note_detail` when needed.
class GetRecentTool extends Tool {
  final AppDatabase? _db;
  GetRecentTool(this._db);

  @override
  String get name => 'get_recent';

  @override
  String get displayName => 'Library: Recent Notes';

  @override
  String get statusLabel => 'Reading recent notes…';

  @override
  String get description =>
      'List the most recent library notes in reverse chronological '
      'order. Returns title + tags only (no body). Best for questions '
      "about what the user has been thinking about lately. Call "
      'get_note_detail(id) to read the full body of any entry.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'limit': {'type': 'integer', 'description': 'Default 20.'},
          'offset': {'type': 'integer', 'description': 'Default 0.'},
        },
        'required': [],
      };

  @override
  IconData get icon => Icons.history_outlined;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final db = _db;
    if (db == null) return missingDbError(name);
    final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    final limit = (args['limit'] as int?) ?? 20;
    final offset = (args['offset'] as int?) ?? 0;

    final items = await (db.select(db.savedItems)
          ..where((i) => i.inLibrary.equals(true))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)])
          ..limit(limit, offset: offset))
        .get();

    return jsonEncode({'items': items.map(listItemMap).toList()});
  }
}
