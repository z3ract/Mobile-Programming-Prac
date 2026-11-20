import '../entities/notification_preference_entity.dart';

/// Canonical atmospheric categories derived from BMKG weather integer codes.
enum WeatherConditionCategory {
  clear,
  partlyCloudy,
  cloudy,
  hazeFog,
  lightRain,
  heavyRain,
  thunderstorm,
}

/// Strategy contract encapsulating advisory text and hazard classification.
abstract interface class IWeatherConditionPolicy {
  WeatherConditionCategory get category;
  String get shortLabel;
  String get advisoryHeadline;
  String get activityRecommendation;
  bool get isRainHazard;
  AlertSeverity get severity;
}

class ClearWeatherPolicy implements IWeatherConditionPolicy {
  const ClearWeatherPolicy();

  @override
  WeatherConditionCategory get category => WeatherConditionCategory.clear;

  @override
  String get shortLabel => 'Cerah';

  @override
  String get advisoryHeadline => 'Langit Cerah & Radiasi Matahari Optimal';

  @override
  String get activityRecommendation =>
      'Ideal untuk aktivitas luar ruang. Gunakan pelindung sinar UV dan jaga hidrasi saat siang hari.';

  @override
  bool get isRainHazard => false;

  @override
  AlertSeverity get severity => AlertSeverity.info;
}

class PartlyCloudyPolicy implements IWeatherConditionPolicy {
  const PartlyCloudyPolicy();

  @override
  WeatherConditionCategory get category =>
      WeatherConditionCategory.partlyCloudy;

  @override
  String get shortLabel => 'Cerah Berawan';

  @override
  String get advisoryHeadline => 'Cerah Berawan & Kondisi Atmosfer Stabil';

  @override
  String get activityRecommendation =>
      'Cuaca relatif bersahabat untuk mobilitas harian dan perjalanan antarkota.';

  @override
  bool get isRainHazard => false;

  @override
  AlertSeverity get severity => AlertSeverity.info;
}

class CloudyPolicy implements IWeatherConditionPolicy {
  const CloudyPolicy();

  @override
  WeatherConditionCategory get category => WeatherConditionCategory.cloudy;

  @override
  String get shortLabel => 'Mendung / Berawan';

  @override
  String get advisoryHeadline => 'Tutupan Awan Tebal (Mendung)';

  @override
  String get activityRecommendation =>
      'Langit didominasi awan tebal. Siapkan payung lipat bila beraktivitas hingga sore atau malam.';

  @override
  bool get isRainHazard => false;

  @override
  AlertSeverity get severity => AlertSeverity.advisory;
}

class HazeFogPolicy implements IWeatherConditionPolicy {
  const HazeFogPolicy();

  @override
  WeatherConditionCategory get category => WeatherConditionCategory.hazeFog;

  @override
  String get shortLabel => 'Kabut / Asap';

  @override
  String get advisoryHeadline => 'Waspada Kabut & Penurunan Jarak Pandang';

  @override
  String get activityRecommendation =>
      'Kurangi kecepatan berkendara, nyalakan lampu kabut, dan gunakan masker bila udara terasa kabur.';

  @override
  bool get isRainHazard => false;

  @override
  AlertSeverity get severity => AlertSeverity.advisory;
}

class LightRainPolicy implements IWeatherConditionPolicy {
  const LightRainPolicy();

  @override
  WeatherConditionCategory get category => WeatherConditionCategory.lightRain;

  @override
  String get shortLabel => 'Hujan Ringan';

  @override
  String get advisoryHeadline => 'Potensi Hujan Ringan hingga Sedang';

  @override
  String get activityRecommendation =>
      'Sediakan jas hujan atau payung serta antisipasi jalan licin di rute perjalanan Anda.';

  @override
  bool get isRainHazard => true;

  @override
  AlertSeverity get severity => AlertSeverity.warning;
}

class HeavyRainPolicy implements IWeatherConditionPolicy {
  const HeavyRainPolicy();

  @override
  WeatherConditionCategory get category => WeatherConditionCategory.heavyRain;

  @override
  String get shortLabel => 'Hujan Lebat';

  @override
  String get advisoryHeadline => 'Peringatan Hujan Lebat di Lokasi Anda';

  @override
  String get activityRecommendation =>
      'Waspadai genangan air, jarak pandang terbatas, dan hindari area rawan banjir atau longsor.';

  @override
  bool get isRainHazard => true;

  @override
  AlertSeverity get severity => AlertSeverity.danger;
}

class ThunderstormPolicy implements IWeatherConditionPolicy {
  const ThunderstormPolicy();

  @override
  WeatherConditionCategory get category =>
      WeatherConditionCategory.thunderstorm;

  @override
  String get shortLabel => 'Hujan Petir';

  @override
  String get advisoryHeadline => 'Waspada Hujan Disertai Kilat & Angin Kencang';

