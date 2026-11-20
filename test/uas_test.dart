import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:master_repo/uas/adapters/dtos/bmkg_earthquake_dto.dart';
import 'package:master_repo/uas/adapters/dtos/bmkg_weather_dto.dart';
import 'package:master_repo/uas/domain/entities/earthquake_entity.dart';
import 'package:master_repo/uas/domain/entities/notification_preference_entity.dart';
import 'package:master_repo/uas/domain/entities/nowcast_alert_entity.dart';
import 'package:master_repo/uas/domain/entities/region_entity.dart';
import 'package:master_repo/uas/domain/entities/weather_entity.dart';
import 'package:master_repo/uas/domain/repositories/i_earthquake_repository.dart';
import 'package:master_repo/uas/domain/repositories/i_nowcast_repository.dart';
import 'package:master_repo/uas/domain/repositories/i_region_repository.dart';
import 'package:master_repo/uas/domain/repositories/i_storage_repository.dart';
import 'package:master_repo/uas/domain/repositories/i_weather_repository.dart';
import 'package:master_repo/uas/domain/services/i_location_provider.dart';
import 'package:master_repo/uas/domain/services/i_notification_dispatcher.dart';
import 'package:master_repo/uas/domain/strategies/weather_advisory_strategy.dart';
import 'package:master_repo/uas/domain/utils/meteorology_calculator.dart';
import 'package:master_repo/uas/infrastructure/config/bmkg_api_config.dart';
import 'package:master_repo/uas/infrastructure/parsers/bmkg_cap_xml_parser.dart';
import 'package:master_repo/uas/main.dart';
import 'package:master_repo/uas/presentation/bindings/uas_binding.dart';
import 'package:master_repo/uas/presentation/theme/atmosphere_theme_strategy.dart';
import 'package:master_repo/uas/usecases/evaluate_weather_alerts_usecase.dart';
import 'package:master_repo/uas/usecases/resolve_gps_region_usecase.dart';

