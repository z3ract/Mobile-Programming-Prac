import '../domain/entities/region_entity.dart';
import '../domain/entities/station_entity.dart';
import '../domain/repositories/i_weather_repository.dart';

/// Fetches live BMKG weather telemetry and actual API latency for observation stations.
class FetchStationTelemetryUseCase {
  final IWeatherRepository _weatherRepository;

  const FetchStationTelemetryUseCase({
    required this._weatherRepository,
  });

  static const List<BmkgStationEntity> defaultStations = [
    BmkgStationEntity(
      id: 'BMKG-ST-01',
      name: 'Stasiun Geofisika Klas I Tangerang',
      type: 'Geofisika & Seismologi',
      adm4: '36.71.01.1001',
      locationLabel: 'Tangerang, Banten',
      latitude: -6.1702,
      longitude: 106.6319,
      elevation: '18 mdpl',
    ),
    BmkgStationEntity(
      id: 'BMKG-ST-02',
      name: 'Stasiun Meteorologi Kemayoran',
      type: 'Meteorologi & Cuaca Penerbangan',
      adm4: '31.71.03.1001',
      locationLabel: 'Jakarta Pusat, DKI Jakarta',
      latitude: -6.1558,
      longitude: 106.8406,
      elevation: '4 mdpl',
    ),
    BmkgStationEntity(
      id: 'BMKG-ST-03',
      name: 'Stasiun Geofisika Karangkates Malang',
      type: 'Seismik & Akselerograf',
      adm4: '35.07.12.2007',
      locationLabel: 'Sumberpucung, Kab. Malang',
      latitude: -8.1520,
      longitude: 112.4480,
      elevation: '280 mdpl',
    ),
    BmkgStationEntity(
      id: 'BMKG-ST-04',
      name: 'Stasiun Geofisika Sanglah Denpasar',
      type: 'Seismologi & Tsunami Early Warning',
      adm4: '51.71.01.1001',
      locationLabel: 'Denpasar, Bali',
      latitude: -8.6768,
      longitude: 115.2102,
      elevation: '25 mdpl',
    ),
    BmkgStationEntity(
      id: 'BMKG-ST-05',
      name: 'Stasiun Klimatologi Mempawah',
      type: 'Klimatologi & Indeks Keringanan',
      adm4: '61.02.18.1001',
      locationLabel: 'Mempawah, Kalimantan Barat',
      latitude: 0.3510,
      longitude: 108.9550,
      elevation: '12 mdpl',
    ),
    BmkgStationEntity(
      id: 'WMO-JP-01',
      name: 'Tokyo Meteorological Observatory (JMA)',
      type: 'Sinoptik & Jaringan Global WMO',
      adm4: 'GLOBAL:JP:1850147',
      locationLabel: 'Tokyo, Japan',
      latitude: 35.6762,
      longitude: 139.6503,
      elevation: '36 mdpl',
    ),
    BmkgStationEntity(
      id: 'WMO-GB-02',
      name: 'London Synoptic Weather Station (Met Office)',
      type: 'Sinoptik & Jaringan Global WMO',
      adm4: 'GLOBAL:GB:2643743',
      locationLabel: 'London, United Kingdom',
      latitude: 51.5074,
      longitude: -0.1278,
      elevation: '25 mdpl',
    ),
    BmkgStationEntity(
      id: 'WMO-US-03',
      name: 'New York Central Park Observatory (NOAA)',
      type: 'Klimatologi & Jaringan Global WMO',
      adm4: 'GLOBAL:US:5128581',
      locationLabel: 'New York, United States',
      latitude: 40.7128,
      longitude: -74.0060,
      elevation: '40 mdpl',
    ),
  ];

  Future<List<BmkgStationEntity>> execute({bool forceRefresh = false}) async {
    final List<BmkgStationEntity> updated = [];

    // Sequential fetching keeps request cadence respectful of BMKG's 60 req/min rate limit.
    for (final station in defaultStations) {
      final regionProbe = _stationToRegion(station);
      final stopwatch = Stopwatch()..start();
      try {
        final forecast = await _weatherRepository.fetchForecast(
          regionProbe,
          forceRefresh: forceRefresh,
        );
        stopwatch.stop();
        updated.add(
          station.copyWith(
            liveTempC: forecast.current.tempC,
            liveCondition: forecast.current.weatherDesc,
            liveWeatherCode: forecast.current.weatherCode,
            liveHumidity: forecast.current.humidity,
            latencyMs: stopwatch.elapsedMilliseconds,
            isOnline: true,
            lastUpdated: DateTime.now(),
          ),
        );
      } catch (_) {
        stopwatch.stop();
        updated.add(
          station.copyWith(
            liveCondition: 'Stasiun sedang sinkronisasi ulang',
            isOnline: false,
            lastUpdated: DateTime.now(),
          ),
        );
      }
    }

    return updated;
  }

  RegionEntity _stationToRegion(BmkgStationEntity station) {
    final segments = station.adm4.split('.');
    return RegionEntity(
      adm1: segments.isNotEmpty ? segments[0] : '31',
      adm2: segments.length >= 2 ? '${segments[0]}.${segments[1]}' : '31.71',
      adm3: segments.length >= 3
          ? '${segments[0]}.${segments[1]}.${segments[2]}'
          : '31.71.03',
      adm4: station.adm4,
      provinsi: station.locationLabel,
      kotkab: station.locationLabel,
      kecamatan: station.name,
      desa: station.locationLabel,
      latitude: station.latitude,
      longitude: station.longitude,
    );
  }
}
