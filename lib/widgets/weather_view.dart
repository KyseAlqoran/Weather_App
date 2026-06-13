import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/weather_model.dart';
import 'weather_info_tile.dart';
import 'forecast_card.dart';
import 'hourly_forecast_card.dart';

class WeatherView extends StatelessWidget {
  final Location currentLocation;
  final WeatherData weatherData;
  final bool isCelsius;
  final Future<void> Function() onRefresh;

  const WeatherView({
    super.key,
    required this.currentLocation,
    required this.weatherData,
    required this.isCelsius,
    required this.onRefresh,
  });

  String _formatTemp(double temp) {
    if (!isCelsius) {
      temp = (temp * 9 / 5) + 32;
    }
    return '${temp.round()}°';
  }

  @override
  Widget build(BuildContext context) {
    final current = weatherData.current;
    final daily = weatherData.daily.isNotEmpty ? weatherData.daily.first : null;
    final emoji = WeatherUtils.getWeatherEmoji(current.weatherCode);
    final label = WeatherUtils.getWeatherLabel(current.weatherCode);

    // Get hourly forecasts from current time onwards (next 24 hours)
    final now = DateTime.now();
    final upcomingHourly = weatherData.hourly
        .where((h) => h.date.isAfter(now.subtract(const Duration(hours: 1))))
        .take(24)
        .toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF38BDF8),
      backgroundColor: const Color(0xFF0F172A),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current Weather Card
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${currentLocation.name}${currentLocation.country.isNotEmpty ? ', ${currentLocation.country}' : ''}',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 80),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _formatTemp(current.temperature),
                            style: GoogleFonts.outfit(
                              fontSize: 84,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.0,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            label,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF38BDF8),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fade(duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),
                
                const SizedBox(height: 32),
                
                // Hourly Forecast
                if (upcomingHourly.isNotEmpty) ...[
                  Text(
                    'HOURLY FORECAST',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 2.0,
                    ),
                  ).animate().fade(delay: 100.ms, duration: 600.ms),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: upcomingHourly.length,
                      itemBuilder: (context, index) {
                        return HourlyForecastCard(
                          forecast: upcomingHourly[index],
                          isCelsius: isCelsius,
                        ).animate().fade(delay: (200 + index * 50).ms, duration: 400.ms).slideX(begin: 0.2, curve: Curves.easeOutQuad);
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Grid of detailed metrics
                Text(
                  'CURRENT DETAILS',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    letterSpacing: 2.0,
                  ),
                ).animate().fade(delay: 200.ms, duration: 600.ms),
                const SizedBox(height: 16),
                
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildDetailBox(Icons.thermostat, 'Feels Like', _formatTemp(current.apparentTemperature)),
                    _buildDetailBox(Icons.water_drop_outlined, 'Humidity', '${current.humidity}%'),
                    _buildDetailBox(Icons.air, 'Wind', '${current.windSpeed} km/h'),
                    _buildDetailBox(Icons.visibility, 'Visibility', '${(current.visibility / 1000).toStringAsFixed(1)} km'),
                    if (daily != null) _buildDetailBox(Icons.wb_sunny, 'UV Index', daily.uvIndexMax.toStringAsFixed(1)),
                    _buildDetailBox(Icons.speed, 'Pressure', '${current.surfacePressure.round()} hPa'),
                    if (daily != null) _buildDetailBox(Icons.wb_twilight, 'Sunrise', daily.sunrise.split('T').last),
                    if (daily != null) _buildDetailBox(Icons.nights_stay, 'Sunset', daily.sunset.split('T').last),
                  ],
                ).animate().fade(delay: 300.ms, duration: 600.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),
                
                // 7-Day Forecast
                Text(
                  '7-DAY FORECAST',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    letterSpacing: 2.0,
                  ),
                ).animate().fade(delay: 400.ms, duration: 600.ms),
                const SizedBox(height: 16),
                SizedBox(
                  height: 190,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: weatherData.daily.length,
                    itemBuilder: (context, index) {
                      return ForecastCard(
                        forecast: weatherData.daily[index],
                        isCelsius: isCelsius,
                      ).animate().fade(delay: (400 + index * 100).ms, duration: 500.ms).slideX(begin: 0.2, curve: Curves.easeOutQuad);
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailBox(IconData icon, String label, String value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
