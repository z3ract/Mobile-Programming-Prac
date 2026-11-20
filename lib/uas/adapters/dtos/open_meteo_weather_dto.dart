import '../../domain/entities/region_entity.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/utils/meteorology_calculator.dart';

/// Adapter DTO converting Open-Meteo forecast JSON payloads into pure
/// WeatherForecastEntity instances for both Indonesian and global locations.
class OpenMeteoWeatherDto {
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

  static const Map<int, ({String id, String en})> _wmoDescriptions = {
    0: (id: 'Cerah', en: 'Clear Sky'),
    1: (id: 'Cerah Berawan', en: 'Mainly Clear'),
    2: (id: 'Berawan Sebagian', en: 'Partly Cloudy'),
    3: (id: 'Mendung', en: 'Overcast'),
    45: (id: 'Berkabut', en: 'Fog'),
    48: (id: 'Kabut Tebal', en: 'Depositing Rime Fog'),
    51: (id: 'Gerimis Ringan', en: 'Light Drizzle'),
    53: (id: 'Gerimis Sedang', en: 'Moderate Drizzle'),
    55: (id: 'Gerimis Lebat', en: 'Dense Drizzle'),
    56: (id: 'Gerimis Beku Ringan', en: 'Light Freezing Drizzle'),
    57: (id: 'Gerimis Beku Lebat', en: 'Dense Freezing Drizzle'),
    61: (id: 'Hujan Ringan', en: 'Slight Rain'),
    63: (id: 'Hujan Sedang', en: 'Moderate Rain'),
    65: (id: 'Hujan Lebat', en: 'Heavy Rain'),
    66: (id: 'Hujan Beku Ringan', en: 'Light Freezing Rain'),
    67: (id: 'Hujan Beku Lebat', en: 'Heavy Freezing Rain'),
    71: (id: 'Salju Ringan', en: 'Slight Snowfall'),
    73: (id: 'Salju Sedang', en: 'Moderate Snowfall'),
    75: (id: 'Salju Lebat', en: 'Heavy Snowfall'),
    77: (id: 'Butiran Salju', en: 'Snow Grains'),
    80: (id: 'Hujan Lokal Ringan', en: 'Slight Rain Showers'),
    81: (id: 'Hujan Lokal Sedang', en: 'Moderate Rain Showers'),
    82: (id: 'Hujan Lokal Deras', en: 'Violent Rain Showers'),
    85: (id: 'Hujan Salju Ringan', en: 'Slight Snow Showers'),
    86: (id: 'Hujan Salju Lebat', en: 'Heavy Snow Showers'),
    95: (id: 'Hujan Petir', en: 'Thunderstorm'),
    96: (id: 'Badai Petir & Es', en: 'Thunderstorm with Hail'),
    99: (id: 'Badai Petir Ekstrem', en: 'Thunderstorm with Heavy Hail'),
  };

  static WeatherForecastEntity fromOpenMeteoJson(
    Map<String, dynamic> json, {
    required RegionEntity region,
    required String sourceAttribution,
    DateTime? referenceTime,
  }) {
    final resolvedTimezone =
        _nonEmpty(json['timezone'], region.timezone);
    final int utcOffsetSeconds =
        (json['utc_offset_seconds'] as num?)?.toInt() ?? 0;

    final hourlyMap = json['hourly'] as Map<String, dynamic>? ?? const {};
    final hourlyTimes = hourlyMap['time'] as List<dynamic>? ?? const [];
    if (hourlyTimes.isEmpty) {
      throw const FormatException(
        'Open-Meteo weather response did not contain any hourly slots.',
      );
    }

    final List<WeatherSlotEntity> allHourlySlots = _parseHourlySlots(
      hourlyMap,
      utcOffsetSeconds: utcOffsetSeconds,
    );
    if (allHourlySlots.isEmpty) {
      throw const FormatException(
        'Open-Meteo hourly array could not be parsed.',
      );
    }

    final currentMap = json['current'] as Map<String, dynamic>?;
    final WeatherSlotEntity currentSlot = _parseCurrentSlot(
      currentMap: currentMap,
      allHourlySlots: allHourlySlots,
      utcOffsetSeconds: utcOffsetSeconds,
      referenceTime: referenceTime,
    );

    final DateTime floorHour = DateTime(
      currentSlot.localDateTime.year,
      currentSlot.localDateTime.month,
      currentSlot.localDateTime.day,
      currentSlot.localDateTime.hour,
    );
    final upcoming = allHourlySlots
        .where((s) => !s.localDateTime.isBefore(floorHour))
        .take(24)
        .toList();
    final List<WeatherSlotEntity> selectedSlots =
        upcoming.isNotEmpty ? upcoming : allHourlySlots.take(24).toList();

    final dailyMap = json['daily'] as Map<String, dynamic>? ?? const {};
    final List<DailyWeatherSummaryEntity> dailySummaries = _parseDailySummaries(
      dailyMap: dailyMap,
      allHourlySlots: allHourlySlots,
      currentSlot: currentSlot,
    );

    return WeatherForecastEntity(
      region: region.copyWith(timezone: resolvedTimezone),
      current: currentSlot,
      slots: selectedSlots,
      daily: dailySummaries,
      fetchedAt: referenceTime ?? DateTime.now(),
      fromCache: false,
      sourceAttribution: sourceAttribution,
    );
  }

