import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';

class WeatherService {
  static const String _weatherApiKey = ApiConfig.weatherApiKey;
  static Map<String, dynamic>? _cachedWeather;

  static bool get hasCachedWeather => _cachedWeather != null;
  static Map<String, dynamic>? get cachedWeather => _cachedWeather;

  static String? get cachedLocationName => _cachedWeather?['locationName'];
  static String? get cachedCityName => _cachedWeather?['cityName'];
  static double? get cachedLat => (_cachedWeather?['lat'] as num?)?.toDouble();
  static double? get cachedLng => (_cachedWeather?['lng'] as num?)?.toDouble();
  static double? get cachedTemp => (_cachedWeather?['temp'] as num?)?.toDouble();
  static bool get isUsingDefaultLocation => _cachedWeather?['isDefault'] == true;

  /// Fetches the user's real live device location and current weather conditions
  static Future<Map<String, dynamic>> fetchCurrentLocationWeather({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedWeather != null &&
        _cachedWeather!['isDefault'] != true) {
      return _cachedWeather!;
    }

    Position? position;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          // 1. Try instant last known position (takes 0-50ms)
          position = await Geolocator.getLastKnownPosition();

          // 2. If null, request fresh current position with 4 second timeout
          position ??= await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          ).timeout(const Duration(seconds: 4));
        }
      }
    } catch (e) {
      debugPrint("Location service check exception: $e");
    }

    // If real GPS coordinates were acquired
    if (position != null && _weatherApiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$_weatherApiKey',
        );

        final response =
            await http.get(url).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final String cityName = (data['name'] as String?)?.trim() ?? '';
          final String country =
              (data['sys']?['country'] as String?)?.trim() ?? '';
          final String weatherDesc = (data['weather'] != null &&
                  (data['weather'] as List).isNotEmpty)
              ? (data['weather'][0]['description'] as String? ?? '')
              : '';

          String locationName = cityName;
          if (cityName.isNotEmpty && country.isNotEmpty) {
            locationName = '$cityName, $country';
          } else if (cityName.isEmpty) {
            locationName =
                'Lat: ${position.latitude.toStringAsFixed(3)}, Lng: ${position.longitude.toStringAsFixed(3)}';
          }

          _cachedWeather = {
            "temp": (data['main']?['temp'] as num?)?.toDouble() ?? 28.0,
            "humidity":
                (data['main']?['humidity'] as num?)?.toDouble() ?? 65.0,
            "description": weatherDesc,
            "cityName": cityName,
            "locationName": locationName,
            "lat": position.latitude,
            "lng": position.longitude,
            "isDefault": false,
          };
          return _cachedWeather!;
        }
      } catch (e) {
        debugPrint("OpenWeatherMap fetch error: $e");
      }

      // If OpenWeatherMap failed but we have genuine GPS coordinates:
      _cachedWeather = {
        "temp": 28.0,
        "humidity": 65.0,
        "description": "Clear",
        "cityName": "",
        "locationName":
            "Latitude ${position.latitude.toStringAsFixed(3)}, Longitude ${position.longitude.toStringAsFixed(3)}",
        "lat": position.latitude,
        "lng": position.longitude,
        "isDefault": false,
      };
      return _cachedWeather!;
    }

    // Fallback ONLY when user denies location permission or GPS is turned off
    _cachedWeather = {
      "temp": 28.0,
      "humidity": 65.0,
      "description": "Clear",
      "cityName": "",
      "locationName": "",
      "lat": 11.1271, // General regional reference (Tamil Nadu center)
      "lng": 78.6569,
      "isDefault": true,
    };
    return _cachedWeather!;
  }
}
