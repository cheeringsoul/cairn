import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../tool_registry.dart';

/// Fetches current weather + short forecast using Open-Meteo
/// (no API key required, CN-accessible).
class WeatherTool extends Tool {
  @override
  String get name => 'weather';

  @override
  String get displayName => 'Weather';

  @override
  String get statusLabel => 'Fetching weather…';

  @override
  String get description =>
      'Get current weather and a short daily forecast for a location. '
      'Use this whenever the user asks about the weather, temperature, '
      'rain, wind, or forecast.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'location': {
            'type': 'string',
            'description':
                'A place name, e.g. "Beijing", "上海", "New York", "Tokyo". '
                    'Can be in any language supported by Open-Meteo geocoding.',
          },
        },
        'required': ['location'],
      };

  @override
  IconData get icon => Icons.wb_sunny_outlined;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    final location = (args['location'] as String?)?.trim() ?? '';
    if (location.isEmpty) {
      return jsonEncode({'error': 'location is required'});
    }

    // 1. Geocode.
    final geoUri = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search'
      '?name=${Uri.encodeQueryComponent(location)}&count=1&language=zh&format=json',
    );
    final geoResp =
        await http.get(geoUri).timeout(const Duration(seconds: 8));
    if (geoResp.statusCode != 200) {
      return jsonEncode({'error': 'geocoding HTTP ${geoResp.statusCode}'});
    }
    final geoJson = jsonDecode(geoResp.body) as Map<String, dynamic>;
    final results = geoJson['results'] as List?;
    if (results == null || results.isEmpty) {
      return jsonEncode({'error': 'Location "$location" not found'});
    }
    final hit = results.first as Map<String, dynamic>;
    final lat = hit['latitude'];
    final lon = hit['longitude'];
    final resolvedName = [
      hit['name'],
      hit['admin1'],
      hit['country'],
    ].whereType<String>().join(', ');

    // 2. Fetch weather.
    final wxUri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,apparent_temperature,relative_humidity_2m,'
      'weather_code,wind_speed_10m,precipitation'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum'
      '&forecast_days=3&timezone=auto',
    );
    final wxResp = await http.get(wxUri).timeout(const Duration(seconds: 8));
    if (wxResp.statusCode != 200) {
      return jsonEncode({'error': 'weather HTTP ${wxResp.statusCode}'});
    }
    final wx = jsonDecode(wxResp.body) as Map<String, dynamic>;
    final cur = wx['current'] as Map<String, dynamic>?;
    final daily = wx['daily'] as Map<String, dynamic>?;

    final days = <Map<String, dynamic>>[];
    if (daily != null) {
      final dates = (daily['time'] as List?) ?? [];
      final codes = (daily['weather_code'] as List?) ?? [];
      final tmax = (daily['temperature_2m_max'] as List?) ?? [];
      final tmin = (daily['temperature_2m_min'] as List?) ?? [];
      final precip = (daily['precipitation_sum'] as List?) ?? [];
      for (var i = 0; i < dates.length; i++) {
        days.add({
          'date': dates[i],
          'condition': _codeToText(codes.elementAtOrNull(i)),
          'temp_max_c': tmax.elementAtOrNull(i),
          'temp_min_c': tmin.elementAtOrNull(i),
          'precipitation_mm': precip.elementAtOrNull(i),
        });
      }
    }

    return jsonEncode({
      'location': resolvedName,
      'current': cur == null
          ? null
          : {
              'temperature_c': cur['temperature_2m'],
              'feels_like_c': cur['apparent_temperature'],
              'humidity_percent': cur['relative_humidity_2m'],
              'wind_speed_kmh': cur['wind_speed_10m'],
              'precipitation_mm': cur['precipitation'],
              'condition': _codeToText(cur['weather_code']),
              'observed_at': cur['time'],
            },
      'daily_forecast': days,
    });
  }

  static String _codeToText(dynamic code) {
    final c = (code as num?)?.toInt();
    // WMO weather interpretation codes.
    switch (c) {
      case 0:
        return 'Clear';
      case 1:
        return 'Mainly clear';
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 56:
      case 57:
        return 'Freezing drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 66:
      case 67:
        return 'Freezing rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 77:
        return 'Snow grains';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with hail';
      default:
        return 'Unknown';
    }
  }
}
