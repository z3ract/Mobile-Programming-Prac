/// Injectable runtime configuration for Open-Meteo, BMKG, wilayah.id, and USGS APIs.
class BmkgApiConfig {
  final String weatherForecastBaseUrl;
  final String openMeteoForecastBaseUrl;
  final String openMeteoGeocodingBaseUrl;
  final String usgsGlobalEarthquakeUrl;
  final String tewsAutoGempaUrl;
  final String tewsGempaTerkiniUrl;
  final String tewsGempaDirasakanUrl;
  final String nowcastRssUrl;
  final String wilayahApiBaseUrl;
  final String osmTileTemplate;
  final String userAgentPackageName;
  final String bmkgAttribution;
  final String openMeteoAttribution;
  final String usgsAttribution;
  final Duration requestTimeout;
  final Duration weatherCacheTtl;
  final Duration seismicCacheTtl;
  final Duration nowcastCacheTtl;
  final Duration wilayahCacheTtl;

  const BmkgApiConfig({
    this.weatherForecastBaseUrl =
        'https://api.bmkg.go.id/publik/prakiraan-cuaca',
    this.openMeteoForecastBaseUrl =
        'https://api.open-meteo.com/v1/forecast',
    this.openMeteoGeocodingBaseUrl =
        'https://geocoding-api.open-meteo.com/v1/search',
    this.usgsGlobalEarthquakeUrl =
        'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_week.geojson',
    this.tewsAutoGempaUrl =
        'https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json',
    this.tewsGempaTerkiniUrl =
        'https://data.bmkg.go.id/DataMKG/TEWS/gempaterkini.json',
    this.tewsGempaDirasakanUrl =
        'https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json',
    this.nowcastRssUrl = 'https://www.bmkg.go.id/alerts/nowcast/id',
    this.wilayahApiBaseUrl = 'https://wilayah.id/api',
    this.osmTileTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    this.userAgentPackageName = 'com.example.master_repo',
    this.bmkgAttribution =
        'Sumber Data: BMKG (Badan Meteorologi, Klimatologi, dan Geofisika)',
    this.openMeteoAttribution =
        'Sumber Data Cuaca: Open-Meteo (Global Weather API)',
    this.usgsAttribution =
        'Sumber Data Gempa Global: USGS Earthquake Hazards Program',
    this.requestTimeout = const Duration(seconds: 8),
    this.weatherCacheTtl = const Duration(minutes: 15),
    this.seismicCacheTtl = const Duration(minutes: 3),
    this.nowcastCacheTtl = const Duration(minutes: 5),
    this.wilayahCacheTtl = const Duration(hours: 24),
  });

  factory BmkgApiConfig.fromEnvironment() {
    const weatherUrl = String.fromEnvironment(
      'BMKG_WEATHER_URL',
      defaultValue: 'https://api.bmkg.go.id/publik/prakiraan-cuaca',
    );
    const openMeteoUrl = String.fromEnvironment(
      'OPEN_METEO_FORECAST_URL',
      defaultValue: 'https://api.open-meteo.com/v1/forecast',
    );
    const openMeteoGeoUrl = String.fromEnvironment(
      'OPEN_METEO_GEOCODING_URL',
      defaultValue: 'https://geocoding-api.open-meteo.com/v1/search',
    );
    const usgsUrl = String.fromEnvironment(
      'USGS_EARTHQUAKE_URL',
      defaultValue:
          'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_week.geojson',
    );
    const autoGempaUrl = String.fromEnvironment(
      'BMKG_AUTOGEMPA_URL',
      defaultValue: 'https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json',
    );
    const terkiniUrl = String.fromEnvironment(
      'BMKG_TERKINI_URL',
      defaultValue: 'https://data.bmkg.go.id/DataMKG/TEWS/gempaterkini.json',
    );
    const dirasakanUrl = String.fromEnvironment(
      'BMKG_DIRASAKAN_URL',
      defaultValue: 'https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json',
    );
    const nowcastUrl = String.fromEnvironment(
      'BMKG_NOWCAST_URL',
      defaultValue: 'https://www.bmkg.go.id/alerts/nowcast/id',
    );
    const wilayahUrl = String.fromEnvironment(
      'WILAYAH_API_URL',
      defaultValue: 'https://wilayah.id/api',
    );
    const tileUrl = String.fromEnvironment(
      'OSM_TILE_TEMPLATE',
      defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
    const timeoutSeconds = int.fromEnvironment(
      'API_TIMEOUT_SECONDS',
      defaultValue: 8,
    );

    return BmkgApiConfig(
      weatherForecastBaseUrl: weatherUrl,
      openMeteoForecastBaseUrl: openMeteoUrl,
      openMeteoGeocodingBaseUrl: openMeteoGeoUrl,
      usgsGlobalEarthquakeUrl: usgsUrl,
      tewsAutoGempaUrl: autoGempaUrl,
      tewsGempaTerkiniUrl: terkiniUrl,
      tewsGempaDirasakanUrl: dirasakanUrl,
      nowcastRssUrl: nowcastUrl,
      wilayahApiBaseUrl: wilayahUrl,
      osmTileTemplate: tileUrl,
      requestTimeout: Duration(seconds: timeoutSeconds),
    );
  }

  Uri weatherForecastUri(String adm4) =>
      Uri.parse(weatherForecastBaseUrl).replace(queryParameters: {'adm4': adm4});

  Uri openMeteoForecastUri({
    required double latitude,
    required double longitude,
  }) =>
      Uri.parse(openMeteoForecastBaseUrl).replace(
        queryParameters: {
          'latitude': latitude.toStringAsFixed(4),
          'longitude': longitude.toStringAsFixed(4),
          'timezone': 'auto',
          'forecast_days': '5',
          'wind_speed_unit': 'kmh',
          'current':
              'temperature_2m,relative_humidity_2m,precipitation,weather_code,cloud_cover,wind_speed_10m,wind_direction_10m',
          'hourly':
              'temperature_2m,relative_humidity_2m,precipitation,weather_code,cloud_cover,visibility,wind_speed_10m,wind_direction_10m',
          'daily':
              'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum',
        },
      );

  Uri openMeteoGeocodingUri(String query, {int count = 10}) =>
      Uri.parse(openMeteoGeocodingBaseUrl).replace(
        queryParameters: {
          'name': query.trim(),
          'count': '$count',
          'language': 'id',
          'format': 'json',
        },
      );

  Uri provincesUri() => Uri.parse('$wilayahApiBaseUrl/provinces.json');

  Uri regenciesUri(String provinceCode) =>
      Uri.parse('$wilayahApiBaseUrl/regencies/$provinceCode.json');

  Uri districtsUri(String regencyCode) =>
      Uri.parse('$wilayahApiBaseUrl/districts/$regencyCode.json');

  Uri villagesUri(String districtCode) =>
      Uri.parse('$wilayahApiBaseUrl/villages/$districtCode.json');
}