void main() {
  group('UAS Unit Tests - DTOs, XML Parser, Meteorology & Strategy', () {
    test('BmkgWeatherDto parses 2D cuaca array and computes daily summaries', () {
      final sampleJson = {
        'lokasi': {
          'adm1': '35',
          'adm2': '35.73',
          'adm3': '35.73.05',
          'adm4': '35.73.05.1004',
          'provinsi': 'Jawa Timur',
          'kotkab': 'Kota Malang',
          'kecamatan': 'Lowokwaru',
          'desa': 'Dinoyo',
          'lon': 112.6152,
          'lat': -7.9439,
          'timezone': 'Asia/Jakarta',
        },
        'data': [
          {
            'cuaca': [
              [
                {
                  't': 26,
                  'tcc': 60,
                  'tp': 0.0,
                  'weather': 1,
                  'weather_desc': 'Cerah Berawan',
                  'weather_desc_en': 'Partly Cloudy',
                  'wd_deg': 120,
                  'wd': 'ESE',
                  'wd_to': 'WNW',
                  'ws': 11.5,
                  'hu': 76,
                  'vs': 10000,
                  'vs_text': '10 km',
                  'utc_datetime': '2026-11-20 05:00:00',
                  'local_datetime': '2026-11-20 12:00:00',
                  'analysis_date': '2026-11-20T00:00:00Z',
                },
                {
                  't': 30,
                  'tcc': 85,
                  'tp': 4.2,
                  'weather': 60,
                  'weather_desc': 'Hujan Ringan',
                  'weather_desc_en': 'Light Rain',
                  'wd_deg': 140,
                  'wd': 'SE',
                  'wd_to': 'NW',
                  'ws': 15.0,
                  'hu': 84,
                  'vs': 6000,
                  'vs_text': '6 km',
                  'utc_datetime': '2026-11-20 08:00:00',
                  'local_datetime': '2026-11-20 15:00:00',
                  'analysis_date': '2026-11-20T00:00:00Z',
                },
              ],
              [
                {
                  't': 24,
                  'tcc': 40,
                  'tp': 0.0,
                  'weather': 0,
                  'weather_desc': 'Cerah',
                  'weather_desc_en': 'Clear Skies',
                  'wd_deg': 90,
                  'wd': 'E',
                  'wd_to': 'W',
                  'ws': 9.0,
                  'hu': 70,
                  'vs': 10000,
                  'vs_text': '10 km',
                  'utc_datetime': '2026-11-21 05:00:00',
                  'local_datetime': '2026-11-21 12:00:00',
                  'analysis_date': '2026-11-20T00:00:00Z',
                },
              ],
            ],
          },
        ],
      };

      final forecast = BmkgWeatherDto.fromBmkgJson(
        sampleJson,
        fallbackRegion: _sampleRegion,
        sourceAttribution: 'Sumber Data: BMKG',
        referenceTime: DateTime(2026, 11, 20, 15, 0),
      );

      expect(forecast.region.desa, 'Dinoyo');
      expect(forecast.slots.length, 3);
      expect(forecast.current.weatherCode, 60);
      expect(forecast.current.tempC, 30.0);
      expect(forecast.daily.length, 2);
      expect(forecast.daily.first.minTempC, 26.0);
      expect(forecast.daily.first.maxTempC, 30.0);
      expect(forecast.daily.first.totalPrecipitationMm, closeTo(4.2, 0.01));
    });

    test('BmkgEarthquakeDto parses autogempa and coordinates properly', () {
      final json = {
        'Infogempa': {
          'gempa': {
            'Tanggal': '20 Nov 2026',
            'Jam': '14:15:00 WIB',
            'Coordinates': '-8.45,112.50',
            'Lintang': '8.45 LS',
            'Bujur': '112.50 BT',
            'Magnitude': '5.6',
            'Kedalaman': '12 km',
            'Wilayah': 'Pusat gempa di laut 45 km BaratDaya Malang',
            'Potensi': 'Tidak berpotensi tsunami',
            'Dirasakan': 'III-IV Malang',
            'Shakemap': '20261120141500.mmi.jpg',
          },
        },
      };

      final quake = BmkgEarthquakeDto.parseAutoGempaResponse(json);
      expect(quake.magnitudeValue, 5.6);
      expect(quake.latitude, -8.45);
      expect(quake.longitude, 112.50);
      expect(quake.hasTsunamiPotential, false);
      expect(quake.shakemapUrl, contains('data.bmkg.go.id'));
    });

    test('BmkgCapXmlParser parses RSS feed and CAP polygon coordinates', () {
      const rssXml = '''
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <item>
            <title><![CDATA[Peringatan Dini Cuaca Jawa Timur]]></title>
            <link>https://www.bmkg.go.id/alerts/nowcast/id/JTM123_alert.xml</link>
            <description><![CDATA[Hujan sedang hingga lebat &amp; kilat/petir di Kab. Malang]]></description>
            <author>BMKG</author>
            <pubDate>Fri, 20 Nov 2026 14:00:00 +0700</pubDate>
          </item>
        </channel>
      </rss>
      ''';

      const capXml = '''
      <cap:alert xmlns:cap="urn:oasis:names:tc:emergency:cap:1.2">
        <cap:identifier>BMKG-JTM-123</cap:identifier>
        <cap:info>
          <cap:event>Hujan Lebat &amp; Angin Kencang</cap:event>
          <cap:severity>Severe</cap:severity>
          <cap:urgency>Immediate</cap:urgency>
          <cap:certainty>Observed</cap:certainty>
          <cap:effective>2026-11-20T14:00:00+07:00</cap:effective>
          <cap:expires>2026-11-20T17:00:00+07:00</cap:expires>
          <cap:senderName>BMKG Stasiun Meteorologi Juanda</cap:senderName>
          <cap:headline>Peringatan Dini Cuaca Jawa Timur</cap:headline>
          <cap:description>Berpotensi hujan lebat disertai petir.</cap:description>
          <cap:instruction>Waspada genangan dan pohon tumbang.</cap:instruction>
          <cap:web>https://www.bmkg.go.id/alerts/nowcast/id/jtm.png</cap:web>
          <cap:area>
            <cap:areaDesc>Lowokwaru, Dinoyo, Kota Malang</cap:areaDesc>
            <cap:polygon>-7.93,112.60 -7.94,112.63 -7.96,112.61 -7.93,112.60</cap:polygon>
          </cap:area>
        </cap:info>
      </cap:alert>
      ''';

      final rssItems = BmkgCapXmlParser.parseNowcastRss(rssXml);
      expect(rssItems.length, 1);
      expect(rssItems.first['title'], 'Peringatan Dini Cuaca Jawa Timur');
      expect(
        rssItems.first['description'],
        'Hujan sedang hingga lebat & kilat/petir di Kab. Malang',
      );

      final capDoc = BmkgCapXmlParser.parseNowcastCapDetail(capXml);
      expect(capDoc.identifier, 'BMKG-JTM-123');
      expect(capDoc.event, 'Hujan Lebat & Angin Kencang');
      expect(capDoc.areas.length, 1);
      expect(capDoc.areas.first.polygons.length, 1);
      expect(capDoc.areas.first.polygons.first.length, 4);
      expect(capDoc.areas.first.polygons.first.first.lat, -7.93);
      expect(capDoc.areas.first.polygons.first.first.lon, 112.60);
    });

    test('MeteorologyCalculator computes Haversine, bounds, dew point, wind O(1)', () {
      final km = MeteorologyCalculator.calculateDistanceKm(
        -7.9439,
        112.6152,
        -7.2994,
        112.7358,
      );
      expect(km, greaterThan(60));
      expect(km, lessThan(90));
      expect(MeteorologyCalculator.isWithinIndonesiaBounds(-7.94, 112.61), true);
      expect(MeteorologyCalculator.isWithinIndonesiaBounds(37.33, -122.03), false);
      expect(MeteorologyCalculator.windDirectionLabel('ESE'), 'Timur Tenggara');
      expect(MeteorologyCalculator.calculateDewPointC(30, 80), greaterThan(25));
      expect(MeteorologyCalculator.calculateFeelsLikeC(34, 70), greaterThan(34));
    });

    test('WeatherCodeRegistry & AtmosphereThemeRegistry map codes in O(1)', () {
      final rainPolicy = WeatherCodeRegistry.resolvePolicy(63);
      expect(rainPolicy.category, WeatherConditionCategory.heavyRain);
      expect(rainPolicy.isRainHazard, true);
      expect(rainPolicy.severity, AlertSeverity.danger);

      final stormTheme = AtmosphereThemeRegistry.resolveByWeatherCode(95);
      expect(stormTheme.badgeLabel, 'Badai Petir');
      expect(stormTheme.sceneType, SkySceneType.storm);

      final nightClearTheme = AtmosphereThemeRegistry.resolveByWeatherCode(
        0,
        isNight: true,
      );
      expect(nightClearTheme.badgeLabel, 'Malam Cerah');
      expect(nightClearTheme.sceneType, SkySceneType.night);
    });

    test('EvaluateWeatherAlertsUseCase evaluates & deduplicates notifications', () async {
      final storage = _FakeStorageRepository();
      final dispatcher = _FakeNotificationDispatcher();
      final useCase = EvaluateWeatherAlertsUseCase(
        storageRepository: storage,
        notificationDispatcher: dispatcher,
      );

      final alerts = await useCase.execute(
        region: _sampleRegion,
        forecast: _sampleForecast(tempC: 34.5, weatherCode: 95),
        nowcasts: const [
          NowcastRssItemEntity(
            id: 'nc1',
            title: 'Peringatan Dini Cuaca Jawa Timur',
            detailUrl: 'https://www.bmkg.go.id/alerts/nowcast/id/JTM.xml',
            description: 'Hujan lebat & petir di Kota Malang',
            author: 'BMKG',
            pubDate: '20 Nov 2026',
            provinceName: 'Jawa Timur',
          ),
        ],
        latestQuake: _sampleEarthquake,
        preferences: const NotificationPreferenceEntity(),
      );

      expect(alerts.length, 4);
      expect(dispatcher.dispatchedAlerts.length, 4);

      // Re-evaluating identical state must not re-fire duplicate OS notifications.
      await useCase.execute(
        region: _sampleRegion,
        forecast: _sampleForecast(tempC: 34.5, weatherCode: 95),
        nowcasts: const [
          NowcastRssItemEntity(
            id: 'nc1',
            title: 'Peringatan Dini Cuaca Jawa Timur',
            detailUrl: 'https://www.bmkg.go.id/alerts/nowcast/id/JTM.xml',
            description: 'Hujan lebat & petir di Kota Malang',
            author: 'BMKG',
            pubDate: '20 Nov 2026',
            provinceName: 'Jawa Timur',
          ),
        ],
        latestQuake: _sampleEarthquake,
        preferences: const NotificationPreferenceEntity(),
      );
      expect(dispatcher.dispatchedAlerts.length, 4);
    });

    test('ResolveGpsRegionUseCase handles outside-Indonesia and inside-Indonesia fixes', () async {
      final regionRepo = _FakeRegionRepository();

      final outsideUseCase = ResolveGpsRegionUseCase(
        locationProvider: _StaticLocationProvider(
          const GeoFixResult(latitude: 37.33, longitude: -122.03),
        ),
        regionRepository: regionRepo,
      );
      final outsideRes = await outsideUseCase.execute(
        fallbackRegion: _sampleRegion,
      );
      expect(outsideRes.isGpsSuccess, false);
      expect(outsideRes.isOutsideIndonesia, true);
      expect(outsideRes.region?.adm4, _sampleRegion.adm4);

      final insideUseCase = ResolveGpsRegionUseCase(
        locationProvider: _FakeLocationProvider(),
        regionRepository: regionRepo,
      );
      final insideRes = await insideUseCase.execute(
        fallbackRegion: _sampleRegion,
      );
      expect(insideRes.isGpsSuccess, true);
      expect(insideRes.isOutsideIndonesia, false);
      expect(insideRes.region?.isGpsResolved, true);
      expect(insideRes.region?.latitude, -7.9439);
    });
  });

  group('UAS Widget Tests - Full Navigation, Location Manager & Alerts', () {
    setUp(() {
      Get.reset();
    });

    testWidgets(
      'TerraCastUasApp renders live BMKG weather, navigates all 5 tabs, opens location manager & triggers test notification',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeDispatcher = _FakeNotificationDispatcher();
        final testBinding = UasBinding(
          configOverride: const BmkgApiConfig(osmTileTemplate: ''),
          weatherRepositoryOverride: _FakeWeatherRepository(),
          earthquakeRepositoryOverride: _FakeEarthquakeRepository(),
          nowcastRepositoryOverride: _FakeNowcastRepository(),
          regionRepositoryOverride: _FakeRegionRepository(),
          storageRepositoryOverride: _FakeStorageRepository(),
          locationProviderOverride: _FakeLocationProvider(),
          notificationDispatcherOverride: fakeDispatcher,
        );

        await tester.pumpWidget(
          TerraCastUasApp(
            customBinding: testBinding,
            enableAmbientMotion: false,
          ),
        );
        await tester.pumpAndSettle();

        // Tab 1: Cuaca displays Dinoyo + live temp and supports °C / °F toggle
        expect(find.text('Dinoyo'), findsWidgets);
        expect(find.text('30'), findsOneWidget);

        await tester.tap(find.byKey(const Key('weather_unit_toggle')));
        await tester.pumpAndSettle();
        expect(find.text('86'), findsOneWidget);

        await tester.tap(find.byKey(const Key('weather_unit_toggle')));
        await tester.pumpAndSettle();
        expect(find.text('30'), findsOneWidget);

        // Open LocationManagerScreen from city selector header
        await tester.tap(find.byKey(const Key('weather_location_button')));
        await tester.pumpAndSettle();
        expect(find.text('Lokasi & Wilayah BMKG'), findsOneWidget);
        expect(find.text('Deteksi Lokasi GPS Otomatis'), findsOneWidget);

        // Return back to Cuaca and scroll down to verify BMKG attribution footer
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(ListView).first,
          const Offset(0, -600),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            'BMKG (Badan Meteorologi, Klimatologi, dan Geofisika)',
          ),
          findsWidgets,
        );

        // Tab 2: Seismik
        await tester.tap(find.text('Seismik'));
        await tester.pumpAndSettle();
        expect(find.text('Aktivitas Seismik'), findsOneWidget);
        expect(find.text('Magnitudo 5.0+'), findsOneWidget);

        // Tab 3: Peta
        await tester.tap(find.text('Peta'));
        await tester.pumpAndSettle();
        expect(find.text('Peta Interaktif Nusantara'), findsOneWidget);

        // Tab 4: Peringatan + Uji Notifikasi
        await tester.tap(find.text('Peringatan'));
        await tester.pumpAndSettle();
        expect(find.text('Pusat Peringatan'), findsOneWidget);

        await tester.tap(find.text('Evaluasi & Notifikasi'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Uji Notifikasi Sistem'));
        await tester.pumpAndSettle();
        expect(fakeDispatcher.dispatchedAlerts.isNotEmpty, true);

        // Tab 5: Stasiun
        await tester.tap(find.text('Stasiun'));
        await tester.pumpAndSettle();
        expect(find.text('Jaringan Stasiun BMKG'), findsOneWidget);
        expect(find.text('Proyek UAS Praktikum Mobile'), findsOneWidget);
      },
    );
  });
}