  @override
  String get activityRecommendation =>
      'Tunda aktivitas di ruang terbuka, jauhi pohon tinggi atau papan reklame, dan cari bangunan aman.';

  @override
  bool get isRainHazard => true;

  @override
  AlertSeverity get severity => AlertSeverity.danger;
}

/// O(1) lookup registry translating BMKG and Open-Meteo WMO codes to strategy policies.
class WeatherCodeRegistry {
  static const Map<int, WeatherConditionCategory> _codeToCategory = {
    0: WeatherConditionCategory.clear,
    1: WeatherConditionCategory.partlyCloudy,
    2: WeatherConditionCategory.partlyCloudy,
    3: WeatherConditionCategory.cloudy,
    4: WeatherConditionCategory.cloudy,
    5: WeatherConditionCategory.hazeFog,
    10: WeatherConditionCategory.hazeFog,
    45: WeatherConditionCategory.hazeFog,
    48: WeatherConditionCategory.hazeFog,
    51: WeatherConditionCategory.lightRain,
    53: WeatherConditionCategory.lightRain,
    55: WeatherConditionCategory.lightRain,
    56: WeatherConditionCategory.lightRain,
    57: WeatherConditionCategory.lightRain,
    60: WeatherConditionCategory.lightRain,
    61: WeatherConditionCategory.lightRain,
    63: WeatherConditionCategory.heavyRain,
    65: WeatherConditionCategory.heavyRain,
    66: WeatherConditionCategory.lightRain,
    67: WeatherConditionCategory.heavyRain,
    71: WeatherConditionCategory.lightRain,
    73: WeatherConditionCategory.lightRain,
    75: WeatherConditionCategory.heavyRain,
    77: WeatherConditionCategory.lightRain,
    80: WeatherConditionCategory.lightRain,
    81: WeatherConditionCategory.lightRain,
    82: WeatherConditionCategory.heavyRain,
    85: WeatherConditionCategory.lightRain,
    86: WeatherConditionCategory.heavyRain,
    95: WeatherConditionCategory.thunderstorm,
    96: WeatherConditionCategory.thunderstorm,
    97: WeatherConditionCategory.thunderstorm,
    99: WeatherConditionCategory.thunderstorm,
  };

  static const Map<WeatherConditionCategory, IWeatherConditionPolicy>
      _categoryToPolicy = {
    WeatherConditionCategory.clear: ClearWeatherPolicy(),
    WeatherConditionCategory.partlyCloudy: PartlyCloudyPolicy(),
    WeatherConditionCategory.cloudy: CloudyPolicy(),
    WeatherConditionCategory.hazeFog: HazeFogPolicy(),
    WeatherConditionCategory.lightRain: LightRainPolicy(),
    WeatherConditionCategory.heavyRain: HeavyRainPolicy(),
    WeatherConditionCategory.thunderstorm: ThunderstormPolicy(),
  };

  static const List<({List<String> keywords, WeatherConditionCategory category})>
      _fallbackKeywordRules = [
    (
      keywords: ['petir', 'thunder', 'kilat', 'badai'],
      category: WeatherConditionCategory.thunderstorm,
    ),
    (
      keywords: ['lebat', 'heavy'],
      category: WeatherConditionCategory.heavyRain,
    ),
    (
      keywords: ['hujan', 'rain', 'gerimis', 'shower', 'salju', 'snow', 'drizzle'],
      category: WeatherConditionCategory.lightRain,
    ),
    (
      keywords: ['kabut', 'asap', 'kabur', 'fog', 'haze', 'mist'],
      category: WeatherConditionCategory.hazeFog,
    ),
    (
      keywords: ['cerah berawan', 'partly'],
      category: WeatherConditionCategory.partlyCloudy,
    ),
    (
      keywords: ['berawan', 'mendung', 'cloudy', 'overcast'],
      category: WeatherConditionCategory.cloudy,
    ),
    (
      keywords: ['cerah', 'clear', 'sunny'],
      category: WeatherConditionCategory.clear,
    ),
  ];

  static WeatherConditionCategory resolveCategory(
    int code, {
    String? fallbackDesc,
  }) {
    final mapped = _codeToCategory[code];
    if (mapped != null) return mapped;

    final normalized = fallbackDesc?.trim().toLowerCase() ?? '';
    if (normalized.isNotEmpty) {
      for (final rule in _fallbackKeywordRules) {
        if (rule.keywords.any(normalized.contains)) {
          return rule.category;
        }
      }
    }

    return WeatherConditionCategory.partlyCloudy;
  }

  static IWeatherConditionPolicy resolvePolicy(
    int code, {
    String? fallbackDesc,
  }) {
    final category = resolveCategory(code, fallbackDesc: fallbackDesc);
    return _categoryToPolicy[category] ?? const PartlyCloudyPolicy();
  }
}
