import 'dart:convert';

import 'package:flutter/material.dart';

import '../../notification_service.dart';
import '../tool_registry.dart';

/// Schedule a local-notification reminder at a given time.
/// Works without external apps and without extra permissions beyond
/// the notification permission already requested at app startup.
class SetReminderTool extends Tool {
  @override
  String get name => 'set_reminder';

  @override
  String get displayName => 'Set Reminder';

  @override
  String get statusLabel => 'Setting reminder…';

  @override
  String get description =>
      'Schedule a local notification reminder that fires at a specific '
      'time. Use this when the user asks to "remind me to X at Y", '
      '"提醒我 X 点做 Y", "设置提醒", or similar. The reminder is local '
      'to this device.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'text': {
            'type': 'string',
            'description':
                'What to remind the user about. Short and imperative, e.g. '
                    '"Drink water", "开会".',
          },
          'when_iso': {
            'type': 'string',
            'description':
                'Absolute time in ISO-8601 format with timezone offset, e.g. '
                    '"2025-04-13T15:30:00+08:00". Compute this from the user '
                    'request before calling the tool — do NOT pass relative '
                    'phrases like "in 10 minutes".',
          },
        },
        'required': ['text', 'when_iso'],
      };

  @override
  IconData get icon => Icons.alarm_outlined;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    final text = (args['text'] as String?)?.trim() ?? '';
    final whenIso = (args['when_iso'] as String?)?.trim() ?? '';
    if (text.isEmpty || whenIso.isEmpty) {
      return jsonEncode({'error': 'text and when_iso are required'});
    }
    final when = DateTime.tryParse(whenIso);
    if (when == null) {
      return jsonEncode({'error': 'when_iso is not a valid ISO-8601 datetime'});
    }
    if (when.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      return jsonEncode({'error': 'when_iso is in the past'});
    }

    try {
      await NotificationService.requestPermission();
      final id = await NotificationService.scheduleOneOff(
        title: 'Reminder',
        body: text,
        when: when,
      );
      return jsonEncode({
        'scheduled': true,
        'id': id,
        'text': text,
        'fires_at': when.toIso8601String(),
      });
    } catch (e) {
      return jsonEncode({'error': 'Failed to schedule: $e'});
    }
  }
}