const RegionEntity _sampleRegion = RegionEntity(
  adm1: '35',
  adm2: '35.73',
  adm3: '35.73.05',
  adm4: '35.73.05.1004',
  provinsi: 'Jawa Timur',
  kotkab: 'Kota Malang',
  kecamatan: 'Lowokwaru',
  desa: 'Dinoyo',
  latitude: -7.9439,
  longitude: 112.6152,
);

const EarthquakeEntity _sampleEarthquake = EarthquakeEntity(
  tanggal: '20 Nov 2026',
  jam: '14:15:00 WIB',
  coordinates: '-8.45,112.50',
  lintang: '8.45 LS',
  bujur: '112.50 BT',
  magnitude: '5.6',
  kedalaman: '12 km',
  wilayah: '45 km BaratDaya Kab. Malang, Jawa Timur',
  potensi: 'Tidak berpotensi tsunami',
  dirasakan: 'III-IV Malang',
);

WeatherForecastEntity _sampleForecast({
  double tempC = 30.0,
  int weatherCode = 60,
}) {
  final slot = WeatherSlotEntity(
    localDateTime: DateTime(2026, 11, 20, 15, 0),
    utcDateTime: DateTime.utc(2026, 11, 20, 8, 0),
    timeLabel: '15:00',
    tempC: tempC,
    humidity: 78,
    cloudCoverPct: 80,
    precipitationMm: 2.5,
    weatherCode: weatherCode,
    weatherDesc: weatherCode == 95 ? 'Hujan Petir' : 'Hujan Ringan',
    weatherDescEn: 'Rain',
    windSpeedKm: 14.0,
    windDirection: 'SE',
    windDirectionTo: 'NW',
    windDegree: 135,
    visibilityMeters: 7000,
    visibilityText: '7 km',
    analysisDate: '2026-11-20T00:00:00Z',
  );

  return WeatherForecastEntity(
    region: _sampleRegion,
    current: slot,
    slots: [slot],
    daily: [
      DailyWeatherSummaryEntity(
        dateKey: '2026-11-20',
        dayLabel: 'Hari ini',
        dominantWeatherCode: weatherCode,
        dominantCondition: slot.weatherDesc,
        minTempC: 24.0,
        maxTempC: tempC,
        avgHumidity: 78,
        totalPrecipitationMm: 2.5,
        currentTempC: tempC,
      ),
    ],
    fetchedAt: DateTime(2026, 11, 20, 15, 0),
    sourceAttribution:
        'Sumber Data: BMKG (Badan Meteorologi, Klimatologi, dan Geofisika)',
  );
}

