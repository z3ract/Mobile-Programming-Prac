import '../entities/notification_preference_entity.dart';
import '../entities/region_entity.dart';
import '../entities/weather_entity.dart';

/// Contract for persistent local caching and user preferences.
abstract interface class IStorageRepository {
  Future<RegionEntity?> loadActiveRegion();
  Future<void> saveActiveRegion(RegionEntity region);

  Future<List<RegionEntity>> loadFavoriteRegions();
  Future<void> saveFavoriteRegions(List<RegionEntity> regions);

  Future<NotificationPreferenceEntity> loadNotificationPreferences();
  Future<void> saveNotificationPreferences(NotificationPreferenceEntity prefs);

  Future<WeatherForecastEntity?> loadWeatherCache(String adm4);
  Future<void> saveWeatherCache(String adm4, WeatherForecastEntity forecast);

  Future<bool> hasNotifiedAlert(String alertId);
  Future<void> markAlertNotified(String alertId);
}
