import 'dart:convert';
import '../../adapters/dtos/bmkg_weather_dto.dart';
import '../../domain/entities/region_entity.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/i_weather_repository.dart';
import '../config/bmkg_api_config.dart';
import '../http/bmkg_http_client.dart';

/// Fetches live 3-day 3-hourly weather forecasts from api.bmkg.go.id.
class BmkgWeatherRepository implements IWeatherRepository {
  final BmkgHttpClient _httpClient;
  final BmkgApiConfig _config;

  const BmkgWeatherRepository({
    required this._httpClient,
    required this._config,
  });

  @override
  Future<WeatherForecastEntity> fetchForecast(
    RegionEntity region, {
    bool forceRefresh = false,
  }) async {
    final uri = _config.weatherForecastUri(region.adm4);
    final rawBody = await _httpClient.getBody(
      uri,
      ttl: _config.weatherCacheTtl,
      forceRefresh: forceRefresh,
      acceptHeader: 'application/json',
    );
    final decoded = json.decode(rawBody) as Map<String, dynamic>;
    return BmkgWeatherDto.fromBmkgJson(
      decoded,
      fallbackRegion: region,
      sourceAttribution: _config.bmkgAttribution,
    );
  }
}
