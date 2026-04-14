import 'dart:convert';

import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../tool_registry.dart';
import 'library_tool_support.dart';

/// Returns high-level stats about the user's Library — used by the
/// model as a first-pass probe before deciding what to look at in
/// detail.
class GetStatsTool extends Tool {
  final AppDatabase? _db;
  GetStatsTool(this._db);

  @override
  String get name => 'get_stats';

  @override
  String get displayName => 'Library: Stats';

  @override
  String get statusLabel => 'Reading library stats…';

  @override
  String get description =>
      "Get an overview of the user's note library: total notes, date "
      'range, weekly average, and number of active days. Call this '
      'first when you need to reason about who the user is or what '
      'they focus on — it gives a baseline before drilling in.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {},
        'required': [],
      };

  @override
  IconData get icon => Icons.insights_outlined;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final db = _db;
    if (db == null) return missingDbError(name);

    final totalRow = await db.customSelect(
      'SELECT COUNT(*) AS c, MIN(created_at) AS first_at, '
      'MAX(created_at) AS last_at '
      'FROM saved_items WHERE in_library = 1',
    ).getSingle();
    final total = totalRow.read<int>('c');
    if (total == 0) {
      return jsonEncode({
        'total_notes': 0,
        'date_range': null,
        'notes_per_week_avg': 0,
        'active_days': 0,
      });
    }
    final firstMs = totalRow.readNullable<int>('first_at');
    final lastMs = totalRow.readNullable<int>('last_at');
    final first = firstMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(firstMs * 1000);
    final last = lastMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastMs * 1000);

    final daysRow = await db.customSelect(
      "SELECT COUNT(DISTINCT date(created_at, 'unixepoch')) AS d "
      'FROM saved_items WHERE in_library = 1',
    ).getSingle();
    final activeDays = daysRow.read<int>('d');

    double perWeek = 0;
    if (first != null && last != null) {
      final span = last.difference(first).inDays + 1;
      perWeek = total / (span / 7.0);
    }

    return jsonEncode({
      'total_notes': total,
      'date_range': first == null || last == null
          ? null
          : {
              'first': first.toIso8601String(),
              'last': last.toIso8601String(),
            },
      'notes_per_week_avg': double.parse(perWeek.toStringAsFixed(2)),
      'active_days': activeDays,
    });
  }
}