class _FakeWeatherRepository implements IWeatherRepository {
  @override
  Future<WeatherForecastEntity> fetchForecast(
    RegionEntity region, {
    bool forceRefresh = false,
  }) async {
    return _sampleForecast().copyWith(region: region);
  }
}

class _FakeEarthquakeRepository implements IEarthquakeRepository {
  @override
  Future<EarthquakeEntity> fetchAutoGempa({bool forceRefresh = false}) async =>
      _sampleEarthquake;

  @override
  Future<List<EarthquakeEntity>> fetchGempaDirasakan({
    bool forceRefresh = false,
  }) async =>
      const [_sampleEarthquake];

  @override
  Future<List<EarthquakeEntity>> fetchGempaTerkini({
    bool forceRefresh = false,
  }) async =>
      const [_sampleEarthquake];
}

class _FakeNowcastRepository implements INowcastRepository {
  @override
  Future<List<NowcastRssItemEntity>> fetchActiveNowcasts({
    bool forceRefresh = false,
  }) async {
    return const [
      NowcastRssItemEntity(
        id: 'nc1',
        title: 'Peringatan Dini Cuaca Jawa Timur',
        detailUrl: 'https://www.bmkg.go.id/alerts/nowcast/id/JTM.xml',
        description: 'Potensi hujan sedang hingga lebat di wilayah Malang.',
        author: 'BMKG',
        pubDate: '20 Nov 2026 14:00 WIB',
        provinceName: 'Jawa Timur',
      ),
    ];
  }

