import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/weather_model.dart';
import 'package:intl/intl.dart';

class HourlyForecastCard extends StatelessWidget {
  final HourlyForecast forecast;
  final bool isCelsius;

  const HourlyForecastCard({
    super.key,
    required this.forecast,
    required this.isCelsius,
  });

  String _formatTemp(double temp) {
    if (!isCelsius) {
      temp = (temp * 9 / 5) + 32;
    }
    return '${temp.round()}°';
  }

  @override
  Widget build(BuildContext context) {
    final emoji = WeatherUtils.getWeatherEmoji(forecast.weatherCode);
    final timeStr = DateFormat.j().format(forecast.date); // e.g. 5 PM

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timeStr,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 12),
          Text(
            _formatTemp(forecast.temperature),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
