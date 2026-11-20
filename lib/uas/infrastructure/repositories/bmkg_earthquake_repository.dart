import 'dart:convert';
import '../../adapters/dtos/bmkg_earthquake_dto.dart';
import '../../domain/entities/earthquake_entity.dart';
import '../../domain/repositories/i_earthquake_repository.dart';
import '../config/bmkg_api_config.dart';
import '../http/bmkg_http_client.dart';

/// Fetches live earthquake telemetry feeds from data.bmkg.go.id/DataMKG/TEWS.
class BmkgEarthquakeRepository implements IEarthquakeRepository {
  final BmkgHttpClient _httpClient;
  final BmkgApiConfig _config;

  const BmkgEarthquakeRepository({
    required this._httpClient,
    required this._config,
  });

  @override
  Future<EarthquakeEntity> fetchAutoGempa({bool forceRefresh = false}) async {
    final body = await _httpClient.getBody(
      Uri.parse(_config.tewsAutoGempaUrl),
      ttl: _config.seismicCacheTtl,
      forceRefresh: forceRefresh,
      acceptHeader: 'application/json',
    );
    final decoded = json.decode(body) as Map<String, dynamic>;
    return BmkgEarthquakeDto.parseAutoGempaResponse(decoded);
  }

  @override
  Future<List<EarthquakeEntity>> fetchGempaTerkini({
    bool forceRefresh = false,
  }) async {
    final body = await _httpClient.getBody(
      Uri.parse(_config.tewsGempaTerkiniUrl),
      ttl: _config.seismicCacheTtl,
      forceRefresh: forceRefresh,
      acceptHeader: 'application/json',
    );
    final decoded = json.decode(body) as Map<String, dynamic>;
    return BmkgEarthquakeDto.parseGempaListResponse(decoded);
  }

  @override
  Future<List<EarthquakeEntity>> fetchGempaDirasakan({
    bool forceRefresh = false,
  }) async {
    final body = await _httpClient.getBody(
      Uri.parse(_config.tewsGempaDirasakanUrl),
      ttl: _config.seismicCacheTtl,
      forceRefresh: forceRefresh,
      acceptHeader: 'application/json',
    );
    final decoded = json.decode(body) as Map<String, dynamic>;
    return BmkgEarthquakeDto.parseGempaListResponse(decoded);
  }
}
