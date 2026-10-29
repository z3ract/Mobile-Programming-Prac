class HourlyForecast {
  final String time;
  final String tempC;
  final String condition;
  final String iconCode;

  HourlyForecast({
    required this.time,
    required this.tempC,
    required this.condition,
    this.iconCode = 'cloudy',
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      time: json['time'] ?? 'Now',
      tempC: json['tempC']?.toString() ?? '28',
      condition: json['condition'] ?? 'Cerah',
      iconCode: json['iconCode'] ?? 'sunny',
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'tempC': tempC,
        'condition': condition,
        'iconCode': iconCode,
      };
}

class DailyForecast {
  final String day;
  final String condition;
  final double minTemp;
  final double maxTemp;
  final double? currentTemp;

  DailyForecast({
    required this.day,
    required this.condition,
    required this.minTemp,
    required this.maxTemp,
    this.currentTemp,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      day: json['day'] ?? 'Hari ini',
      condition: json['condition'] ?? 'Cerah Berawan',
      minTemp: (json['minTemp'] as num?)?.toDouble() ?? 24.0,
      maxTemp: (json['maxTemp'] as num?)?.toDouble() ?? 32.0,
      currentTemp: (json['currentTemp'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'condition': condition,
        'minTemp': minTemp,
        'maxTemp': maxTemp,
        'currentTemp': currentTemp,
      };
}

class WeatherModel {
  final String cityName;
  final String regionName;
  final String country;
  final double latitude;
  final double longitude;
  final String tempC;
  final String tempMaxC;
  final String tempMinC;
  final String feelsLikeC;
  final String humidity;
  final String weatherDesc;
  final String windSpeedKm;
  final String windDirection;
  final int uvIndex;
  final int aqi;
  final String aqiStatus;
  final String sunrise;
  final String sunset;
  final String dewPoint;
  final String pressureMb;
  final bool isGpsSource;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  WeatherModel({
    required this.cityName,
    required this.regionName,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.tempC,
    this.tempMaxC = '32',
    this.tempMinC = '24',
    required this.feelsLikeC,
    required this.humidity,
    required this.weatherDesc,
    required this.windSpeedKm,
    this.windDirection = 'Barat Daya',
    this.uvIndex = 6,
    this.aqi = 42,
    this.aqiStatus = 'Baik',
    this.sunrise = '05:42 WIB',
    this.sunset = '17:55 WIB',
    this.dewPoint = '22°',
    this.pressureMb = '1012 hPa',
    this.isGpsSource = false,
    this.hourly = const [],
    this.daily = const [],
  });

  factory WeatherModel.fromWttrJson(
    Map<String, dynamic> json, {
    bool isGps = false,
    List<HourlyForecast>? hourly,
    List<DailyForecast>? daily,
  }) {
    String city = 'Jakarta';
    String region = 'DKI Jakarta';
    String country = 'Indonesia';
    double lat = -6.2088;
    double lon = 106.8456;

    final nearest = json['nearest_area'] as List?;
    if (nearest != null && nearest.isNotEmpty) {
      final area = nearest[0] as Map<String, dynamic>;
      final areaNames = area['areaName'] as List?;
      if (areaNames != null && areaNames.isNotEmpty) {
        city = areaNames[0]['value'] ?? city;
      }
      final regions = area['region'] as List?;
      if (regions != null && regions.isNotEmpty) {
        region = regions[0]['value'] ?? region;
      }
      final countries = area['country'] as List?;
      if (countries != null && countries.isNotEmpty) {
        country = countries[0]['value'] ?? country;
      }
      lat = double.tryParse(area['latitude']?.toString() ?? '') ?? lat;
      lon = double.tryParse(area['longitude']?.toString() ?? '') ?? lon;
    }

    String temp = '29';
    String feelsLike = '32';
    String hum = '68';
    String desc = 'Cerah Berawan';
    String wind = '12';
    String windDir = 'SSW';
    int uv = 5;

    final conditions = json['current_condition'] as List?;
    if (conditions != null && conditions.isNotEmpty) {
      final cond = conditions[0] as Map<String, dynamic>;
      temp = cond['temp_C']?.toString() ?? temp;
      feelsLike = cond['FeelsLikeC']?.toString() ?? feelsLike;
      hum = cond['humidity']?.toString() ?? hum;
      wind = cond['windspeedKmph']?.toString() ?? wind;
      windDir = cond['winddir16Point']?.toString() ?? windDir;
      uv = int.tryParse(cond['uvIndex']?.toString() ?? '5') ?? 5;

      final descs = cond['weatherDesc'] as List?;
      if (descs != null && descs.isNotEmpty) {
        desc = descs[0]['value'] ?? desc;
      }
    }

    return WeatherModel(
      cityName: city,
      regionName: region,
      country: country,
      latitude: lat,
      longitude: lon,
      tempC: temp,
      feelsLikeC: feelsLike,
      humidity: hum,
      weatherDesc: desc,
      windSpeedKm: wind,
      windDirection: windDir,
      uvIndex: uv,
      isGpsSource: isGps,
      hourly: hourly ?? [],
      daily: daily ?? [],
    );
  }

  WeatherModel copyWith({
    String? cityName,
    String? regionName,
    String? country,
    double? latitude,
    double? longitude,
    String? tempC,
    String? tempMaxC,
    String? tempMinC,
    String? feelsLikeC,
    String? humidity,
    String? weatherDesc,
    String? windSpeedKm,
    String? windDirection,
    int? uvIndex,
    int? aqi,
    String? aqiStatus,
    String? sunrise,
    String? sunset,
    String? dewPoint,
    String? pressureMb,
    bool? isGpsSource,
    List<HourlyForecast>? hourly,
    List<DailyForecast>? daily,
  }) {
    return WeatherModel(
      cityName: cityName ?? this.cityName,
      regionName: regionName ?? this.regionName,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tempC: tempC ?? this.tempC,
      tempMaxC: tempMaxC ?? this.tempMaxC,
      tempMinC: tempMinC ?? this.tempMinC,
      feelsLikeC: feelsLikeC ?? this.feelsLikeC,
      humidity: humidity ?? this.humidity,
      weatherDesc: weatherDesc ?? this.weatherDesc,
      windSpeedKm: windSpeedKm ?? this.windSpeedKm,
      windDirection: windDirection ?? this.windDirection,
      uvIndex: uvIndex ?? this.uvIndex,
      aqi: aqi ?? this.aqi,
      aqiStatus: aqiStatus ?? this.aqiStatus,
      sunrise: sunrise ?? this.sunrise,
      sunset: sunset ?? this.sunset,
      dewPoint: dewPoint ?? this.dewPoint,
      pressureMb: pressureMb ?? this.pressureMb,
      isGpsSource: isGpsSource ?? this.isGpsSource,
      hourly: hourly ?? this.hourly,
      daily: daily ?? this.daily,
    );
  }
}
