import '../utils/meteorology_calculator.dart';
import 'region_entity.dart';

/// A single 3-hour forecast slot returned by BMKG public weather API.
class WeatherSlotEntity {
  final DateTime localDateTime;
  final DateTime utcDateTime;
  final String timeLabel;
  final double tempC;
  final int humidity;
  final int cloudCoverPct;
  final double precipitationMm;
  final int weatherCode;
  final String weatherDesc;
  final String weatherDescEn;
  final double windSpeedKm;
  final String windDirection;
  final String windDirectionTo;
  final int windDegree;
  final int visibilityMeters;
  final String visibilityText;
  final String analysisDate;

  const WeatherSlotEntity({
    required this.localDateTime,
    required this.utcDateTime,
    required this.timeLabel,
    required this.tempC,
    required this.humidity,
    required this.cloudCoverPct,
    required this.precipitationMm,
    required this.weatherCode,
    required this.weatherDesc,
    required this.weatherDescEn,
    required this.windSpeedKm,
    required this.windDirection,
    required this.windDirectionTo,
    required this.windDegree,
    required this.visibilityMeters,
    required this.visibilityText,
    required this.analysisDate,
  });

  bool get isNightTime => localDateTime.hour >= 18 || localDateTime.hour < 6;
}

/// Daily aggregated summary derived from BMKG's 3-hour weather forecast slots.
class DailyWeatherSummaryEntity {
  final String dateKey;
  final String dayLabel;
  final int dominantWeatherCode;
  final String dominantCondition;
  final double minTempC;
  final double maxTempC;
  final int avgHumidity;
  final double totalPrecipitationMm;
  final double? currentTempC;

  const DailyWeatherSummaryEntity({
    required this.dateKey,
    required this.dayLabel,
    required this.dominantWeatherCode,
    required this.dominantCondition,
    required this.minTempC,
    required this.maxTempC,
    required this.avgHumidity,
    required this.totalPrecipitationMm,
    this.currentTempC,
  });
}

/// Full weather forecast entity for an Indonesian adm4 village/kelurahan.
class WeatherForecastEntity {
  final RegionEntity region;
  final WeatherSlotEntity current;
  final List<WeatherSlotEntity> slots;
  final List<DailyWeatherSummaryEntity> daily;
  final DateTime fetchedAt;
  final bool fromCache;
  final String sourceAttribution;

  const WeatherForecastEntity({
    required this.region,
    required this.current,
    required this.slots,
    required this.daily,
    required this.fetchedAt,
    this.fromCache = false,
    required this.sourceAttribution,
  });

  double get tempMaxTodayC =>
      daily.isNotEmpty ? daily.first.maxTempC : current.tempC;

  double get tempMinTodayC =>
      daily.isNotEmpty ? daily.first.minTempC : current.tempC;

  double get feelsLikeC => MeteorologyCalculator.calculateFeelsLikeC(
        current.tempC,
        current.humidity,
      );

  double get dewPointC => MeteorologyCalculator.calculateDewPointC(
        current.tempC,
        current.humidity,
      );

  WeatherForecastEntity copyWith({
    RegionEntity? region,
    WeatherSlotEntity? current,
    List<WeatherSlotEntity>? slots,
    List<DailyWeatherSummaryEntity>? daily,
    DateTime? fetchedAt,
    bool? fromCache,
    String? sourceAttribution,
  }) {
    return WeatherForecastEntity(
      region: region ?? this.region,
      current: current ?? this.current,
      slots: slots ?? this.slots,
      daily: daily ?? this.daily,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      fromCache: fromCache ?? this.fromCache,
      sourceAttribution: sourceAttribution ?? this.sourceAttribution,
    );
  }
}