  @override
  Future<NowcastCapDetailEntity> fetchCapDetail(String detailUrl) async {
    return const NowcastCapDetailEntity(
      identifier: 'BMKG-JTM-1',
      event: 'Hujan Lebat',
      severity: 'Severe',
      urgency: 'Immediate',
      certainty: 'Observed',
      effective: '2026-11-20T14:00:00+07:00',
      expires: '2026-11-20T17:00:00+07:00',
      senderName: 'BMKG',
      headline: 'Peringatan Dini Cuaca Jawa Timur',
      description: 'Hujan intensitas sedang hingga lebat.',
      instruction: 'Waspadai genangan air.',
      infographicUrl: '',
      areas: [],
    );
  }
}

class _FakeRegionRepository implements IRegionRepository {
  @override
  Future<List<AdminAreaOption>> fetchDistricts(String regencyCode) async =>
      const [AdminAreaOption(code: '35.73.05', name: 'Lowokwaru', level: 3)];

  @override
  Future<List<AdminAreaOption>> fetchProvinces() async =>
      const [AdminAreaOption(code: '35', name: 'Jawa Timur', level: 1)];

  @override
  Future<List<AdminAreaOption>> fetchRegencies(String provinceCode) async =>
      const [AdminAreaOption(code: '35.73', name: 'Kota Malang', level: 2)];

