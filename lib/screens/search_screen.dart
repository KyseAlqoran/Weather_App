import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/storage_service.dart';
import '../widgets/weather_view.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SearchScreen extends StatefulWidget {
  final bool isCelsius;
  final void Function(WeatherData) onWeatherLoaded;

  const SearchScreen({super.key, required this.isCelsius, required this.onWeatherLoaded});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final WeatherService _weatherService = WeatherService();
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();

  List<Location> _savedLocations = [];
  Location? _currentLocation;
  WeatherData? _weatherData;
  bool _isLoading = false;
  bool _isViewingWeather = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  Future<void> _loadSavedLocations() async {
    final locations = await _storageService.getSavedLocations();
    setState(() {
      _savedLocations = locations;
    });
  }

  Future<void> _fetchWeather(String city, {Location? existingLocation}) async {
    if (city.trim().isEmpty && existingLocation == null) return;

    setState(() {
      _isLoading = true;
      _isViewingWeather = true;
    });

    try {
      Location location;
      if (existingLocation != null) {
        location = existingLocation;
      } else {
        final loc = await _weatherService.geocodeCity(city.trim());
        if (loc == null) {
          _showError('City not found. Please try another name.');
          setState(() {
            _isLoading = false;
            _isViewingWeather = false;
          });
          return;
        }
        location = loc;
        await _storageService.saveLocation(location);
        _loadSavedLocations();
      }

      final weatherData = await _weatherService.getWeather(
        location.latitude,
        location.longitude,
      );

      setState(() {
        _currentLocation = location;
        _weatherData = weatherData;
        _isLoading = false;
      });
      widget.onWeatherLoaded(weatherData);

    } catch (e) {
      _showError('Unable to fetch weather data. Please check your connection.');
      setState(() {
        _isLoading = false;
        _isViewingWeather = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isViewingWeather) {
      return Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isViewingWeather = false;
                    _weatherData = null;
                  });
                },
              ),
              Text(
                'Back to Saved',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                    )
                  : _weatherData != null
                      ? WeatherView(
                          currentLocation: _currentLocation!,
                          weatherData: _weatherData!,
                          isCelsius: widget.isCelsius,
                          onRefresh: () => _fetchWeather('', existingLocation: _currentLocation),
                        )
                      : const SizedBox(),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopSection().animate().fade(duration: 600.ms).slideY(begin: -0.2),
        const SizedBox(height: 32),
        Text(
          'SAVED LOCATIONS',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 2.0,
          ),
        ).animate().fade(delay: 200.ms),
        const SizedBox(height: 16),
        Expanded(
          child: _savedLocations.isEmpty
              ? Center(
                  child: Text(
                    'No saved locations yet.\nSearch for a city above!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ).animate().fade(delay: 300.ms)
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _savedLocations.length,
                  itemBuilder: (context, index) {
                    final loc = _savedLocations[index];
                    return _buildLocationItem(loc, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTopSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search new city...',
              hintStyle: const TextStyle(color: Colors.white54),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.white70),
                onPressed: _isLoading
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        _fetchWeather(_searchController.text);
                      },
              ),
            ),
            onSubmitted: (_) {
              if (!_isLoading) {
                _fetchWeather(_searchController.text);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLocationItem(Location loc, int index) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _fetchWeather('', existingLocation: loc);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.name,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (loc.country.isNotEmpty)
                    Text(
                      loc.country,
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              onPressed: () async {
                await _storageService.removeLocation(loc);
                _loadSavedLocations();
              },
            ),
          ],
        ),
      ).animate().fade(delay: (300 + index * 100).ms).slideX(begin: 0.1),
    );
  }
}
