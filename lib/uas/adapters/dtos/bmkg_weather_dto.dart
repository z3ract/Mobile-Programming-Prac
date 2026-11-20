import '../../domain/entities/region_entity.dart';
import '../../domain/entities/weather_entity.dart';
import 'region_dto.dart';

/// Adapter DTO converting BMKG public weather forecast JSON and local cache JSON
/// into pure WeatherForecastEntity instances.
class BmkgWeatherDto {
  static const Map<int, String> _weekdayNames = {
    DateTime.monday: 'Sen',
    DateTime.tuesday: 'Sel',
    DateTime.wednesday: 'Rab',
    DateTime.thursday: 'Kam',
    DateTime.friday: 'Jum',
    DateTime.saturday: 'Sab',
    DateTime.sunday: 'Min',
  };

  static const Map<int, String> _monthNames = {
    1: 'Jan',
    2: 'Feb',
    3: 'Mar',
    4: 'Apr',
    5: 'Mei',
    6: 'Jun',
    7: 'Jul',
    8: 'Agu',
    9: 'Sep',
    10: 'Okt',
    11: 'Nov',
    12: 'Des',
  };

  static WeatherForecastEntity fromBmkgJson(
    Map<String, dynamic> json, {
    required RegionEntity fallbackRegion,
    required String sourceAttribution,
    DateTime? referenceTime,
  }) {
    final dataList = json['data'] as List<dynamic>? ?? const [];
    final firstEntry = dataList.isNotEmpty && dataList.first is Map<String, dynamic>
        ? dataList.first as Map<String, dynamic>
        : <String, dynamic>{};

    final rootLokasi = json['lokasi'] as Map<String, dynamic>?;
    final entryLokasi = firstEntry['lokasi'] as Map<String, dynamic>?;
    final mergedLokasi = <String, dynamic>{
      ...?rootLokasi,
      ...?entryLokasi,
    };

    final region = _parseRegion(mergedLokasi, fallbackRegion);
    final rawCuaca = firstEntry['cuaca'] as List<dynamic>? ?? const [];
    final List<WeatherSlotEntity> slots = _flattenSlots(rawCuaca);

    if (slots.isEmpty) {
      throw const FormatException(
        'BMKG weather response did not contain any forecast slots.',
      );
    }

    slots.sort((a, b) => a.localDateTime.compareTo(b.localDateTime));
    final now = referenceTime ?? DateTime.now();
    final currentSlot = _selectClosestSlot(slots, now);
    final dailySummaries = _buildDailySummaries(slots, currentSlot);

    return WeatherForecastEntity(
      region: region,
      current: currentSlot,
      slots: slots,
      daily: dailySummaries,
      fetchedAt: now,
      fromCache: false,
      sourceAttribution: sourceAttribution,
    );
  }

  static Map<String, dynamic> toCacheJson(WeatherForecastEntity entity) {
    return {
      'region': RegionDto.toMap(entity.region),
      'current': _slotToMap(entity.current),
      'slots': entity.slots.map(_slotToMap).toList(),
      'daily': entity.daily.map(_dailyToMap).toList(),
      'fetchedAt': entity.fetchedAt.toIso8601String(),
      'sourceAttribution': entity.sourceAttribution,
    };
  }

  static WeatherForecastEntity fromCacheJson(
    Map<String, dynamic> map, {
    required String defaultAttribution,
  }) {
    final regionMap = map['region'] as Map<String, dynamic>? ?? const {};
    final currentMap = map['current'] as Map<String, dynamic>? ?? const {};
    final rawSlots = map['slots'] as List<dynamic>? ?? const [];
    final rawDaily = map['daily'] as List<dynamic>? ?? const [];

    final slots = rawSlots
        .whereType<Map<String, dynamic>>()
        .map(_slotFromMap)
        .toList();
    final daily = rawDaily
        .whereType<Map<String, dynamic>>()
        .map(_dailyFromMap)
        .toList();

    return WeatherForecastEntity(
      region: RegionDto.fromMap(regionMap),
      current: _slotFromMap(currentMap),
      slots: slots,
      daily: daily,
      fetchedAt:
          DateTime.tryParse(map['fetchedAt']?.toString() ?? '') ?? DateTime.now(),
      fromCache: true,
      sourceAttribution:
          map['sourceAttribution']?.toString() ?? defaultAttribution,
    );
  }

