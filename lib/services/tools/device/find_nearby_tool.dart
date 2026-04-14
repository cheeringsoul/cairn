import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../tool_registry.dart';

/// Build tap-to-open links to Meituan / Dianping / Amap for "nearby"
/// queries. Returns candidate URLs; the UI renders them as buttons
/// after the assistant reply — nothing launches automatically.
class FindNearbyTool extends Tool {
  @override
  String get name => 'find_nearby';

  @override
  String get displayName => 'Find Nearby';

  @override
  String get statusLabel => 'Preparing nearby links…';

  @override
  String get description =>
      'Generate tap-to-open links for nearby restaurants, hotels, shops, '
      'attractions (Meituan / Dianping / Amap). Use when the user asks '
      '"附近有什么…", "nearby X", "X 附近有什么吃的", "where to eat/stay around '
      'here". IMPORTANT location handling: if the user names a specific '
      'place/area (e.g. "国贸附近", "near Times Square"), pass it in '
      '`place`. If the user says generic "附近/nearby/here", first call '
      '`current_location` and pass the returned `latitude`/`longitude` '
      'as `lat`/`lng` so the links land at the right spot. Does NOT '
      'launch anything — returns links rendered as buttons after your '
      'text reply.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'category': {
            'type': 'string',
            'enum': ['food', 'hotel', 'attraction', 'shop', 'other'],
            'description':
                'Category of place. "food"=restaurants/美食, "hotel"=酒店, '
                    '"attraction"=景点/fun, "shop"=购物/shopping, "other"=anything else.',
          },
          'keyword': {
            'type': 'string',
            'description':
                'Optional keyword to refine (e.g. "hotpot", "boutique hotel", '
                    '"sushi"). Leave empty for generic nearby browsing.',
          },
          'place': {
            'type': 'string',
            'description':
                'Named place/area the user asked about (e.g. "国贸", "陆家嘴", '
                    '"Times Square"). Folded into the search query so results '
                    'center on that area. Omit for generic "nearby" queries.',
          },
          'lat': {
            'type': 'number',
            'description':
                "User's current latitude. Fill from current_location tool "
                    'when the user asks about "nearby / 附近 / here" without '
                    'naming a place.',
          },
          'lng': {
            'type': 'number',
            'description':
                "User's current longitude. Pair with `lat`.",
          },
        },
        'required': ['category'],
      };

  @override
  IconData get icon => Icons.place_outlined;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    final category = (args['category'] as String?) ?? 'other';
    final keyword = (args['keyword'] as String?)?.trim() ?? '';
    final place = (args['place'] as String?)?.trim() ?? '';
    var lat = (args['lat'] as num?)?.toDouble();
    var lng = (args['lng'] as num?)?.toDouble();

    // Fallback: if the model didn't hand us coords and the user
    // didn't name a place, try to grab GPS ourselves so Amap's
    // around-search actually centers on the user.
    if (lat == null && lng == null && place.isEmpty) {
      final pos = await _tryQuickGps();
      if (pos != null) {
        lat = pos.latitude;
        lng = pos.longitude;
      }
    }

    // Build text query. If a named place is given, fold it in so
    // Meituan/Dianping (which can't take raw coords) still center on
    // the right area.
    final baseKeyword =
        keyword.isNotEmpty ? keyword : _categoryLabel(category);
    final query = place.isNotEmpty ? '$place $baseKeyword' : baseKeyword;
    final enc = Uri.encodeQueryComponent(query);

    final meituanUrl = category == 'hotel'
        ? 'imeituan://www.meituan.com/hotel/list?q=$enc'
        : 'imeituan://www.meituan.com/search?q=$enc';

    // Amap has a dedicated "around" scheme that takes coords; fall
    // back to keyword search when no coords are available.
    final hasCoords = lat != null && lng != null;
    final amapUrl = hasCoords && place.isEmpty
        ? 'iosamap://arroundpoi?sourceApplication=cairn&keywords=$enc'
            '&lat=$lat&lon=$lng&dev=0'
        : 'iosamap://poi?sourceApplication=cairn&keywords=$enc&dev=0';

    final links = [
      {'label': '在美团搜索 "$query"', 'url': meituanUrl},
      {'label': '在大众点评搜索', 'url': 'dianping://searchshoplist?keyword=$enc'},
      {'label': '在高德地图查看', 'url': amapUrl},
      {'label': '在美团网页搜索', 'url': 'https://i.meituan.com/s/$enc'},
    ];

    return jsonEncode({
      'category': category,
      'keyword': keyword,
      'place': place,
      if (hasCoords) 'lat': lat,
      if (hasCoords) 'lng': lng,
      'action_links': links,
    });
  }

  static Future<Position?> _tryQuickGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static String _categoryLabel(String category) {
    switch (category) {
      case 'food':
        return '美食';
      case 'hotel':
        return '酒店';
      case 'attraction':
        return '景点';
      case 'shop':
        return '购物';
      default:
        return '附近';
    }
  }
}
