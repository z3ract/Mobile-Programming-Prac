import '../../domain/entities/notification_preference_entity.dart';

/// Storage/adapter DTO for persisting NotificationPreferenceEntity safely.
class NotificationPreferenceDto {
  static Map<String, dynamic> toMap(NotificationPreferenceEntity prefs) {
    return {
      'enableRainAlert': prefs.enableRainAlert,
      'enableHeatAlert': prefs.enableHeatAlert,
      'enableNowcastAlert': prefs.enableNowcastAlert,
      'enableEarthquakeAlert': prefs.enableEarthquakeAlert,
      'earthquakeMinMagnitude': prefs.earthquakeMinMagnitude,
      'heatThresholdC': prefs.heatThresholdC,
    };
  }

  static NotificationPreferenceEntity fromMap(Map<String, dynamic> map) {
    return NotificationPreferenceEntity(
      enableRainAlert: map['enableRainAlert'] != false,
      enableHeatAlert: map['enableHeatAlert'] != false,
      enableNowcastAlert: map['enableNowcastAlert'] != false,
      enableEarthquakeAlert: map['enableEarthquakeAlert'] != false,
      earthquakeMinMagnitude:
          (map['earthquakeMinMagnitude'] as num?)?.toDouble() ?? 5.0,
      heatThresholdC: (map['heatThresholdC'] as num?)?.toDouble() ?? 33.0,
    );
  }
}
