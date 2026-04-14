import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../tool_registry.dart';
import 'library_tool_support.dart';

/// Compares per-tag frequency in the most recent [days]-day window
/// against the prior equal-length window — useful for detecting
/// interest shifts ("what has the user been into lately vs. before").
class GetTagTrendTool extends Tool {
  final AppDatabase? _db;
  GetTagTrendTool(this._db);

  @override
  String get name => 'get_tag_trend';

  @override
  String get displayName => 'Library: Tag Trend';

  @override
  String get statusLabel => 'Comparing recent tags…';

  @override
  String get description =>
      'Compare tag frequency in the last N days against the previous '
      'N days and return the delta per tag. Use to detect shifting '
      'interests — which topics are rising or fading in the library.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'days': {
            'type': 'integer',
            'description':
                'Length in days of the recent window (and of the prior '
                    'window it is compared against). Default 30.',
          },
        },
        'required': [],
      };

  @override
  IconData get icon => Icons.trending_up_outlined;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final db = _db;
    if (db == null) return missingDbError(name);
    final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    final days = (args['days'] as int?) ?? 30;

    final now = DateTime.now();
    final recentStart = now.subtract(Duration(days: days));
    final priorStart = now.subtract(Duration(days: days * 2));
    int secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

    final rows = await db.customSelect(
      'SELECT t.tag AS tag, '
      'SUM(CASE WHEN s.created_at >= ? THEN 1 ELSE 0 END) AS recent, '
      'SUM(CASE WHEN s.created_at >= ? AND s.created_at < ? THEN 1 ELSE 0 END) AS prior '
      'FROM item_tags t JOIN saved_items s ON t.item_id = s.id '
      'WHERE s.in_library = 1 AND s.created_at >= ? '
      'GROUP BY t.tag '
      'HAVING recent > 0 OR prior > 0 '
      'ORDER BY (recent - prior) DESC',
      variables: [
        Variable<int>(secs(recentStart)),
        Variable<int>(secs(priorStart)),
        Variable<int>(secs(recentStart)),
        Variable<int>(secs(priorStart)),
      ],
    ).get();

    final tags = rows.map((r) {
      final recent = r.read<int>('recent');
      final prior = r.read<int>('prior');
      return {
        'tag': r.read<String>('tag'),
        'count_recent': recent,
        'count_prior': prior,
        'delta': recent - prior,
      };
    }).toList();

    return jsonEncode({
      'window_days': days,
      'recent_window_start': recentStart.toIso8601String(),
      'prior_window_start': priorStart.toIso8601String(),
      'tags': tags,
    });
  }
}