  @override
  Future<List<AdminAreaOption>> fetchVillages(String districtCode) async =>
      const [AdminAreaOption(code: '35.73.05.1004', name: 'Dinoyo', level: 4)];

  @override
  RegionEntity findNearestPreset(double latitude, double longitude) =>
      _sampleRegion;

  @override
  RegionEntity getDefaultRegion() => _sampleRegion;

  @override
  List<RegionEntity> getPresetRegions() => const [_sampleRegion];

  @override
  Future<RegionEntity?> resolveByCoordinates({
    required double latitude,
    required double longitude,
    String? adminAreaHint,
    String? subAdminAreaHint,
    String? localityHint,
  }) async =>
      _sampleRegion;
}

class _FakeStorageRepository implements IStorageRepository {
  RegionEntity? _activeRegion;
  List<RegionEntity> _favorites = const [];
  NotificationPreferenceEntity _prefs = const NotificationPreferenceEntity();
  final Map<String, WeatherForecastEntity> _cache = {};
  final Set<String> _notified = {};

  @override
  Future<bool> hasNotifiedAlert(String alertId) async =>
      _notified.contains(alertId);

  @override
  Future<RegionEntity?> loadActiveRegion() async => _activeRegion;

  @override
  Future<List<RegionEntity>> loadFavoriteRegions() async => _favorites;

  @override
  Future<NotificationPreferenceEntity> loadNotificationPreferences() async =>
      _prefs;

  @override
  Future<WeatherForecastEntity?> loadWeatherCache(String adm4) async =>
      _cache[adm4];

  @override
  Future<void> markAlertNotified(String alertId) async {
    _notified.add(alertId);
  }

  @override
  Future<void> saveActiveRegion(RegionEntity region) async {
    _activeRegion = region;
  }

  @override
  Future<void> saveFavoriteRegions(List<RegionEntity> regions) async {
    _favorites = regions;
  }

  @override
  Future<void> saveNotificationPreferences(
    NotificationPreferenceEntity prefs,
  ) async {
    _prefs = prefs;
  }

  @override
  Future<void> saveWeatherCache(
    String adm4,
    WeatherForecastEntity forecast,
  ) async {
    _cache[adm4] = forecast;
  }
}

class _FakeLocationProvider implements ILocationProvider {
  @override
  Future<GeoFixResult?> getCurrentCoordinates() async =>
      const GeoFixResult(latitude: -7.9439, longitude: 112.6152);

  @override
  Future<ReverseGeocodeResult?> reverseGeocode(
    double latitude,
    double longitude,
  ) async =>
      const ReverseGeocodeResult(
        provinceHint: 'Jawa Timur',
        cityHint: 'Kota Malang',
        districtHint: 'Lowokwaru',
        villageHint: 'Dinoyo',
      );
}

class _StaticLocationProvider implements ILocationProvider {
  final GeoFixResult? fix;

  const _StaticLocationProvider(this.fix);

  @override
  Future<GeoFixResult?> getCurrentCoordinates() async => fix;

  @override
  Future<ReverseGeocodeResult?> reverseGeocode(
    double latitude,
    double longitude,
  ) async =>
      null;
}

class _FakeNotificationDispatcher implements INotificationDispatcher {
  final List<AlertEvaluationEntity> dispatchedAlerts = [];

  @override
  Future<void> dispatchAlert(AlertEvaluationEntity alert) async {
    dispatchedAlerts.add(alert);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissionIfNeeded() async => true;
}
