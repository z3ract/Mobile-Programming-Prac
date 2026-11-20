import '../domain/entities/region_entity.dart';
import '../domain/entities/weather_entity.dart';
import '../domain/repositories/i_storage_repository.dart';
import '../domain/repositories/i_weather_repository.dart';

/// Fetches live BMKG weather forecast and falls back to persisted local cache when offline.
class FetchWeatherForecastUseCase {
  final IWeatherRepository _weatherRepository;
  final IStorageRepository _storageRepository;

  const FetchWeatherForecastUseCase({
    required this._weatherRepository,
    required this._storageRepository,
  });

  Future<WeatherForecastEntity> execute(
    RegionEntity region, {
    bool forceRefresh = false,
  }) async {
    try {
      final live = await _weatherRepository.fetchForecast(
        region,
        forceRefresh: forceRefresh,
      );
      final normalized = live.copyWith(fromCache: false);
      await _storageRepository.saveWeatherCache(region.adm4, normalized);
      return normalized;
    } catch (_) {
      final cached = await _storageRepository.loadWeatherCache(region.adm4);
      if (cached != null) {
        return cached.copyWith(
          region: region.copyWith(
            latitude: cached.region.latitude,
            longitude: cached.region.longitude,
            timezone: cached.region.timezone,
          ),
          fromCache: true,
        );
      }
      rethrow;
    }
  }
}
