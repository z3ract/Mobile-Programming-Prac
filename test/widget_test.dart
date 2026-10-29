import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_repo/uts/dummy/dummy_gempa_data.dart';
import 'package:master_repo/uts/dummy/dummy_weather_data.dart';
import 'package:master_repo/uts/main.dart';
import 'package:master_repo/uts/models/gempa_model.dart';
import 'package:master_repo/uts/services/location_service.dart';

void main() {
  group('UTS Praktikum - Model & Dummy Data Tests', () {
    test('GempaModel parses JSON correctly with valid coordinates and magnitude', () {
      final json = {
        'Tanggal': '29 Okt 2026',
        'Jam': '14:28:10 WIB',
        'Coordinates': '-8.32,115.65',
        'Lintang': '8.32 LS',
        'Bujur': '115.65 BT',
        'Magnitude': '5.4',
        'Kedalaman': '10 km',
        'Wilayah': 'Bali',
        'Potensi': 'Tidak berpotensi tsunami',
        'Dirasakan': 'II-III Denpasar',
        'Shakemap': '20221213173834.mmi.jpg',
      };

      final gempa = GempaModel.fromJson(json);

      expect(gempa.magnitude, '5.4');
      expect(gempa.magnitudeValue, 5.4);
      expect(gempa.latitude, -8.32);
      expect(gempa.longitude, 115.65);
      expect(gempa.shakemapUrl, contains('data.bmkg.go.id'));
    });

    test('WeatherModel and Hourly/Daily dummy datasets are populated correctly', () {
      final weather = DummyWeatherData.getPrimaryWeather();

      expect(weather.cityName, 'Jakarta Pusat');
      expect(weather.tempC, '29');
      expect(weather.hourly.isNotEmpty, true);
      expect(weather.daily.isNotEmpty, true);
      expect(weather.aqi, 45);
    });

    test('LocationService calculates distance and formats properly', () {
      // Jarak Jakarta (-6.1754, 106.8272) ke Bandung (-6.9175, 107.6191) ~ 120-150 km
      final distance = LocationService.calculateDistanceKm(
        startLatitude: -6.1754,
        startLongitude: 106.8272,
        endLatitude: -6.9175,
        endLongitude: 107.6191,
      );

      expect(distance > 100, true);
      expect(distance < 200, true);
      expect(LocationService.formatDistance(distance), contains('km'));
      expect(LocationService.formatDistance(0.5), '500 m');
    });

    test('DummyGempaData supplies valid seismic and station data', () {
      final terkini = DummyGempaData.getGempaTerkiniList();
      final dirasakan = DummyGempaData.getGempaDirasakanList();
      final stations = DummyGempaData.getStationsList();

      expect(terkini.length, greaterThanOrEqualTo(5));
      expect(dirasakan.length, greaterThanOrEqualTo(3));
      expect(stations.length, greaterThanOrEqualTo(4));
    });
  });

  group('UTS Praktikum - Widget Rendering & Navigation Smoke Test', () {
    testWidgets('CupertinoAtmosphereApp renders properly and bottom navigation works', (WidgetTester tester) async {
      // Set larger screen surface to avoid layout clipping during test
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const CupertinoAtmosphereApp());
      await tester.pumpAndSettle();

      // Check bottom nav items
      expect(find.text('Cuaca'), findsOneWidget);
      expect(find.text('Seismik'), findsOneWidget);
      expect(find.text('Stasiun'), findsOneWidget);

      // Tap Seismik Tab
      await tester.tap(find.text('Seismik'));
      await tester.pumpAndSettle();

      expect(find.text('Aktivitas Seismik'), findsOneWidget);

      // Tap Stasiun Tab
      await tester.tap(find.text('Stasiun'));
      await tester.pumpAndSettle();

      expect(find.text('Jaringan Stasiun BMKG'), findsOneWidget);
    });
  });
}
