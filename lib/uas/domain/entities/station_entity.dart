/// BMKG observation station with live meteorological telemetry linked by adm4.
class BmkgStationEntity {
  final String id;
  final String name;
  final String type;
  final String adm4;
  final String locationLabel;
  final double latitude;
  final double longitude;
  final String elevation;
  final double? liveTempC;
  final String liveCondition;
  final int? liveWeatherCode;
  final int? liveHumidity;
  final int? latencyMs;
  final bool isOnline;
  final DateTime? lastUpdated;

  const BmkgStationEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.adm4,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    required this.elevation,
    this.liveTempC,
    this.liveCondition = 'Menunggu sinkronisasi BMKG',
    this.liveWeatherCode,
    this.liveHumidity,
    this.latencyMs,
    this.isOnline = false,
    this.lastUpdated,
  });

  BmkgStationEntity copyWith({
    double? liveTempC,
    String? liveCondition,
    int? liveWeatherCode,
    int? liveHumidity,
    int? latencyMs,
    bool? isOnline,
    DateTime? lastUpdated,
  }) {
    return BmkgStationEntity(
      id: id,
      name: name,
      type: type,
      adm4: adm4,
      locationLabel: locationLabel,
      latitude: latitude,
      longitude: longitude,
      elevation: elevation,
      liveTempC: liveTempC ?? this.liveTempC,
      liveCondition: liveCondition ?? this.liveCondition,
      liveWeatherCode: liveWeatherCode ?? this.liveWeatherCode,
      liveHumidity: liveHumidity ?? this.liveHumidity,
      latencyMs: latencyMs ?? this.latencyMs,
      isOnline: isOnline ?? this.isOnline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
