import 'dart:convert';

import 'package:flutter/material.dart';

import '../tool_registry.dart';

/// Build tap-to-open links to ride-hailing apps (Didi, Amap taxi).
/// Returns candidate URLs; the UI renders them as buttons after the
/// assistant reply — nothing launches automatically.
class CallTaxiTool extends Tool {
  @override
  String get name => 'call_taxi';

  @override
  String get displayName => 'Call a Taxi';

  @override
  String get statusLabel => 'Preparing taxi links…';

  @override
  String get description =>
      'Generate tap-to-open links to hail a taxi via Didi / Amap. Use '
      'when the user asks "打车到 X", "call a taxi to X". Destination '
      'required; origin optional (defaults to current location in the '
      'target app). Does NOT launch anything — returns links rendered '
      'as buttons after your text reply.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'destination': {
            'type': 'string',
            'description': 'Drop-off place name or address.',
          },
          'origin': {
            'type': 'string',
            'description':
                'Optional pickup place. Leave empty to use current location.',
          },
        },
        'required': ['destination'],
      };

  @override
  IconData get icon => Icons.local_taxi_outlined;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    final dest = (args['destination'] as String?)?.trim() ?? '';
    final origin = (args['origin'] as String?)?.trim() ?? '';
    if (dest.isEmpty) return jsonEncode({'error': 'destination is required'});

    final destEnc = Uri.encodeQueryComponent(dest);
    final originParam =
        origin.isNotEmpty ? '&fromaddr=${Uri.encodeQueryComponent(origin)}' : '';

    final links = [
      {
        'label': '用滴滴打车到 "$dest"',
        'url': 'diditaxi://router/dache?toaddr=$destEnc$originParam',
      },
      {
        'label': '用高德打车',
        'url': 'iosamap://path?sourceApplication=cairn&dname=$destEnc&dev=0&t=3',
      },
    ];

    return jsonEncode({
      'destination': dest,
      'origin': origin,
      'action_links': links,
    });
  }
}
