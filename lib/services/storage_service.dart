import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';

class StorageService {
  static const String _locationsKey = 'saved_locations';
  static const String _lastCityKey = 'last_city';

  Future<List<Location>> getSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? locationsJson = prefs.getString(_locationsKey);
    if (locationsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(locationsJson);
      return decoded.map((e) => Location.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveLocation(Location location) async {
    final locations = await getSavedLocations();
    // Avoid duplicates
    if (!locations.any((loc) => loc.name == location.name && loc.country == location.country)) {
      locations.add(location);
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(locations.map((e) => e.toJson()).toList());
      await prefs.setString(_locationsKey, encoded);
    }
  }

  Future<void> removeLocation(Location location) async {
    final locations = await getSavedLocations();
    locations.removeWhere((loc) => loc.name == location.name && loc.country == location.country);
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(locations.map((e) => e.toJson()).toList());
    await prefs.setString(_locationsKey, encoded);
  }

  Future<void> saveLastSearchedCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCityKey, city);
  }

  Future<String?> getLastSearchedCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastCityKey);
  }
}
