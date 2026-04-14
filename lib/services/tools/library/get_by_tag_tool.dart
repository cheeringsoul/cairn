import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../tool_registry.dart';
import 'library_tool_support.dart';

/// Notes carrying a given tag. The [tag] argument MUST be one returned
/// by `get_tag_distribution` — passing guessed tags produces empty
/// results and wastes a round trip.
class GetByTagTool extends Tool {
  final AppDatabase? _db;
  GetByTagTool(this._db);

  @override
  String get name => 'get_by_tag';

  @override
  String get displayName => 'Library: By Tag';

  @override
  String get statusLabel => 'Fetching notes by tag…';

  @override
  String get description =>
      'List library notes carrying a specific tag, newest first. '
      'Returns title + tags only (no body). The tag argument must be '
      'a real tag from get_tag_distribution — never invent tag names, '
      'the library uses automatically assigned tags that may differ '
      'from natural-language phrasing.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'tag': {'type': 'string'},
          'limit': {'type': 'integer', 'description': 'Default 20.'},
        },
        'required': ['tag'],
      };

  @override
  IconData get icon => Icons.label_outline;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final db = _db;
    if (db == null) return missingDbError(name);
    final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    final tag = (args['tag'] as String?)?.trim() ?? '';
    final limit = (args['limit'] as int?) ?? 20;
    if (tag.isEmpty) {
      return jsonEncode({'error': 'tag is required'});
    }

    final idRows = await db.customSelect(
      'SELECT t.item_id AS id FROM item_tags t '
      'JOIN saved_items s ON s.id = t.item_id '
      'WHERE s.in_library = 1 AND t.tag = ? '
      'ORDER BY s.created_at DESC LIMIT ?',
      variables: [Variable<String>(tag), Variable<int>(limit)],
      readsFrom: {db.savedItems, db.itemTags},
    ).get();
    final ids = idRows.map((r) => r.read<String>('id')).toList();
    if (ids.isEmpty) {
      return jsonEncode({'tag': tag, 'items': const []});
    }
    final items = await (db.select(db.savedItems)
          ..where((i) => i.id.isIn(ids))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .get();
    return jsonEncode({
      'tag': tag,
      'items': items.map(listItemMap).toList(),
    });
  }
}
