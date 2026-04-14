import 'dart:convert';

import 'package:flutter/material.dart';

import '../tool_registry.dart';

/// Build tap-to-open search links for common consumer apps (Taobao,
/// JD, Xiaohongshu, Bilibili, Douyin, NetEase Music). Returns
/// candidate URLs; the UI renders them as buttons after the assistant
/// reply — nothing launches automatically.
class AppSearchTool extends Tool {
  @override
  String get name => 'app_search';

  @override
  String get displayName => 'Search in App';

  @override
  String get statusLabel => 'Preparing app search links…';

  @override
  String get description =>
      'Generate tap-to-open search links for consumer apps (Taobao/淘宝, '
      'JD/京东, Xiaohongshu/小红书, Bilibili/B站, Douyin/抖音, NetEase '
      'Music/网易云). Use when the user wants to buy something, find '
      'reviews/notes, watch videos, or search music. Pick the most '
      'relevant app(s) for the intent. Does NOT launch anything — '
      'returns links rendered as buttons after your text reply.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'intent': {
            'type': 'string',
            'enum': ['shopping', 'notes', 'video', 'music'],
            'description':
                '"shopping"=Taobao+JD, "notes"=Xiaohongshu, "video"=Bilibili+Douyin, "music"=NetEase Music.',
          },
          'keyword': {
            'type': 'string',
            'description': 'Search keyword (product name, topic, song, etc.).',
          },
        },
        'required': ['intent', 'keyword'],
      };

  @override
  IconData get icon => Icons.apps_outlined;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    final intent = (args['intent'] as String?) ?? '';
    final keyword = (args['keyword'] as String?)?.trim() ?? '';
    if (keyword.isEmpty) {
      return jsonEncode({'error': 'keyword is required'});
    }
    final enc = Uri.encodeQueryComponent(keyword);

    final links = switch (intent) {
      'shopping' => [
          {
            'label': '在淘宝搜索 "$keyword"',
            'url': 'taobao://s.taobao.com/search?q=$enc',
          },
          {
            'label': '在京东搜索',
            'url': 'openapp.jdmobile://virtual?params='
                '${Uri.encodeQueryComponent(jsonEncode({
              'category': 'jump',
              'des': 'productList',
              'keyWord': keyword,
            }))}',
          },
          {
            'label': '在淘宝网页搜索',
            'url': 'https://s.taobao.com/search?q=$enc',
          },
        ],
      'notes' => [
          {
            'label': '在小红书搜索 "$keyword"',
            'url': 'xhsdiscover://search/result?keyword=$enc',
          },
          {
            'label': '在小红书网页搜索',
            'url': 'https://www.xiaohongshu.com/search_result?keyword=$enc',
          },
        ],
      'video' => [
          {
            'label': '在B站搜索 "$keyword"',
            'url': 'bilibili://search?keyword=$enc',
          },
          {
            'label': '在抖音搜索',
            'url': 'snssdk1128://search?keyword=$enc',
          },
          {
            'label': '在B站网页搜索',
            'url': 'https://search.bilibili.com/all?keyword=$enc',
          },
        ],
      'music' => [
          {
            'label': '在网易云音乐搜索 "$keyword"',
            'url': 'orpheus://search/$enc',
          },
          {
            'label': '在QQ音乐搜索',
            'url': 'qqmusic://qq.com/search?key=$enc',
          },
        ],
      _ => <Map<String, String>>[],
    };

    if (links.isEmpty) {
      return jsonEncode({'error': 'unsupported intent: $intent'});
    }

    return jsonEncode({
      'intent': intent,
      'keyword': keyword,
      'action_links': links,
    });
  }
}
