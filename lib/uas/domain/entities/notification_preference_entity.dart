/// Severity hierarchy for weather, seismic, and BMKG nowcast notifications.
enum AlertSeverity { info, advisory, warning, danger }

/// Domain categories for evaluated alerts and user notification filters.
enum AlertCategory { rain, heat, nowcast, earthquake, visibility }

/// User-configurable alert thresholds and notification preferences.
class NotificationPreferenceEntity {
  final bool enableRainAlert;
  final bool enableHeatAlert;
  final bool enableNowcastAlert;
  final bool enableEarthquakeAlert;
  final double earthquakeMinMagnitude;
  final double heatThresholdC;

  const NotificationPreferenceEntity({
    this.enableRainAlert = true,
    this.enableHeatAlert = true,
    this.enableNowcastAlert = true,
    this.enableEarthquakeAlert = true,
    this.earthquakeMinMagnitude = 5.0,
    this.heatThresholdC = 33.0,
  });

  NotificationPreferenceEntity copyWith({
    bool? enableRainAlert,
    bool? enableHeatAlert,
    bool? enableNowcastAlert,
    bool? enableEarthquakeAlert,
    double? earthquakeMinMagnitude,
    double? heatThresholdC,
  }) {
    return NotificationPreferenceEntity(
      enableRainAlert: enableRainAlert ?? this.enableRainAlert,
      enableHeatAlert: enableHeatAlert ?? this.enableHeatAlert,
      enableNowcastAlert: enableNowcastAlert ?? this.enableNowcastAlert,
      enableEarthquakeAlert:
          enableEarthquakeAlert ?? this.enableEarthquakeAlert,
      earthquakeMinMagnitude:
          earthquakeMinMagnitude ?? this.earthquakeMinMagnitude,
      heatThresholdC: heatThresholdC ?? this.heatThresholdC,
    );
  }
}

/// Evaluated environmental or seismic alert ready for UI presentation and OS push.
class AlertEvaluationEntity {
  final String id;
  final AlertCategory category;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String advice;
  final DateTime timestamp;
  final bool isOfficialBmkg;
  final String? detailUrl;

  const AlertEvaluationEntity({
    required this.id,
    required this.category,
    required this.severity,
    required this.title,
    required this.message,
    required this.advice,
    required this.timestamp,
    this.isOfficialBmkg = false,
    this.detailUrl,
  });
}
