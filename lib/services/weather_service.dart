import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class WeatherInfo {
  final double temperature;
  final String description;
  final String locationName;
  final double lat;
  final double lon;

  WeatherInfo({
    required this.temperature,
    required this.description,
    required this.locationName,
    required this.lat,
    required this.lon,
  });
}

class WeatherService {
  static Future<WeatherInfo?> getCurrentWeather() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Get location name via reverse geocoding
      String locationName = 'Unknown';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[];
          if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) parts.add(p.administrativeArea!);
          locationName = parts.join(', ');
          if (locationName.isEmpty) locationName = p.country ?? 'Unknown';
        }
      } catch (_) {
        // Geocoding failed, use coordinates
        locationName = '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
      }

      // Fetch weather from Open-Meteo (free, no API key needed)
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${position.latitude}'
        '&longitude=${position.longitude}'
        '&current=temperature_2m,weather_code'
        '&timezone=auto'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];
        final temp = (current['temperature_2m'] as num).toDouble();
        final weatherCode = current['weather_code'] as int;
        final desc = _weatherCodeToDescription(weatherCode);

        return WeatherInfo(
          temperature: temp,
          description: desc,
          locationName: locationName,
          lat: position.latitude,
          lon: position.longitude,
        );
      }
    } catch (_) {
      // Silently fail - weather is optional
    }
    return null;
  }

  static String _weatherCodeToDescription(int code) {
    if (code == 0) return 'Clear sky ☀️';
    if (code <= 3) return 'Partly cloudy ⛅';
    if (code <= 48) return 'Foggy 🌫️';
    if (code <= 57) return 'Drizzle 🌦️';
    if (code <= 65) return 'Rainy 🌧️';
    if (code <= 67) return 'Freezing rain 🌨️';
    if (code <= 77) return 'Snow ❄️';
    if (code <= 82) return 'Rain showers 🌧️';
    if (code <= 86) return 'Snow showers 🌨️';
    if (code <= 99) return 'Thunderstorm ⛈️';
    return 'Unknown';
  }
}
