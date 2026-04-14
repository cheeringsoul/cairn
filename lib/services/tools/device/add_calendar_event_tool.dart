import 'dart:convert';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../tool_registry.dart';

/// Add an event to the device's default calendar. Unlike the deep-link
/// tools, this completes in-app (no app switch) — the event lands
/// directly in the user's calendar.
class AddCalendarEventTool extends Tool {
  @override
  String get name => 'add_calendar_event';

  @override
  String get displayName => 'Add to Calendar';

  @override
  String get statusLabel => 'Adding to calendar…';

  @override
  String get description =>
      'Add an event to the device calendar. Use when the user asks to '
      '"记一下", "安排", "加到日历", "add to calendar", "schedule a meeting". '
      'Requires a title and start time (ISO-8601 with timezone offset, '
      'e.g. "2026-04-14T15:00:00+08:00"). Duration defaults to 60 min. '
      'Completes in-app — no need for action_links.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description': 'Event title, e.g. "Team standup".',
          },
          'start_iso': {
            'type': 'string',
            'description':
                'Start time in ISO-8601 with timezone offset, e.g. "2026-04-14T15:00:00+08:00".',
          },
          'duration_minutes': {
            'type': 'integer',
            'description': 'Event length in minutes. Defaults to 60.',
          },
          'location': {
            'type': 'string',
            'description': 'Optional location (address or place name).',
          },
          'notes': {
            'type': 'string',
            'description': 'Optional notes / description.',
          },
        },
        'required': ['title', 'start_iso'],
      };

  @override
  IconData get icon => Icons.event_outlined;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    final title = (args['title'] as String?)?.trim() ?? '';
    final startIso = (args['start_iso'] as String?)?.trim() ?? '';
    final durationMin = (args['duration_minutes'] as num?)?.toInt() ?? 60;
    final location = (args['location'] as String?)?.trim();
    final notes = (args['notes'] as String?)?.trim();

    if (title.isEmpty || startIso.isEmpty) {
      return jsonEncode({'error': 'title and start_iso are required'});
    }

    final start = DateTime.tryParse(startIso);
    if (start == null) {
      return jsonEncode({'error': 'invalid start_iso: $startIso'});
    }
    final end = start.add(Duration(minutes: durationMin));

    final plugin = DeviceCalendarPlugin();
    final permResult = await plugin.hasPermissions();
    if (permResult.data != true) {
      final req = await plugin.requestPermissions();
      if (req.data != true) {
        return jsonEncode({'error': 'calendar permission denied'});
      }
    }

    final calsResult = await plugin.retrieveCalendars();
    final cals = calsResult.data;
    if (cals == null || cals.isEmpty) {
      return jsonEncode({'error': 'no calendars available on device'});
    }
    final target = cals.firstWhere(
      (c) => c.isDefault == true && c.isReadOnly != true,
      orElse: () => cals.firstWhere(
        (c) => c.isReadOnly != true,
        orElse: () => cals.first,
      ),
    );

    final location0 = tz.local;
    final event = Event(
      target.id,
      title: title,
      start: tz.TZDateTime.from(start, location0),
      end: tz.TZDateTime.from(end, location0),
      description: (notes?.isNotEmpty ?? false) ? notes : null,
    );
    if (location?.isNotEmpty ?? false) event.location = location;

    final res = await plugin.createOrUpdateEvent(event);
    if (res?.isSuccess != true) {
      final msg = res?.errors.map((e) => e.errorMessage).join('; ') ??
          'unknown error';
      return jsonEncode({'error': 'failed to add event: $msg'});
    }

    return jsonEncode({
      'ok': true,
      'title': title,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'calendar': target.name,
    });
  }
}
