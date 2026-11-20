import 'dart:math' as math;

/// Pure Dart meteorological and geospatial calculations with O(1) compass lookup.
class MeteorologyCalculator {
  static const double _earthRadiusKm = 6371.0;

  static const Map<String, String> _windDirectionMap = {
    'N': 'Utara',
    'NNE': 'Utara Timur Laut',
    'NE': 'Timur Laut',
    'ENE': 'Timur Timur Laut',
    'E': 'Timur',
    'ESE': 'Timur Tenggara',
    'SE': 'Tenggara',
    'SSE': 'Selatan Tenggara',
    'S': 'Selatan',
    'SSW': 'Selatan Barat Daya',
    'SW': 'Barat Daya',
    'WSW': 'Barat Barat Daya',
    'W': 'Barat',
    'WNW': 'Barat Barat Laut',
    'NW': 'Barat Laut',
    'NNW': 'Utara Barat Laut',
    'VARIABLE': 'Berubah-ubah',
  };

  /// Magnus-Tetens approximation for dew point temperature in Celsius.
  static double calculateDewPointC(double tempC, int humidityPct) {
    final double rh = humidityPct.clamp(1, 100).toDouble();
    const double a = 17.27;
    const double b = 237.7;
    final double gamma = ((a * tempC) / (b + tempC)) + math.log(rh / 100.0);
    return (b * gamma) / (a - gamma);
  }

  /// Steadman / Rothfusz heat index approximation for warm tropical humidity.
  static double calculateFeelsLikeC(double tempC, int humidityPct) {
    final double rh = humidityPct.clamp(0, 100).toDouble();
    if (tempC < 27.0 || rh < 40.0) {
      return tempC;
    }
    final double tempF = (tempC * 9.0 / 5.0) + 32.0;
    final double hiF = -42.379 +
        (2.04901523 * tempF) +
        (10.14333127 * rh) -
        (0.22475541 * tempF * rh) -
        (0.00683783 * tempF * tempF) -
        (0.05481717 * rh * rh) +
        (0.00122874 * tempF * tempF * rh) +
        (0.00085282 * tempF * rh * rh) -
        (0.00000199 * tempF * tempF * rh * rh);
    return (hiF - 32.0) * 5.0 / 9.0;
  }

  /// Great-circle Haversine distance in kilometers.
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double radLat1 = _toRadians(lat1);
    final double radLat2 = _toRadians(lat2);

    final double sinHalfLat = math.sin(dLat / 2.0);
    final double sinHalfLon = math.sin(dLon / 2.0);
    final double a = (sinHalfLat * sinHalfLat) +
        (math.cos(radLat1) * math.cos(radLat2) * sinHalfLon * sinHalfLon);
    final double c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    return _earthRadiusKm * c;
  }

  static String formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000.0).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  /// Validates whether coordinates lie within Indonesia's geographic bounding box.
  static bool isWithinIndonesiaBounds(double lat, double lon) {
    return lat >= -11.5 && lat <= 6.5 && lon >= 94.5 && lon <= 141.5;
  }

  /// Translates BMKG wind direction codes in O(1) time.
  static String windDirectionLabel(String code) {
    final normalized = code.trim().toUpperCase();
    return _windDirectionMap[normalized] ??
        (normalized.isEmpty ? 'Tidak diketahui' : normalized);
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}