  static List<WeatherSlotEntity> _parseHourlySlots(
    Map<String, dynamic> hourly, {
    required int utcOffsetSeconds,
  }) {
    final times = hourly['time'] as List<dynamic>? ?? const [];
    final temps = hourly['temperature_2m'] as List<dynamic>? ?? const [];
    final humidities =
        hourly['relative_humidity_2m'] as List<dynamic>? ?? const [];
    final precips = hourly['precipitation'] as List<dynamic>? ?? const [];
    final codes = hourly['weather_code'] as List<dynamic>? ?? const [];
    final clouds = hourly['cloud_cover'] as List<dynamic>? ?? const [];
    final visibilities = hourly['visibility'] as List<dynamic>? ?? const [];
    final windSpeeds = hourly['wind_speed_10m'] as List<dynamic>? ?? const [];
    final windDirs =
        hourly['wind_direction_10m'] as List<dynamic>? ?? const [];

    final List<WeatherSlotEntity> result = [];
    for (int i = 0; i < times.length; i++) {
      final rawTime = times[i]?.toString() ?? '';
      final localDt = DateTime.tryParse(rawTime);
      if (localDt == null) continue;

      final utcDt = _toUtcWithOffset(localDt, utcOffsetSeconds);
      final code = _toInt(_elementAt(codes, i), 1);
      final desc = _describeWmo(code);
      final windDeg = _toInt(_elementAt(windDirs, i), 0);
      final visMeters = _toInt(_elementAt(visibilities, i), 10000);
      final timeLabel =
          '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}';

      result.add(
        WeatherSlotEntity(
          localDateTime: localDt,
          utcDateTime: utcDt,
          timeLabel: timeLabel,
          tempC: _toDouble(_elementAt(temps, i), 26.0),
          humidity: _toInt(_elementAt(humidities, i), 70),
          cloudCoverPct: _toInt(_elementAt(clouds, i), 40),
          precipitationMm: _toDouble(_elementAt(precips, i), 0.0),
          weatherCode: code,
          weatherDesc: desc.id,
          weatherDescEn: desc.en,
          windSpeedKm: _toDouble(_elementAt(windSpeeds, i), 10.0),
          windDirection: MeteorologyCalculator.degreeToWindCode(windDeg),
          windDirectionTo: MeteorologyCalculator.oppositeWindCode(windDeg),
          windDegree: windDeg,
          visibilityMeters: visMeters,
          visibilityText: _formatVisibility(visMeters),
          analysisDate: rawTime,
        ),
      );
    }
    return result;
  }

  static WeatherSlotEntity _parseCurrentSlot({
    required Map<String, dynamic>? currentMap,
    required List<WeatherSlotEntity> allHourlySlots,
    required int utcOffsetSeconds,
    DateTime? referenceTime,
  }) {
    if (currentMap == null || currentMap.isEmpty) {
      return _selectClosestSlot(
        allHourlySlots,
        referenceTime ?? DateTime.now(),
      );
    }

    final rawTime = currentMap['time']?.toString() ?? '';
    final localDt = DateTime.tryParse(rawTime) ??
        allHourlySlots.first.localDateTime;
    final closestHourly = _selectClosestSlot(allHourlySlots, localDt);
    final code = _toInt(currentMap['weather_code'], closestHourly.weatherCode);
    final desc = _describeWmo(code);
    final windDeg = _toInt(
      currentMap['wind_direction_10m'],
      closestHourly.windDegree,
    );
    final timeLabel =
        '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}';

    return WeatherSlotEntity(
      localDateTime: localDt,
      utcDateTime: _toUtcWithOffset(localDt, utcOffsetSeconds),
      timeLabel: timeLabel,
      tempC: _toDouble(currentMap['temperature_2m'], closestHourly.tempC),
      humidity: _toInt(
        currentMap['relative_humidity_2m'],
        closestHourly.humidity,
      ),
      cloudCoverPct: _toInt(
        currentMap['cloud_cover'],
        closestHourly.cloudCoverPct,
      ),
      precipitationMm: _toDouble(
        currentMap['precipitation'],
        closestHourly.precipitationMm,
      ),
      weatherCode: code,
      weatherDesc: desc.id,
      weatherDescEn: desc.en,
      windSpeedKm: _toDouble(
        currentMap['wind_speed_10m'],
        closestHourly.windSpeedKm,
      ),
      windDirection: MeteorologyCalculator.degreeToWindCode(windDeg),
      windDirectionTo: MeteorologyCalculator.oppositeWindCode(windDeg),
      windDegree: windDeg,
      visibilityMeters: closestHourly.visibilityMeters,
      visibilityText: closestHourly.visibilityText,
      analysisDate: rawTime.isEmpty ? closestHourly.analysisDate : rawTime,
    );
  }

