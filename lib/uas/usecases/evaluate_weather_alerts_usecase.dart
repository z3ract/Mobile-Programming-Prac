import '../domain/entities/earthquake_entity.dart';
import '../domain/entities/notification_preference_entity.dart';
import '../domain/entities/nowcast_alert_entity.dart';
import '../domain/entities/region_entity.dart';
import '../domain/entities/weather_entity.dart';
import '../domain/repositories/i_storage_repository.dart';
import '../domain/services/i_notification_dispatcher.dart';
import '../domain/strategies/weather_advisory_strategy.dart';
import '../domain/utils/meteorology_calculator.dart';

/// Evaluates BMKG weather, nowcast warnings, and earthquakes to trigger deduplicated OS alerts.
class EvaluateWeatherAlertsUseCase {
  final IStorageRepository _storageRepository;
  final INotificationDispatcher _notificationDispatcher;

  const EvaluateWeatherAlertsUseCase({
    required this._storageRepository,
    required this._notificationDispatcher,
  });

  Future<List<AlertEvaluationEntity>> execute({
    required RegionEntity region,
    required WeatherForecastEntity? forecast,
    required List<NowcastRssItemEntity> nowcasts,
    required EarthquakeEntity? latestQuake,
    required NotificationPreferenceEntity preferences,
    bool dispatchOsNotifications = true,
  }) async {
    final List<AlertEvaluationEntity> alerts = [];
    final DateTime now = DateTime.now();

    _evaluateNowcasts(
      alerts: alerts,
      region: region,
      nowcasts: nowcasts,
      now: now,
    );

    if (forecast != null) {
      _evaluateWeatherSlot(
        alerts: alerts,
        region: region,
        forecast: forecast,
        preferences: preferences,
        now: now,
      );
    }

    if (latestQuake != null) {
      _evaluateEarthquake(
        alerts: alerts,
        region: region,
        quake: latestQuake,
        preferences: preferences,
        now: now,
      );
    }

    if (dispatchOsNotifications) {
      await _dispatchEnabledNotifications(
        alerts: alerts,
        preferences: preferences,
      );
    }

    return alerts;
  }

  void _evaluateNowcasts({
    required List<AlertEvaluationEntity> alerts,
    required RegionEntity region,
    required List<NowcastRssItemEntity> nowcasts,
    required DateTime now,
  }) {
    final normalizedProvince = _normalizeProvince(region.provinsi);
    if (normalizedProvince.isEmpty) return;

    for (final item in nowcasts) {
      final itemProv = _normalizeProvince(item.provinceName);
      final itemTitle = _normalizeProvince(item.title);
      final matches = itemProv.contains(normalizedProvince) ||
          normalizedProvince.contains(itemProv) ||
          itemTitle.contains(normalizedProvince);
      if (!matches) continue;

      alerts.add(
        AlertEvaluationEntity(
          id: 'nowcast_${item.id}',
          category: AlertCategory.nowcast,
          severity: AlertSeverity.danger,
          title: item.title,
          message: item.description,
          advice:
              'Peringatan dini cuaca resmi BMKG aktif di provinsi ${region.provinsi}. Pantau detail area terdampak.',
          timestamp: now,
          isOfficialBmkg: true,
          detailUrl: item.detailUrl,
        ),
      );
    }
  }

