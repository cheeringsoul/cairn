import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../tool_registry.dart';
import 'library_tool_support.dart';

/// Returns the set of tags that actually exist in the user's Library,
/// with frequency and last-used timestamp. Call this before
/// `get_by_tag` so you filter on real tags instead of guessing
/// keywords the user never used.
class GetTagDistributionTool extends Tool {
  final AppDatabase? _db;
  GetTagDistributionTool(this._db);

  @override
  String get name => 'get_tag_distribution';

  @override
  String get displayName => 'Library: Tag Distribution';

  @override
  String get statusLabel => 'Reading tag distribution…';

  @override
  String get description =>
      'List every tag that appears in the library with its frequency '
      'and most recent use, sorted by count descending. Use the '
      'results as the authoritative vocabulary before calling '
      'get_by_tag — do not invent tag names.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'limit': {
            'type': 'integer',
            'description': 'Max number of tags to return. Default 50.',
          },
        },
        'required': [],
      };

  @override
  IconData get icon => Icons.sell_outlined;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final db = _db;
    if (db == null) return missingDbError(name);
    final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    final limit = (args['limit'] as int?) ?? 50;

    final rows = await db.customSelect(
      'SELECT t.tag AS tag, COUNT(*) AS count, '
      'MAX(s.created_at) AS last_used '
      'FROM item_tags t JOIN saved_items s ON t.item_id = s.id '
      'WHERE s.in_library = 1 '
      'GROUP BY t.tag '
      'ORDER BY count DESC, last_used DESC '
      'LIMIT ?',
      variables: [Variable<int>(limit)],
    ).get();

    final tags = rows.map((r) {
      final lastUsedSec = r.readNullable<int>('last_used');
      return {
        'tag': r.read<String>('tag'),
        'count': r.read<int>('count'),
        'last_used_at': lastUsedSec == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(lastUsedSec * 1000)
                .toIso8601String(),
      };
    }).toList();

    return jsonEncode({'tags': tags});
  }
}
