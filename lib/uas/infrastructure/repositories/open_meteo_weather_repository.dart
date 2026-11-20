import 'dart:convert';
import '../../adapters/dtos/open_meteo_weather_dto.dart';
import '../../domain/entities/region_entity.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/i_weather_repository.dart';
import '../config/bmkg_api_config.dart';
import '../http/bmkg_http_client.dart';

/// Fetches live worldwide weather forecasts (Indonesia and global cities)
/// from Open-Meteo Forecast API using each region's coordinates.
class OpenMeteoWeatherRepository implements IWeatherRepository {
  final BmkgHttpClient _httpClient;
  final BmkgApiConfig _config;

  const OpenMeteoWeatherRepository({
    required this._httpClient,
    required this._config,
  });

  @override
  Future<WeatherForecastEntity> fetchForecast(
    RegionEntity region, {
    bool forceRefresh = false,
  }) async {
    final uri = _config.openMeteoForecastUri(
      latitude: region.latitude,
      longitude: region.longitude,
    );
    final rawBody = await _httpClient.getBody(
      uri,
      ttl: _config.weatherCacheTtl,
      forceRefresh: forceRefresh,
      acceptHeader: 'application/json',
    );
    final decoded = json.decode(rawBody) as Map<String, dynamic>;
    return OpenMeteoWeatherDto.fromOpenMeteoJson(
      decoded,
      region: region,
      sourceAttribution: _config.openMeteoAttribution,
    );
  }
}