  static List<DailyWeatherSummaryEntity> _parseDailySummaries({
    required Map<String, dynamic> dailyMap,
    required List<WeatherSlotEntity> allHourlySlots,
    required WeatherSlotEntity currentSlot,
  }) {
    final Map<String, List<int>> humidityByDate = {};
    for (final slot in allHourlySlots) {
      final dt = slot.localDateTime;
      final key =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      humidityByDate.putIfAbsent(key, () => []).add(slot.humidity);
    }

    final times = dailyMap['time'] as List<dynamic>? ?? const [];
    if (times.isEmpty) {
      return [
        DailyWeatherSummaryEntity(
          dateKey:
              '${currentSlot.localDateTime.year.toString().padLeft(4, '0')}-${currentSlot.localDateTime.month.toString().padLeft(2, '0')}-${currentSlot.localDateTime.day.toString().padLeft(2, '0')}',
          dayLabel: 'Hari ini',
          dominantWeatherCode: currentSlot.weatherCode,
          dominantCondition: currentSlot.weatherDesc,
          minTempC: currentSlot.tempC,
          maxTempC: currentSlot.tempC,
          avgHumidity: currentSlot.humidity,
          totalPrecipitationMm: currentSlot.precipitationMm,
          currentTempC: currentSlot.tempC,
        ),
      ];
    }

    final codes = dailyMap['weather_code'] as List<dynamic>? ?? const [];
    final maxTemps =
        dailyMap['temperature_2m_max'] as List<dynamic>? ?? const [];
    final minTemps =
        dailyMap['temperature_2m_min'] as List<dynamic>? ?? const [];
    final precipSums =
        dailyMap['precipitation_sum'] as List<dynamic>? ?? const [];

    final List<DailyWeatherSummaryEntity> summaries = [];
    for (int i = 0; i < times.length; i++) {
      final dateKey = times[i]?.toString() ?? '';
      final parsedDate = DateTime.tryParse(dateKey);
      if (parsedDate == null) continue;

      final code = _toInt(_elementAt(codes, i), currentSlot.weatherCode);
      final desc = _describeWmo(code);
      final humidList = humidityByDate[dateKey];
      final int avgHumidity = (humidList != null && humidList.isNotEmpty)
          ? (humidList.reduce((a, b) => a + b) / humidList.length).round()
          : currentSlot.humidity;

      final String dayLabel = i == 0
          ? 'Hari ini'
          : '${_weekdayNames[parsedDate.weekday] ?? 'Hari'}, ${parsedDate.day} ${_monthNames[parsedDate.month] ?? ''}';

      summaries.add(
        DailyWeatherSummaryEntity(
          dateKey: dateKey,
          dayLabel: dayLabel,
          dominantWeatherCode: code,
          dominantCondition: desc.id,
          minTempC: _toDouble(_elementAt(minTemps, i), currentSlot.tempC - 2),
          maxTempC: _toDouble(_elementAt(maxTemps, i), currentSlot.tempC + 2),
          avgHumidity: avgHumidity,
          totalPrecipitationMm: _toDouble(_elementAt(precipSums, i), 0.0),
          currentTempC: i == 0 ? currentSlot.tempC : null,
        ),
      );
    }
    return summaries;
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

  static DateTime _toUtcWithOffset(DateTime localDt, int utcOffsetSeconds) {
    return DateTime.utc(
      localDt.year,
      localDt.month,
      localDt.day,
      localDt.hour,
      localDt.minute,
      localDt.second,
    ).subtract(Duration(seconds: utcOffsetSeconds));
  }

  static ({String id, String en}) _describeWmo(int code) {
    return _wmoDescriptions[code] ??
        (id: 'Cerah Berawan', en: 'Partly Cloudy');
  }

  static String _formatVisibility(int meters) {
    if (meters >= 1000) {
      final km = meters / 1000.0;
      return km == km.roundToDouble()
          ? '${km.round()} km'
          : '${km.toStringAsFixed(1)} km';
    }
    return '$meters m';
  }

  static dynamic _elementAt(List<dynamic> list, int index) =>
      index >= 0 && index < list.length ? list[index] : null;

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
