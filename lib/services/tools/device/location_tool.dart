import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../tool_registry.dart';

/// Get the user's current location. Prefers device GPS (accurate to
/// ~10m, requires a one-time permission prompt); falls back to IP
/// geolocation (city-level) if the user denies or GPS is disabled.
class LocationTool extends Tool {
  @override
  String get name => 'current_location';

  @override
  String get displayName => 'Current Location';

  @override
  String get statusLabel => 'Locating…';

  @override
  String get description =>
      "Get the user's current location (city, region, country, and "
      'coordinates). Use this whenever the user asks about things '
      '"here", "near me", "current city", or when a location-aware '
      'answer (weather, time, news, nearby places) is needed and the '
      'user has not specified a city.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {},
      };

  @override
  IconData get icon => Icons.my_location_outlined;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final gps = await _tryGps();
    if (gps != null) return gps;

    final errors = <String>[];
    final a = await _tryIpapiCo(errors);
    if (a != null) return a;
    final b = await _tryIpwhois(errors);
    if (b != null) return b;
    return jsonEncode({
      'error': 'GPS unavailable and all IP sources failed: ${errors.join(" | ")}'
    });
  }

  Future<String?> _tryGps() async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) return null;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      // Reverse geocode via Open-Meteo's free endpoint (city-level name).
      String? city, region, country, countryCode;
      try {
        final resp = await http
            .get(Uri.parse(
                'https://geocoding-api.open-meteo.com/v1/reverse'
                '?latitude=${pos.latitude}&longitude=${pos.longitude}'
                '&language=zh&count=1&format=json'))
            .timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          final j = jsonDecode(resp.body) as Map<String, dynamic>;
          final hit = (j['results'] as List?)?.firstOrNull as Map?;
          city = hit?['name'] as String?;
          region = hit?['admin1'] as String?;
          country = hit?['country'] as String?;
          countryCode = hit?['country_code'] as String?;
        }
      } catch (_) {
        // Reverse geocode is best-effort — return coords anyway.
      }

      return jsonEncode({
        'source': 'gps',
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'accuracy_m': pos.accuracy,
        'city': city,
        'region': region,
        'country': country,
        'country_code': countryCode,
      });
    } catch (_) {
      return null;
    }
  }

  Future<String?> _tryIpapiCo(List<String> errors) async {
    try {
      final resp = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) {
        errors.add('ipapi.co:${resp.statusCode}');
        return null;
      }
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      if (j['error'] == true) {
        errors.add('ipapi.co:${j['reason']}');
        return null;
      }
      return jsonEncode({
        'source': 'ipapi.co',
        'city': j['city'],
        'region': j['region'],
        'country': j['country_name'],
        'country_code': j['country_code'],
        'latitude': j['latitude'],
        'longitude': j['longitude'],
        'timezone': j['timezone'],
        'note': 'IP-based approximate location.',
      });
    } catch (e) {
      errors.add('ipapi.co:$e');
      return null;
    }
  }

  Future<String?> _tryIpwhois(List<String> errors) async {
    try {
      final resp = await http
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) {
        errors.add('ipwho.is:${resp.statusCode}');
        return null;
      }
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      if (j['success'] == false) {
        errors.add('ipwho.is:${j['message']}');
        return null;
      }
      return jsonEncode({
        'source': 'ipwho.is',
        'city': j['city'],
        'region': j['region'],
        'country': j['country'],
        'country_code': j['country_code'],
        'latitude': j['latitude'],
        'longitude': j['longitude'],
        'timezone': (j['timezone'] as Map?)?['id'],
        'note': 'IP-based approximate location.',
      });
    } catch (e) {
      errors.add('ipwho.is:$e');
      return null;
    }
  }
}
