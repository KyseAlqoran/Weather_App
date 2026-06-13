import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../widgets/weather_view.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CurrentLocationScreen extends StatefulWidget {
  final bool isCelsius;
  final void Function(WeatherData) onWeatherLoaded;

  const CurrentLocationScreen({super.key, required this.isCelsius, required this.onWeatherLoaded});

  @override
  State<CurrentLocationScreen> createState() => _CurrentLocationScreenState();
}

class _CurrentLocationScreenState extends State<CurrentLocationScreen> {
  final WeatherService _weatherService = WeatherService();

  Location? _currentLocation;
  WeatherData? _weatherData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndWeather();
  }

  Future<void> _fetchLocationAndWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }

      Position? position = await Geolocator.getLastKnownPosition();

      LocationSettings locationSettings;
      if (Theme.of(context).platform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.low,
          forceLocationManager: true,
          timeLimit: const Duration(seconds: 10),
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        );
      }

      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );
      }

      String cityName = 'Unknown Location';
      String country = '';
      try {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          cityName =
              place.locality ??
              place.subAdministrativeArea ??
              place.administrativeArea ??
              'Unknown Location';
          country = place.country ?? '';
        }
      } catch (e) {
        // Fallback to coordinates if geocoding fails
        cityName =
            '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
      }

      final location = Location(
        name: cityName,
        country: country,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final weatherData = await _weatherService.getWeather(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _currentLocation = location;
          _weatherData = weatherData;
          _isLoading = false;
        });
        widget.onWeatherLoaded(weatherData);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                'Unable to get location',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchLocationAndWeather,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ).animate().fade(duration: 500.ms),
      );
    }

    if (_weatherData == null || _currentLocation == null) {
      return const SizedBox();
    }

    return WeatherView(
      currentLocation: _currentLocation!,
      weatherData: _weatherData!,
      isCelsius: widget.isCelsius,
      onRefresh: _fetchLocationAndWeather,
    );
  }
}
