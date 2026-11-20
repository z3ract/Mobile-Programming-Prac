import '../entities/region_entity.dart';
import '../entities/weather_entity.dart';

/// Contract for fetching live weather forecasts from BMKG public API.
abstract interface class IWeatherRepository {
  Future<WeatherForecastEntity> fetchForecast(
    RegionEntity region, {
    bool forceRefresh = false,
  });
}