  void _evaluateWeatherSlot({
    required List<AlertEvaluationEntity> alerts,
    required RegionEntity region,
    required WeatherForecastEntity forecast,
    required NotificationPreferenceEntity preferences,
    required DateTime now,
  }) {
    final slot = forecast.current;
    final policy = WeatherCodeRegistry.resolvePolicy(
      slot.weatherCode,
      fallbackDesc: slot.weatherDesc,
    );

    if (policy.isRainHazard) {
      alerts.add(
        AlertEvaluationEntity(
          id: 'rain_${region.adm4}_${slot.timeLabel}_${slot.weatherCode}',
          category: AlertCategory.rain,
          severity: policy.severity,
          title: '${policy.shortLabel} di ${region.displayTitle}',
          message:
              '${slot.weatherDesc} (${slot.tempC.round()}°C, kelembapan ${slot.humidity}%, curah hujan ${slot.precipitationMm.toStringAsFixed(1)} mm).',
          advice: policy.activityRecommendation,
          timestamp: now,
        ),
      );
    }

    if (slot.tempC >= preferences.heatThresholdC) {
      alerts.add(
        AlertEvaluationEntity(
          id: 'heat_${region.adm4}_${slot.timeLabel}_${slot.tempC.round()}',
          category: AlertCategory.heat,
          severity: AlertSeverity.warning,
          title: 'Suhu Panas ${slot.tempC.round()}°C di ${region.displayTitle}',
          message:
              'Suhu udara melampaui ambang batas ${preferences.heatThresholdC.toStringAsFixed(0)}°C (terasa seperti ${forecast.feelsLikeC.round()}°C).',
          advice:
              'Perbanyak minum air putih, hindari paparan matahari langsung terlalu lama, dan gunakan tabir surya.',
          timestamp: now,
        ),
      );
    }

    if (slot.visibilityMeters > 0 && slot.visibilityMeters < 3000) {
      alerts.add(
        AlertEvaluationEntity(
          id: 'vis_${region.adm4}_${slot.timeLabel}_${slot.visibilityMeters}',
          category: AlertCategory.visibility,
          severity: AlertSeverity.advisory,
          title: 'Jarak Pandang Terbatas (${slot.visibilityText})',
          message:
              'Visibilitas di ${region.displayTitle} menurun akibat ${slot.weatherDesc.toLowerCase()}.',
          advice:
              'Berhati-hati saat berkendara dan pastikan pencahayaan kendaraan berfungsi optimal.',
          timestamp: now,
        ),
      );
    }
  }

  void _evaluateEarthquake({
    required List<AlertEvaluationEntity> alerts,
    required RegionEntity region,
    required EarthquakeEntity quake,
    required NotificationPreferenceEntity preferences,
    required DateTime now,
  }) {
    if (quake.magnitudeValue < preferences.earthquakeMinMagnitude) return;

    String distanceText = '';
    final lat = quake.latitude;
    final lon = quake.longitude;
    if (lat != null && lon != null) {
      final km = MeteorologyCalculator.calculateDistanceKm(
        region.latitude,
        region.longitude,
        lat,
        lon,
      );
      distanceText =
          ' (~${MeteorologyCalculator.formatDistance(km)} dari ${region.displayTitle})';
    }

    alerts.add(
      AlertEvaluationEntity(
        id: 'quake_${quake.uniqueKey}',
        category: AlertCategory.earthquake,
        severity: quake.magnitudeValue >= 6.0 || quake.hasTsunamiPotential
            ? AlertSeverity.danger
            : AlertSeverity.warning,
        title: 'Gempa BMKG M ${quake.magnitude} SR',
        message: '${quake.wilayah}$distanceText • ${quake.jam}.',
        advice: quake.potensi,
        timestamp: now,
        isOfficialBmkg: true,
      ),
    );
  }

  Future<void> _dispatchEnabledNotifications({
    required List<AlertEvaluationEntity> alerts,
    required NotificationPreferenceEntity preferences,
  }) async {
    final Map<AlertCategory, bool> categoryEnabledMap = {
      AlertCategory.nowcast: preferences.enableNowcastAlert,
      AlertCategory.rain: preferences.enableRainAlert,
      AlertCategory.heat: preferences.enableHeatAlert,
      AlertCategory.earthquake: preferences.enableEarthquakeAlert,
      AlertCategory.visibility:
          preferences.enableRainAlert || preferences.enableNowcastAlert,
    };

    for (final alert in alerts) {
      final isEnabled = categoryEnabledMap[alert.category] ?? false;
      if (!isEnabled) continue;

      final alreadyNotified =
          await _storageRepository.hasNotifiedAlert(alert.id);
      if (alreadyNotified) continue;

      await _notificationDispatcher.dispatchAlert(alert);
      await _storageRepository.markAlertNotified(alert.id);
    }
  }

  String _normalizeProvince(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('daerah khusus ibukota', 'dki')
        .replaceAll('daerah istimewa', 'di')
        .replaceAll('provinsi', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
