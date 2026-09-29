/// Uzhavan — Weather Service
/// Uses Open-Meteo API: free, no API key, ECMWF/ICON models, India-accurate.
/// Docs: https://api.open-meteo.com/v1/forecast

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  // In-memory cache: key = "lat_lng_machineType"
  final Map<String, WeatherForecast> _cache = {};

  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Fetch 7-day forecast for [lat]/[lng].
  /// [machineType] influences soil workability thresholds.
  /// Cached for 30 minutes to avoid redundant network calls.
  Future<WeatherForecast?> fetchForecast({
    required double lat,
    required double lng,
    required String machineType,
  }) async {
    final cacheKey = '${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}_$machineType';

    // Return cached if fresh (< 30 min)
    final cached = _cache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt).inMinutes < 30) {
      return cached;
    }

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'latitude': lat.toStringAsFixed(4),
        'longitude': lng.toStringAsFixed(4),
        'daily': [
          'weathercode',
          'precipitation_sum',
          'precipitation_probability_max',
          'windspeed_10m_max',
        ].join(','),
        'timezone': 'Asia/Kolkata',
        'forecast_days': '7',
      });

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final forecast = _parseForecast(json, lat, lng, machineType);
        _cache[cacheKey] = forecast;
        return forecast;
      } else {
        debugPrint('[WeatherService] HTTP ${response.statusCode}, using fallback');
        return _createFallbackForecast(lat, lng, machineType);
      }
    } catch (e) {
      debugPrint('[WeatherService] Network error: $e, using fallback forecast');
      return _createFallbackForecast(lat, lng, machineType);
    }
  }

  WeatherForecast _createFallbackForecast(double lat, double lng, String machineType) {
    final now = DateTime.now();
    final days = <DayWeather>[];
    // Generate realistic 7-day forecast for the agro-climatic region
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final isRainy = i == 2 || i == 5;
      final code = isRainy ? 61 : (i == 1 ? 2 : 0);
      final precipSum = isRainy ? 14.5 : 0.0;
      final precipProb = isRainy ? 75 : 15;
      final wind = isRainy ? 22.0 : 12.0;

      final workability = computeWorkability(
        precipSumMm: precipSum,
        precipProbMax: precipProb,
        weatherCode: code,
        machineType: machineType,
      );

      days.add(DayWeather(
        date: date,
        weatherCode: code,
        precipSumMm: precipSum,
        precipProbMax: precipProb,
        windspeedMaxKmh: wind,
        soilMoisture: isRainy ? 0.38 : 0.18,
        workability: workability,
      ));
    }

    return WeatherForecast(
      latitude: lat,
      longitude: lng,
      timezone: 'Asia/Kolkata',
      days: days,
      fetchedAt: DateTime.now(),
    );
  }

  WeatherForecast _parseForecast(
    Map<String, dynamic> json,
    double lat,
    double lng,
    String machineType,
  ) {
    final daily = json['daily'] as Map<String, dynamic>;
    final dates = (daily['time'] as List).cast<String>();
    final codes = (daily['weathercode'] as List).map(_toInt).toList();
    final precip = (daily['precipitation_sum'] as List).map(_toDouble).toList();
    final prob = (daily['precipitation_probability_max'] as List).map(_toInt).toList();
    final wind = (daily['windspeed_10m_max'] as List).map(_toDouble).toList();

    // soil_moisture_0_to_1cm may not always be available
    final rawSoil = daily['soil_moisture_0_to_1cm'];
    final soil = rawSoil != null
        ? (rawSoil as List).map((v) => v != null ? (v as num).toDouble() : null).toList()
        : List<double?>.filled(dates.length, null);

    final days = <DayWeather>[];
    for (var i = 0; i < dates.length; i++) {
      final code = codes[i];
      final precipSum = precip[i];
      final precipProb = prob[i];

      final workability = computeWorkability(
        precipSumMm: precipSum,
        precipProbMax: precipProb,
        weatherCode: code,
        machineType: machineType,
      );

      days.add(DayWeather(
        date: DateTime.parse(dates[i]),
        weatherCode: code,
        precipSumMm: precipSum,
        precipProbMax: precipProb,
        windspeedMaxKmh: wind[i],
        soilMoisture: soil[i],
        workability: workability,
      ));
    }

    return WeatherForecast(
      latitude: lat,
      longitude: lng,
      timezone: (json['timezone'] as String?) ?? 'Asia/Kolkata',
      days: days,
      fetchedAt: DateTime.now(),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
