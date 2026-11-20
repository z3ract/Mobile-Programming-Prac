import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../adapters/dtos/bmkg_weather_dto.dart';
import '../../adapters/dtos/notification_preference_dto.dart';
import '../../adapters/dtos/region_dto.dart';
import '../../domain/entities/notification_preference_entity.dart';
import '../../domain/entities/region_entity.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/i_storage_repository.dart';
import '../config/bmkg_api_config.dart';

/// Persists active region, favorite regions, alert preferences, and weather cache via SharedPreferences.
class SharedPrefsStorageRepository implements IStorageRepository {
  final SharedPreferences _prefs;
  final BmkgApiConfig _config;

  static const String _activeRegionKey = 'uas_active_region_v1';
  static const String _favoritesKey = 'uas_favorite_regions_v1';
  static const String _notifPrefsKey = 'uas_notification_prefs_v1';
  static const String _notifiedIdsKey = 'uas_notified_alert_ids_v1';
  static const String _weatherCachePrefix = 'uas_weather_cache_v1_';

  const SharedPrefsStorageRepository({
    required this._prefs,
    required this._config,
  });

  @override
  Future<RegionEntity?> loadActiveRegion() async {
    final raw = _prefs.getString(_activeRegionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final region = RegionDto.fromMap(decoded);
      return region.adm4.isEmpty ? null : region;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveActiveRegion(RegionEntity region) async {
    await _prefs.setString(
      _activeRegionKey,
      json.encode(RegionDto.toMap(region)),
    );
  }

  @override
  Future<List<RegionEntity>> loadFavoriteRegions() async {
    final raw = _prefs.getString(_favoritesKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(RegionDto.fromMap)
          .where((region) => region.adm4.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> saveFavoriteRegions(List<RegionEntity> regions) async {
    final payload = regions.map(RegionDto.toMap).toList();
    await _prefs.setString(_favoritesKey, json.encode(payload));
  }

  @override
  Future<NotificationPreferenceEntity> loadNotificationPreferences() async {
    final raw = _prefs.getString(_notifPrefsKey);
    if (raw == null || raw.isEmpty) {
      return const NotificationPreferenceEntity();
    }
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return NotificationPreferenceDto.fromMap(decoded);
    } catch (_) {
      return const NotificationPreferenceEntity();
    }
  }

  @override
  Future<void> saveNotificationPreferences(
    NotificationPreferenceEntity prefs,
  ) async {
    await _prefs.setString(
      _notifPrefsKey,
      json.encode(NotificationPreferenceDto.toMap(prefs)),
    );
  }

  @override
  Future<WeatherForecastEntity?> loadWeatherCache(String adm4) async {
    final raw = _prefs.getString('$_weatherCachePrefix$adm4');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return BmkgWeatherDto.fromCacheJson(
        decoded,
        defaultAttribution: _config.bmkgAttribution,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveWeatherCache(
    String adm4,
    WeatherForecastEntity forecast,
  ) async {
    final payload = BmkgWeatherDto.toCacheJson(forecast);
    await _prefs.setString(
      '$_weatherCachePrefix$adm4',
      json.encode(payload),
    );
  }

  @override
  Future<bool> hasNotifiedAlert(String alertId) async {
    final ids = _prefs.getStringList(_notifiedIdsKey) ?? const [];
    return ids.toSet().contains(alertId);
  }

  @override
  Future<void> markAlertNotified(String alertId) async {
    final current = (_prefs.getStringList(_notifiedIdsKey) ?? const []).toList();
    if (current.contains(alertId)) return;
    current.add(alertId);
    // Keep bounded history to prevent unbounded preference growth.
    if (current.length > 50) {
      current.removeRange(0, current.length - 50);
    }
    await _prefs.setStringList(_notifiedIdsKey, current);
  }
}