  static RegionEntity _parseRegion(
    Map<String, dynamic> lokasi,
    RegionEntity fallback,
  ) {
    if (lokasi.isEmpty) return fallback;

    final lat = _toDouble(lokasi['lat'], fallback.latitude);
    final lon = _toDouble(lokasi['lon'], fallback.longitude);

    return RegionEntity(
      adm1: _nonEmpty(lokasi['adm1'], fallback.adm1),
      adm2: _nonEmpty(lokasi['adm2'], fallback.adm2),
      adm3: _nonEmpty(lokasi['adm3'], fallback.adm3),
      adm4: _nonEmpty(lokasi['adm4'], fallback.adm4),
      provinsi: _nonEmpty(lokasi['provinsi'], fallback.provinsi),
      kotkab: _nonEmpty(lokasi['kotkab'], fallback.kotkab),
      kecamatan: _nonEmpty(lokasi['kecamatan'], fallback.kecamatan),
      desa: _nonEmpty(lokasi['desa'], fallback.desa),
      latitude: fallback.isGpsResolved ? fallback.latitude : lat,
      longitude: fallback.isGpsResolved ? fallback.longitude : lon,
      timezone: _nonEmpty(lokasi['timezone'], fallback.timezone),
      isGpsResolved: fallback.isGpsResolved,
    );
  }

  static List<WeatherSlotEntity> _flattenSlots(List<dynamic> rawCuaca) {
    final List<WeatherSlotEntity> result = [];
    for (final entry in rawCuaca) {
      if (entry is List<dynamic>) {
        for (final item in entry) {
          if (item is Map<String, dynamic>) {
            result.add(_parseSlot(item));
          }
        }
      } else if (entry is Map<String, dynamic>) {
        result.add(_parseSlot(entry));
      }
    }
    return result;
  }

  static WeatherSlotEntity _parseSlot(Map<String, dynamic> item) {
    final localRaw = item['local_datetime']?.toString() ?? '';
    final utcRaw =
        item['utc_datetime']?.toString() ?? item['datetime']?.toString() ?? '';
    final localDt = _parseDateTime(localRaw) ?? DateTime.now();
    final utcDt = _parseDateTime(utcRaw, assumeUtc: true) ?? localDt.toUtc();

    final hour = localDt.hour.toString().padLeft(2, '0');
    final minute = localDt.minute.toString().padLeft(2, '0');

    return WeatherSlotEntity(
      localDateTime: localDt,
      utcDateTime: utcDt,
      timeLabel: '$hour:$minute',
      tempC: _toDouble(item['t'], 27.0),
      humidity: _toInt(item['hu'], 75),
      cloudCoverPct: _toInt(item['tcc'], 50),
      precipitationMm: _toDouble(item['tp'], 0.0),
      weatherCode: _toInt(item['weather'], 1),
      weatherDesc: _nonEmpty(item['weather_desc'], 'Cerah Berawan'),
      weatherDescEn: _nonEmpty(item['weather_desc_en'], 'Partly Cloudy'),
      windSpeedKm: _toDouble(item['ws'], 10.0),
      windDirection: _nonEmpty(item['wd'], 'N'),
      windDirectionTo: _nonEmpty(item['wd_to'], 'S'),
      windDegree: _toInt(item['wd_deg'], 0),
      visibilityMeters: _toInt(item['vs'], 10000),
      visibilityText: _nonEmpty(item['vs_text'], '10 km'),
      analysisDate: item['analysis_date']?.toString() ?? '',
    );
  }

  static WeatherSlotEntity _selectClosestSlot(
    List<WeatherSlotEntity> slots,
    DateTime referenceTime,
  ) {
    WeatherSlotEntity best = slots.first;
    Duration bestDelta = best.localDateTime.difference(referenceTime).abs();

    for (final slot in slots.skip(1)) {
      final delta = slot.localDateTime.difference(referenceTime).abs();
      if (delta < bestDelta) {
        best = slot;
        bestDelta = delta;
      }
    }
    return best;
  }

  static List<DailyWeatherSummaryEntity> _buildDailySummaries(
    List<WeatherSlotEntity> slots,
    WeatherSlotEntity currentSlot,
  ) {
    final Map<String, List<WeatherSlotEntity>> grouped = {};
    for (final slot in slots) {
      final dt = slot.localDateTime;
      final key =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(slot);
    }

    final List<DailyWeatherSummaryEntity> summaries = [];
    int index = 0;
    for (final entry in grouped.entries) {
      final daySlots = entry.value;
      double minTemp = daySlots.first.tempC;
      double maxTemp = daySlots.first.tempC;
      int humiditySum = 0;
      double totalRain = 0.0;

      WeatherSlotEntity dominant = daySlots.first;
      int bestNoonDiff = (dominant.localDateTime.hour - 12).abs();

      for (final slot in daySlots) {
        if (slot.tempC < minTemp) minTemp = slot.tempC;
        if (slot.tempC > maxTemp) maxTemp = slot.tempC;
        humiditySum += slot.humidity;
        totalRain += slot.precipitationMm;

        final noonDiff = (slot.localDateTime.hour - 12).abs();
        if (noonDiff < bestNoonDiff) {
          dominant = slot;
          bestNoonDiff = noonDiff;
        }
      }

      final date = daySlots.first.localDateTime;
      final dayLabel = index == 0
          ? 'Hari ini'
          : '${_weekdayNames[date.weekday] ?? 'Hari'}, ${date.day} ${_monthNames[date.month] ?? ''}';

      summaries.add(
        DailyWeatherSummaryEntity(
          dateKey: entry.key,
          dayLabel: dayLabel,
          dominantWeatherCode: dominant.weatherCode,
          dominantCondition: dominant.weatherDesc,
          minTempC: minTemp,
          maxTempC: maxTemp,
          avgHumidity: (humiditySum / daySlots.length).round(),
          totalPrecipitationMm: totalRain,
          currentTempC: index == 0 ? currentSlot.tempC : null,
        ),
      );
      index++;
    }

    return summaries;
  }

