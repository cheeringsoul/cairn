import 'dart:convert';

import 'package:flutter/material.dart';

import '../tool_registry.dart';

/// Build a set of map deep-links for a destination. Returns candidate
/// URLs; the UI renders them as tap-to-open buttons at the end of the
/// assistant reply — nothing is launched automatically.
class OpenMapsTool extends Tool {
  @override
  String get name => 'open_maps';

  @override
  String get displayName => 'Open Maps';

  @override
  String get statusLabel => 'Preparing map link…';

  @override
  String get description =>
      'Generate tap-to-open map links (Amap / Baidu / Apple Maps) for a '
      'place. Use this when the user asks "how do I get to X", "怎么去 '
      'X", or wants directions. Does NOT launch anything — returns '
      'links that are rendered as buttons after your text reply.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'destination': {
            'type': 'string',
            'description': 'Place name or address to navigate to.',
          },
          'mode': {
            'type': 'string',
            'enum': ['navigate', 'search'],
            'description':
                '"navigate" for turn-by-turn directions, "search" to just '
                    'show the place on the map. Defaults to "navigate".',
          },
        },
        'required': ['destination'],
      };

  @override
  IconData get icon => Icons.map_outlined;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    final dest = (args['destination'] as String?)?.trim() ?? '';
    final mode = (args['mode'] as String?) ?? 'navigate';
    if (dest.isEmpty) return jsonEncode({'error': 'destination is required'});

    final enc = Uri.encodeQueryComponent(dest);
    final links = mode == 'navigate'
        ? [
            {
              'label': '用高德导航',
              'url':
                  'iosamap://path?sourceApplication=cairn&dname=$enc&dev=0&t=0',
            },
            {
              'label': '用百度地图导航',
              'url':
                  'baidumap://map/direction?destination=$enc&mode=driving&coord_type=bd09ll&src=cairn',
            },
            {
              'label': '用苹果地图导航',
              'url': 'http://maps.apple.com/?daddr=$enc',
            },
          ]
        : [
            {
              'label': '在高德查看',
              'url':
                  'iosamap://poi?sourceApplication=cairn&keywords=$enc&dev=0',
            },
            {
              'label': '在百度地图查看',
              'url': 'baidumap://map/place/search?query=$enc&src=cairn',
            },
            {
              'label': '在苹果地图查看',
              'url': 'http://maps.apple.com/?q=$enc',
            },
          ];

    return jsonEncode({
      'destination': dest,
      'mode': mode,
      'action_links': links,
    });
  }
}
