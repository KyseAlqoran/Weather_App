class Location {
  final String name;
  final String country;
  final double latitude;
  final double longitude;

  Location({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class CurrentWeather {
  final double temperature;
  final double apparentTemperature;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final double surfacePressure;
  final double visibility;
  final int isDay;

  CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.surfacePressure,
    required this.visibility,
    required this.isDay,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature_2m'] ?? 0).toDouble(),
      apparentTemperature: (json['apparent_temperature'] ?? 0).toDouble(),
      humidity: json['relative_humidity_2m'] ?? 0,
      windSpeed: (json['wind_speed_10m'] ?? 0).toDouble(),
      weatherCode: json['weather_code'] ?? 0,
      surfacePressure: (json['surface_pressure'] ?? 0).toDouble(),
      visibility: (json['visibility'] ?? 0).toDouble(),
      isDay: json['is_day'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature_2m': temperature,
      'apparent_temperature': apparentTemperature,
      'relative_humidity_2m': humidity,
      'wind_speed_10m': windSpeed,
      'weather_code': weatherCode,
      'surface_pressure': surfacePressure,
      'visibility': visibility,
      'is_day': isDay,
    };
  }
}

class HourlyForecast {
  final DateTime date;
  final double temperature;
  final int weatherCode;

  HourlyForecast({
    required this.date,
    required this.temperature,
    required this.weatherCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'time': date.toIso8601String(),
      'temperature_2m': temperature,
      'weather_code': weatherCode,
    };
  }
}

class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;
  final double precipitation;
  final String sunrise;
  final String sunset;
  final double uvIndexMax;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
    required this.precipitation,
    required this.sunrise,
    required this.sunset,
    required this.uvIndexMax,
  });

  Map<String, dynamic> toJson() {
    return {
      'time': date.toIso8601String(),
      'temperature_2m_max': maxTemp,
      'temperature_2m_min': minTemp,
      'weather_code': weatherCode,
      'precipitation_sum': precipitation,
      'sunrise': sunrise,
      'sunset': sunset,
      'uv_index_max': uvIndexMax,
    };
  }
}

class WeatherData {
  final CurrentWeather current;
  final List<DailyForecast> daily;
  final List<HourlyForecast> hourly;

  WeatherData({required this.current, required this.daily, required this.hourly});

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = CurrentWeather.fromJson(json['current'] ?? json['current_weather'] ?? json);

    final dailyJson = json['daily'] ?? {};
    final List<dynamic> dailyTimes = dailyJson['time'] ?? [];
    final List<dynamic> maxTemps = dailyJson['temperature_2m_max'] ?? [];
    final List<dynamic> minTemps = dailyJson['temperature_2m_min'] ?? [];
    final List<dynamic> dailyCodes = dailyJson['weather_code'] ?? [];
    final List<dynamic> precipitations = dailyJson['precipitation_sum'] ?? [];
    final List<dynamic> sunrises = dailyJson['sunrise'] ?? [];
    final List<dynamic> sunsets = dailyJson['sunset'] ?? [];
    final List<dynamic> uvIndexes = dailyJson['uv_index_max'] ?? [];

    List<DailyForecast> daily = [];
    for (int i = 0; i < dailyTimes.length; i++) {
      daily.add(
        DailyForecast(
          date: DateTime.tryParse(dailyTimes[i].toString()) ?? DateTime.now(),
          maxTemp: (maxTemps.length > i ? maxTemps[i] ?? 0 : 0).toDouble(),
          minTemp: (minTemps.length > i ? minTemps[i] ?? 0 : 0).toDouble(),
          weatherCode: dailyCodes.length > i ? dailyCodes[i] ?? 0 : 0,
          precipitation: (precipitations.length > i ? precipitations[i] ?? 0 : 0).toDouble(),
          sunrise: sunrises.length > i ? sunrises[i]?.toString() ?? '' : '',
          sunset: sunsets.length > i ? sunsets[i]?.toString() ?? '' : '',
          uvIndexMax: (uvIndexes.length > i ? uvIndexes[i] ?? 0 : 0).toDouble(),
        ),
      );
    }

    final hourlyJson = json['hourly'] ?? {};
    final List<dynamic> hourlyTimes = hourlyJson['time'] ?? [];
    final List<dynamic> hourlyTemps = hourlyJson['temperature_2m'] ?? [];
    final List<dynamic> hourlyCodes = hourlyJson['weather_code'] ?? [];

    List<HourlyForecast> hourly = [];
    for (int i = 0; i < hourlyTimes.length; i++) {
      hourly.add(
        HourlyForecast(
          date: DateTime.tryParse(hourlyTimes[i].toString()) ?? DateTime.now(),
          temperature: (hourlyTemps.length > i ? hourlyTemps[i] ?? 0 : 0).toDouble(),
          weatherCode: hourlyCodes.length > i ? hourlyCodes[i] ?? 0 : 0,
        ),
      );
    }

    return WeatherData(current: current, daily: daily, hourly: hourly);
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current.toJson(),
      'daily': {
        'time': daily.map((e) => e.date.toIso8601String()).toList(),
        'temperature_2m_max': daily.map((e) => e.maxTemp).toList(),
        'temperature_2m_min': daily.map((e) => e.minTemp).toList(),
        'weather_code': daily.map((e) => e.weatherCode).toList(),
        'precipitation_sum': daily.map((e) => e.precipitation).toList(),
        'sunrise': daily.map((e) => e.sunrise).toList(),
        'sunset': daily.map((e) => e.sunset).toList(),
        'uv_index_max': daily.map((e) => e.uvIndexMax).toList(),
      },
      'hourly': {
        'time': hourly.map((e) => e.date.toIso8601String()).toList(),
        'temperature_2m': hourly.map((e) => e.temperature).toList(),
        'weather_code': hourly.map((e) => e.weatherCode).toList(),
      }
    };
  }
}

class WeatherUtils {
  static String getWeatherLabel(int code) {
    if (code == 0) return 'Clear Sky';
    if (code == 1) return 'Mainly Clear';
    if (code == 2) return 'Partly Cloudy';
    if (code == 3) return 'Overcast';
    if (code >= 45 && code <= 48) return 'Foggy';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 61 && code <= 65) return 'Rain';
    if (code >= 71 && code <= 75) return 'Snow';
    if (code >= 80 && code <= 82) return 'Rain Showers';
    if (code >= 85 && code <= 86) return 'Snow Showers';
    if (code == 95) return 'Thunderstorm';
    if (code == 99) return 'Heavy Thunderstorm';
    return 'Unknown';
  }

  static String getWeatherEmoji(int code) {
    if (code == 0) return '☀️';
    if (code == 1) return '🌤';
    if (code == 2) return '⛅';
    if (code == 3) return '🌥';
    if (code >= 45 && code <= 48) return '🌫';
    if (code >= 51 && code <= 55) return '🌦';
    if (code >= 61 && code <= 65) return '🌧';
    if (code >= 71 && code <= 75) return '❄️';
    if (code >= 80 && code <= 82) return '🌧';
    if (code >= 85 && code <= 86) return '🌨';
    if (code == 95 || code == 99) return '⛈';
    return '🌡';
  }
}
