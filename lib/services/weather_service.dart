import 'package:dio/dio.dart';
import '../models/weather_model.dart';

class WeatherService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static const List<String> _photonPlaceTags = [
    'place:city',
    'place:town',
    'place:village',
  ];

  WeatherService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // ignore: avoid_print
          print('Request sent to: ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          // ignore: avoid_print
          print('Response code: ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          // ignore: avoid_print
          print('Dio error: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  Future<Location?> geocodeCity(String cityName) async {
    final suggestions = await geocodeCitySuggestions(cityName, count: 1);
    if (suggestions.isNotEmpty) return suggestions.first;

    // Fallback to Nominatim if Photon returns nothing or is blocked.
    return _geocodeWithNominatim(cityName.trim());
  }

  Future<Location?> _geocodeWithNominatim(String query) async {
    try {
      final uri =
          Uri.parse('https://nominatim.openstreetmap.org/search').replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': '1',
          'accept-language': 'en',
        },
      );

      final response = await _dio.getUri(
        uri,
        options: Options(
          headers: {
            'User-Agent': 'weather_app/1.0',
            'Accept': 'application/json',
          },
        ),
      );

      final results = response.data as List<dynamic>? ?? [];
      if (results.isEmpty) return null;

      final data = results.first as Map<String, dynamic>;
      final name = data['name']?.toString() ?? '';
      if (name.isEmpty) return null;

      final address = data['address'] as Map<String, dynamic>? ?? {};
      String country = address['country']?.toString() ?? '';
      if (country.isEmpty) {
        final parts = data['display_name']?.toString().split(',');
        if (parts != null && parts.isNotEmpty) {
          country = parts.last.trim();
        }
      }

      final latitude = double.tryParse(data['lat']?.toString() ?? '') ?? 0.0;
      final longitude = double.tryParse(data['lon']?.toString() ?? '') ?? 0.0;
      if (latitude == 0.0 && longitude == 0.0) return null;

      return Location(
        name: name,
        country: country,
        latitude: latitude,
        longitude: longitude,
      );
    } on DioException catch (e) {
      // ignore: avoid_print
      print('Nominatim geocode fallback failed: ${e.message}');
      return null;
    }
  }

  Future<List<Location>> geocodeCitySuggestions(
    String cityName, {
    int count = 5,
  }) async {
    if (cityName.trim().isEmpty) return [];
    try {
      final uri = Uri.parse('https://photon.komoot.io/api/').replace(
        queryParameters: {
          'q': cityName.trim(),
          'limit': count.toString(),
          'osm_tag': _photonPlaceTags,
        },
      );

      final response = await _dio.getUri(
        uri,
        options: Options(
          headers: {
            'User-Agent': 'weather_app/1.0',
            'Accept': 'application/json',
          },
        ),
      );
      final features = response.data['features'] as List<dynamic>? ?? [];

      return features
          .map((feature) => _locationFromPhotonFeature(feature))
          .toList();
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<Location> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse('https://photon.komoot.io/reverse').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lon': lon.toString(),
        },
      );

      final response = await _dio.getUri(
        uri,
        options: Options(
          headers: {
            'User-Agent': 'weather_app/1.0',
            'Accept': 'application/json',
          },
        ),
      );
      final features = response.data['features'] as List<dynamic>? ?? [];

      if (features.isNotEmpty) {
        return _locationFromPhotonFeature(
          features.first,
          fallbackLat: lat,
          fallbackLon: lon,
        );
      }
    } on DioException catch (e) {
      // ignore: avoid_print
      print('Photon reverse geocode failed, falling back: ${e.message}');
    }

    return _reverseGeocodeBigDataCloud(lat, lon);
  }

  Future<Location> _reverseGeocodeBigDataCloud(double lat, double lon) async {
    try {
      final response = await _dio.get(
        'https://api.bigdatacloud.net/data/reverse-geocode-client',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'localityLanguage': 'en',
        },
      );

      final data = response.data;
      return Location(
        name: data['city']?.toString().isNotEmpty == true
            ? data['city'].toString()
            : data['locality']?.toString() ?? 'My Location',
        country: data['countryName']?.toString() ?? '',
        latitude: lat,
        longitude: lon,
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Location _locationFromPhotonFeature(
    dynamic feature, {
    double? fallbackLat,
    double? fallbackLon,
  }) {
    final props = (feature['properties'] as Map<String, dynamic>?) ?? {};
    final geometry = (feature['geometry'] as Map<String, dynamic>?) ?? {};
    final coords = (geometry['coordinates'] as List<dynamic>?) ?? [];

    double longitude =
        coords.isNotEmpty ? (coords[0] as num).toDouble() : 0.0;
    double latitude =
        coords.length > 1 ? (coords[1] as num).toDouble() : 0.0;

    if (latitude == 0.0 && longitude == 0.0) {
      latitude = fallbackLat ?? 0.0;
      longitude = fallbackLon ?? 0.0;
    }

    String name = props['name']?.toString() ?? '';
    if (name.isEmpty) {
      name = props['city']?.toString() ??
          props['locality']?.toString() ??
          'Unknown';
    }

    String country = props['country']?.toString() ?? '';
    if (country.isEmpty) {
      country = props['countrycode']?.toString() ?? '';
    }

    return Location(
      name: name,
      country: country,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<WeatherData> getWeather(double lat, double lon) async {
    try {
      final response = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'current':
              'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code,apparent_temperature,surface_pressure,visibility,is_day',
          'hourly': 'temperature_2m,weather_code',
          'daily':
              'temperature_2m_max,temperature_2m_min,weather_code,precipitation_sum,sunrise,sunset,uv_index_max',
          'timezone': 'auto',
          'forecast_days': 7,
        },
      );

      return WeatherData.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out.';
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      case DioExceptionType.badResponse:
        return 'Server error: ${error.response?.statusCode}.';
      default:
        return 'Unable to fetch weather data.';
    }
  }
}