  static Map<String, dynamic> _slotToMap(WeatherSlotEntity slot) {
    return {
      'localDateTime': slot.localDateTime.toIso8601String(),
      'utcDateTime': slot.utcDateTime.toIso8601String(),
      'timeLabel': slot.timeLabel,
      'tempC': slot.tempC,
      'humidity': slot.humidity,
      'cloudCoverPct': slot.cloudCoverPct,
      'precipitationMm': slot.precipitationMm,
      'weatherCode': slot.weatherCode,
      'weatherDesc': slot.weatherDesc,
      'weatherDescEn': slot.weatherDescEn,
      'windSpeedKm': slot.windSpeedKm,
      'windDirection': slot.windDirection,
      'windDirectionTo': slot.windDirectionTo,
      'windDegree': slot.windDegree,
      'visibilityMeters': slot.visibilityMeters,
      'visibilityText': slot.visibilityText,
      'analysisDate': slot.analysisDate,
    };
  }

  static WeatherSlotEntity _slotFromMap(Map<String, dynamic> map) {
    return WeatherSlotEntity(
      localDateTime:
          DateTime.tryParse(map['localDateTime']?.toString() ?? '') ??
              DateTime.now(),
      utcDateTime:
          DateTime.tryParse(map['utcDateTime']?.toString() ?? '') ??
              DateTime.now().toUtc(),
      timeLabel: map['timeLabel']?.toString() ?? '12:00',
      tempC: _toDouble(map['tempC'], 27.0),
      humidity: _toInt(map['humidity'], 75),
      cloudCoverPct: _toInt(map['cloudCoverPct'], 50),
      precipitationMm: _toDouble(map['precipitationMm'], 0.0),
      weatherCode: _toInt(map['weatherCode'], 1),
      weatherDesc: _nonEmpty(map['weatherDesc'], 'Cerah Berawan'),
      weatherDescEn: _nonEmpty(map['weatherDescEn'], 'Partly Cloudy'),
      windSpeedKm: _toDouble(map['windSpeedKm'], 10.0),
      windDirection: _nonEmpty(map['windDirection'], 'N'),
      windDirectionTo: _nonEmpty(map['windDirectionTo'], 'S'),
      windDegree: _toInt(map['windDegree'], 0),
      visibilityMeters: _toInt(map['visibilityMeters'], 10000),
      visibilityText: _nonEmpty(map['visibilityText'], '10 km'),
      analysisDate: map['analysisDate']?.toString() ?? '',
    );
  }

  static Map<String, dynamic> _dailyToMap(DailyWeatherSummaryEntity daily) {
    return {
      'dateKey': daily.dateKey,
      'dayLabel': daily.dayLabel,
      'dominantWeatherCode': daily.dominantWeatherCode,
      'dominantCondition': daily.dominantCondition,
      'minTempC': daily.minTempC,
      'maxTempC': daily.maxTempC,
      'avgHumidity': daily.avgHumidity,
      'totalPrecipitationMm': daily.totalPrecipitationMm,
      'currentTempC': daily.currentTempC,
    };
  }

  static DailyWeatherSummaryEntity _dailyFromMap(Map<String, dynamic> map) {
    return DailyWeatherSummaryEntity(
      dateKey: map['dateKey']?.toString() ?? '',
      dayLabel: map['dayLabel']?.toString() ?? 'Hari ini',
      dominantWeatherCode: _toInt(map['dominantWeatherCode'], 1),
      dominantCondition:
          _nonEmpty(map['dominantCondition'], 'Cerah Berawan'),
      minTempC: _toDouble(map['minTempC'], 24.0),
      maxTempC: _toDouble(map['maxTempC'], 32.0),
      avgHumidity: _toInt(map['avgHumidity'], 75),
      totalPrecipitationMm: _toDouble(map['totalPrecipitationMm'], 0.0),
      currentTempC: (map['currentTempC'] as num?)?.toDouble(),
    );
  }

  static DateTime? _parseDateTime(String raw, {bool assumeUtc = false}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final isoLike = trimmed.contains('T')
        ? trimmed
        : trimmed.replaceFirst(' ', 'T');
    final finalStr =
        assumeUtc && !isoLike.endsWith('Z') && !isoLike.contains('+')
            ? '${isoLike}Z'
            : isoLike;
    return DateTime.tryParse(finalStr);
  }

  static double _toDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ??
        double.tryParse(value?.toString() ?? '')?.round() ??
        fallback;
  }

  static String _nonEmpty(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
