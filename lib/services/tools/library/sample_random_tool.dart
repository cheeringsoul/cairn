import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../tool_registry.dart';
import 'library_tool_support.dart';

/// Random sample across the full library — use for global "who is this
/// user" style questions where a recency-biased view would be
/// misleading.
class SampleRandomTool extends Tool {
  final AppDatabase? _db;
  SampleRandomTool(this._db);

  @override
  String get name => 'sample_random';

  @override
  String get displayName => 'Library: Random Sample';

  @override
  String get statusLabel => 'Sampling library…';

  @override
  String get description =>
      'Sample notes uniformly at random from the whole library. Use '
      'when the user asks global profile questions ("what kind of '
      'person am I", "summarize my interests") — a recency-only view '
      'would miss older but defining notes.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'limit': {'type': 'integer', 'description': 'Default 20.'},
        },
        'required': [],
      };

  @override
  IconData get icon => Icons.shuffle_outlined;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final db = _db;
    if (db == null) return missingDbError(name);
    final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    final limit = (args['limit'] as int?) ?? 20;

    final idRows = await db.customSelect(
      'SELECT id FROM saved_items WHERE in_library = 1 '
      'ORDER BY RANDOM() LIMIT ?',
      variables: [Variable<int>(limit)],
      readsFrom: {db.savedItems},
    ).get();
    final ids = idRows.map((r) => r.read<String>('id')).toList();
    if (ids.isEmpty) {
      return jsonEncode({'items': const []});
    }
    final items = await (db.select(db.savedItems)
          ..where((i) => i.id.isIn(ids)))
        .get();
    return jsonEncode({'items': items.map(listItemMap).toList()});
  }
}
