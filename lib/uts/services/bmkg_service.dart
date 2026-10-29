import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../dummy/dummy_gempa_data.dart';
import '../dummy/dummy_weather_data.dart';
import '../models/gempa_model.dart';
import '../models/weather_model.dart';

class BmkgApiService {
  final http.Client client;

  BmkgApiService({http.Client? client}) : client = client ?? http.Client();

  /// Mengambil data gempa bumi terkini realtime (fallback ke data dummy jika offline)
  Future<GempaModel> fetchAutoGempa() async {
    try {
      final response = await client
          .get(
            Uri.parse('https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('Infogempa') && data['Infogempa']['gempa'] != null) {
          return GempaModel.fromJson(data['Infogempa']['gempa']);
        }
      }
    } catch (e) {
      debugPrint('BMKG live autogempa notice: $e (memuat data dummy lokal)');
    }

    // Fallback data dummy lokal terstruktur
    return DummyGempaData.getAutoGempa();
  }

  /// Mengambil daftar riwayat gempa bumi M 5.0+
  Future<List<GempaModel>> fetchGempaTerkini() async {
    try {
      final response = await client
          .get(
            Uri.parse('https://data.bmkg.go.id/DataMKG/TEWS/gempaterkini.json'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('Infogempa') && data['Infogempa']['gempa'] != null) {
          final List<dynamic> list = data['Infogempa']['gempa'];
          return list.map((item) => GempaModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('BMKG live gempa terkini notice: $e (memuat data dummy lokal)');
    }

    return DummyGempaData.getGempaTerkiniList();
  }

  /// Mengambil daftar gempa dirasakan oleh masyarakat (skala MMI)
  Future<List<GempaModel>> fetchGempaDirasakan() async {
    try {
      final response = await client
          .get(
            Uri.parse('https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('Infogempa') && data['Infogempa']['gempa'] != null) {
          final List<dynamic> list = data['Infogempa']['gempa'];
          return list.map((item) => GempaModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('BMKG live gempa dirasakan notice: $e (memuat data dummy lokal)');
    }

    return DummyGempaData.getGempaDirasakanList();
  }

  /// Mengambil data cuaca lokal & prakiraan jam-jaman
  Future<WeatherModel> fetchWeatherData({
    double? latitude,
    double? longitude,
    bool isGps = false,
  }) async {
    try {
      String url = 'https://wttr.in/?format=j1';
      if (latitude != null && longitude != null) {
        url = 'https://wttr.in/$latitude,$longitude?format=j1';
      }

      final response = await client
          .get(
            Uri.parse(url),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final base = DummyWeatherData.getPrimaryWeather();
        final live = WeatherModel.fromWttrJson(
          data,
          isGps: isGps,
          hourly: base.hourly,
          daily: base.daily,
        );
        return live;
      }
    } catch (e) {
      debugPrint('Live weather notice: $e (memuat data dummy lokal)');
    }

    return DummyWeatherData.getPrimaryWeather();
  }
}
