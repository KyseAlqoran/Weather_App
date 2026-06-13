import 'package:flutter/material.dart';
import '../models/weather_model.dart';

class WeatherBackground extends StatelessWidget {
  final WeatherData? weatherData;

  const WeatherBackground({super.key, this.weatherData});

  @override
  Widget build(BuildContext context) {
    if (weatherData == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF0F172A), Color(0xFF064E3B)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      );
    }

    final code = weatherData!.current.weatherCode;
    final isDay = weatherData!.current.isDay == 1;

    List<Color> colors;

    if (code == 0 || code == 1) {
      // Clear
      colors = isDay
          ? [
              const Color(0xFF1E3A8A),
              const Color(0xFF3B82F6),
            ] // Dark blue to bright blue
          : [const Color(0xFF0F172A), const Color(0xFF1E293B)]; // Slate dark
    } else if (code == 2 || code == 3) {
      // Cloudy
      colors = isDay
          ? [
              const Color(0xFF334155),
              const Color(0xFF64748B),
            ] // Cool dark grays
          : [const Color(0xFF1E293B), const Color(0xFF334155)];
    } else if (code >= 61 && code <= 65) {
      // Rain
      colors = [
        const Color(0xFF0F172A),
        const Color(0xFF312E81),
      ]; // Slate to deep indigo
    } else if (code >= 71 && code <= 75) {
      // Snow
      colors = [
        const Color(0xFF1E293B),
        const Color(0xFF475569),
      ]; // Slate to medium gray
    } else if (code == 95 || code == 99) {
      // Thunderstorm
      colors = [const Color(0xFF09090B), const Color(0xFF27272A)]; // Near black
    } else {
      // Default
      colors = [const Color(0xFF0F172A), const Color(0xFF1E1B4B)];
    }

    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}
