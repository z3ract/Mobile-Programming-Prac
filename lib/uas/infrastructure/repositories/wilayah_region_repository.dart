import 'dart:convert';
import '../../adapters/dtos/open_meteo_geocoding_dto.dart';
import '../../adapters/dtos/wilayah_dto.dart';
import '../../domain/entities/region_entity.dart';
import '../../domain/repositories/i_region_repository.dart';
import '../../domain/utils/meteorology_calculator.dart';
import '../config/bmkg_api_config.dart';
import '../http/bmkg_http_client.dart';

/// Resolves Indonesian Kemendagri ADM1-ADM4 codes via wilayah.id, curated presets,
/// and live global city search via Open-Meteo Geocoding API.
class WilayahRegionRepository implements IRegionRepository {
  final BmkgHttpClient _httpClient;
  final BmkgApiConfig _config;

  const WilayahRegionRepository({
    required this._httpClient,
    required this._config,
  });

  static const String _defaultAdm4 = '35.73.05.1004';

  static const Map<String, RegionEntity> _presetRegistry = {
    '35.73.05.1004': RegionEntity(
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
    ),
    '35.73.01.1001': RegionEntity(
      adm1: '35',
      adm2: '35.73',
      adm3: '35.73.01',
      adm4: '35.73.01.1001',
      provinsi: 'Jawa Timur',
      kotkab: 'Kota Malang',
      kecamatan: 'Blimbing',
      desa: 'Balearjosari',
      latitude: -7.9325,
      longitude: 112.6512,
    ),
    '35.07.12.2007': RegionEntity(
      adm1: '35',
      adm2: '35.07',
      adm3: '35.07.12',
      adm4: '35.07.12.2007',
      provinsi: 'Jawa Timur',
      kotkab: 'Kab. Malang',
      kecamatan: 'Sumberpucung',
      desa: 'Karangkates',
      latitude: -8.1520,
      longitude: 112.4480,
    ),
    '31.71.03.1001': RegionEntity(
      adm1: '31',
      adm2: '31.71',
      adm3: '31.71.03',
      adm4: '31.71.03.1001',
      provinsi: 'DKI Jakarta',
      kotkab: 'Kota Adm. Jakarta Pusat',
      kecamatan: 'Kemayoran',
      desa: 'Kemayoran',
      latitude: -6.1624,
      longitude: 106.8451,
    ),
    '36.71.01.1001': RegionEntity(
      adm1: '36',
      adm2: '36.71',
      adm3: '36.71.01',
      adm4: '36.71.01.1001',
      provinsi: 'Banten',
      kotkab: 'Kota Tangerang',
      kecamatan: 'Tangerang',
      desa: 'Sukarasa',
      latitude: -6.1702,
      longitude: 106.6319,
    ),
    '35.78.04.1001': RegionEntity(
      adm1: '35',
      adm2: '35.78',
      adm3: '35.78.04',
      adm4: '35.78.04.1001',
      provinsi: 'Jawa Timur',
      kotkab: 'Kota Surabaya',
      kecamatan: 'Wonokromo',
      desa: 'Wonokromo',
      latitude: -7.2994,
      longitude: 112.7358,
    ),
    '32.73.09.1001': RegionEntity(
      adm1: '32',
      adm2: '32.73',
      adm3: '32.73.09',
      adm4: '32.73.09.1001',
      provinsi: 'Jawa Barat',
      kotkab: 'Kota Bandung',
      kecamatan: 'Bandung Wetan',
      desa: 'Cihapit',
      latitude: -6.9096,
      longitude: 107.6214,
    ),
    '34.71.01.1001': RegionEntity(
      adm1: '34',
      adm2: '34.71',
      adm3: '34.71.01',
      adm4: '34.71.01.1001',
      provinsi: 'DI Yogyakarta',
      kotkab: 'Kota Yogyakarta',
      kecamatan: 'Tegalrejo',
      desa: 'Kricak',
      latitude: -7.7798,
      longitude: 110.3578,
    ),
    '33.74.01.1001': RegionEntity(
      adm1: '33',
      adm2: '33.74',
      adm3: '33.74.01',
      adm4: '33.74.01.1001',
      provinsi: 'Jawa Tengah',
      kotkab: 'Kota Semarang',
      kecamatan: 'Semarang Tengah',
      desa: 'Miroto',
      latitude: -6.9822,
      longitude: 110.4158,
    ),
    '51.71.01.1001': RegionEntity(
      adm1: '51',
      adm2: '51.71',
      adm3: '51.71.01',
      adm4: '51.71.01.1001',
      provinsi: 'Bali',
      kotkab: 'Kota Denpasar',
      kecamatan: 'Denpasar Selatan',
      desa: 'Serangan',
      latitude: -8.7289,
      longitude: 115.2356,
      timezone: 'Asia/Makassar',
    ),
    '12.71.01.1001': RegionEntity(
      adm1: '12',
      adm2: '12.71',
      adm3: '12.71.01',
      adm4: '12.71.01.1001',
      provinsi: 'Sumatera Utara',
      kotkab: 'Kota Medan',
      kecamatan: 'Medan Kota',
      desa: 'Pasar Baru',
      latitude: 3.5833,
      longitude: 98.6833,
    ),
    '64.71.01.1001': RegionEntity(
      adm1: '64',
      adm2: '64.71',
      adm3: '64.71.01',
      adm4: '64.71.01.1001',
      provinsi: 'Kalimantan Timur',
      kotkab: 'Kota Balikpapan',
      kecamatan: 'Balikpapan Timur',
      desa: 'Manggar',
      latitude: -1.2167,
      longitude: 116.9500,
      timezone: 'Asia/Makassar',
    ),
    '61.02.18.1001': RegionEntity(
      adm1: '61',
      adm2: '61.02',
      adm3: '61.02.18',
      adm4: '61.02.18.1001',
      provinsi: 'Kalimantan Barat',
      kotkab: 'Kab. Mempawah',
      kecamatan: 'Mempawah Timur',
      desa: 'Pulau Pedalaman',
      latitude: 0.3510,
      longitude: 108.9550,
    ),
    '73.71.01.1001': RegionEntity(
      adm1: '73',
      adm2: '73.71',
      adm3: '73.71.01',
      adm4: '73.71.01.1001',
      provinsi: 'Sulawesi Selatan',
      kotkab: 'Kota Makassar',
      kecamatan: 'Mariso',
      desa: 'Bontorannu',
      latitude: -5.1583,
      longitude: 119.4092,
      timezone: 'Asia/Makassar',
    ),
    '71.71.01.1001': RegionEntity(
      adm1: '71',
      adm2: '71.71',
      adm3: '71.71.01',
      adm4: '71.71.01.1001',
      provinsi: 'Sulawesi Utara',
      kotkab: 'Kota Manado',
      kecamatan: 'Bunaken',
      desa: 'Molas',
      latitude: 1.5439,
      longitude: 124.8439,
      timezone: 'Asia/Makassar',
    ),
    '91.71.01.1001': RegionEntity(
      adm1: '91',
      adm2: '91.71',
      adm3: '91.71.01',
      adm4: '91.71.01.1001',
      provinsi: 'Papua',
      kotkab: 'Kota Jayapura',
      kecamatan: 'Jayapura Utara',
      desa: 'Gurabesi',
      latitude: -2.5337,
      longitude: 140.7181,
      timezone: 'Asia/Jayapura',
    ),
    'GLOBAL:JP:1850147': RegionEntity(
      adm1: 'JP',
      adm2: 'Tokyo',
      adm3: 'Tokyo',
      adm4: 'GLOBAL:JP:1850147',
      provinsi: 'Tokyo',
      kotkab: 'Tokyo',
      kecamatan: 'Shinjuku',
      desa: 'Tokyo',
      latitude: 35.6762,
      longitude: 139.6503,
      timezone: 'Asia/Tokyo',
      country: 'Japan',
      countryCode: 'JP',
      isGlobal: true,
    ),
    'GLOBAL:SG:1880252': RegionEntity(
      adm1: 'SG',
      adm2: 'Singapore',
      adm3: 'Central',
      adm4: 'GLOBAL:SG:1880252',
      provinsi: 'Singapore',
      kotkab: 'Singapore',
      kecamatan: 'Marina Bay',
      desa: 'Singapore',
      latitude: 1.3521,
      longitude: 103.8198,
      timezone: 'Asia/Singapore',
      country: 'Singapore',
      countryCode: 'SG',
      isGlobal: true,
    ),
    'GLOBAL:MY:1735161': RegionEntity(
      adm1: 'MY',
      adm2: 'Kuala Lumpur',
      adm3: 'Kuala Lumpur',
      adm4: 'GLOBAL:MY:1735161',
      provinsi: 'WP Kuala Lumpur',
      kotkab: 'Kuala Lumpur',
      kecamatan: 'City Centre',
      desa: 'Kuala Lumpur',
      latitude: 3.1390,
      longitude: 101.6869,
      timezone: 'Asia/Kuala_Lumpur',
      country: 'Malaysia',
      countryCode: 'MY',
      isGlobal: true,
    ),
    'GLOBAL:SA:104515': RegionEntity(
      adm1: 'SA',
      adm2: 'Makkah',
      adm3: 'Makkah',
      adm4: 'GLOBAL:SA:104515',
      provinsi: 'Makkah Region',
      kotkab: 'Makkah',
      kecamatan: 'Al Haram',
      desa: 'Makkah',
      latitude: 21.4225,
      longitude: 39.8262,
      timezone: 'Asia/Riyadh',
      country: 'Saudi Arabia',
      countryCode: 'SA',
      isGlobal: true,
    ),
    'GLOBAL:GB:2643743': RegionEntity(
      adm1: 'GB',
      adm2: 'Greater London',
      adm3: 'London',
      adm4: 'GLOBAL:GB:2643743',
      provinsi: 'England',
      kotkab: 'London',
      kecamatan: 'Westminster',
      desa: 'London',
      latitude: 51.5074,
      longitude: -0.1278,
      timezone: 'Europe/London',
      country: 'United Kingdom',
      countryCode: 'GB',
      isGlobal: true,
    ),
    'GLOBAL:US:5128581': RegionEntity(
      adm1: 'US',
      adm2: 'New York',
      adm3: 'Manhattan',
      adm4: 'GLOBAL:US:5128581',
      provinsi: 'New York',
      kotkab: 'New York',
      kecamatan: 'Midtown',
      desa: 'New York',
      latitude: 40.7128,
      longitude: -74.0060,
      timezone: 'America/New_York',
      country: 'United States',
      countryCode: 'US',
      isGlobal: true,
    ),
    'GLOBAL:AU:2147714': RegionEntity(
      adm1: 'AU',
      adm2: 'New South Wales',
      adm3: 'Sydney',
      adm4: 'GLOBAL:AU:2147714',
      provinsi: 'New South Wales',
      kotkab: 'Sydney',
      kecamatan: 'Sydney CBD',
      desa: 'Sydney',
      latitude: -33.8688,
      longitude: 151.2093,
      timezone: 'Australia/Sydney',
      country: 'Australia',
      countryCode: 'AU',
      isGlobal: true,
    ),
    'GLOBAL:KR:1835848': RegionEntity(
      adm1: 'KR',
      adm2: 'Seoul',
      adm3: 'Jung-gu',
      adm4: 'GLOBAL:KR:1835848',
      provinsi: 'Seoul',
      kotkab: 'Seoul',
      kecamatan: 'Seoul',
      desa: 'Seoul',
      latitude: 37.5665,
      longitude: 126.9780,
      timezone: 'Asia/Seoul',
      country: 'South Korea',
      countryCode: 'KR',
      isGlobal: true,
    ),
  };

  @override
  List<RegionEntity> getPresetRegions() => _presetRegistry.values.toList();

  @override
  RegionEntity getDefaultRegion() => _presetRegistry[_defaultAdm4]!;

  @override
  RegionEntity findNearestPreset(double latitude, double longitude) {
    RegionEntity best = getDefaultRegion();
    double bestDistance = double.infinity;

    for (final preset in _presetRegistry.values.where((r) => !r.isGlobal)) {
      final km = MeteorologyCalculator.calculateDistanceKm(
        latitude,
        longitude,
        preset.latitude,
        preset.longitude,
      );
      if (km < bestDistance) {
        bestDistance = km;
        best = preset;
      }
    }
    return best;
  }

  @override
  Future<List<RegionEntity>> searchGlobalRegions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    final body = await _httpClient.getBody(
      _config.openMeteoGeocodingUri(trimmed),
      ttl: _config.wilayahCacheTtl,
      acceptHeader: 'application/json',
    );
    return OpenMeteoGeocodingDto.parseSearchResponse(
      json.decode(body) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<AdminAreaOption>> fetchProvinces() async {
    final body = await _httpClient.getBody(
      _config.provincesUri(),
      ttl: _config.wilayahCacheTtl,
      acceptHeader: 'application/json',
    );
    return WilayahDto.parseList(
      json.decode(body) as Map<String, dynamic>,
      level: 1,
    );
  }

  @override
  Future<List<AdminAreaOption>> fetchRegencies(String provinceCode) async {
    final body = await _httpClient.getBody(
      _config.regenciesUri(provinceCode),
      ttl: _config.wilayahCacheTtl,
      acceptHeader: 'application/json',
    );
    return WilayahDto.parseList(
      json.decode(body) as Map<String, dynamic>,
      level: 2,
    );
  }

  @override
  Future<List<AdminAreaOption>> fetchDistricts(String regencyCode) async {
    final body = await _httpClient.getBody(
      _config.districtsUri(regencyCode),
      ttl: _config.wilayahCacheTtl,
      acceptHeader: 'application/json',
    );
    return WilayahDto.parseList(
      json.decode(body) as Map<String, dynamic>,
      level: 3,
    );
  }

  @override
  Future<List<AdminAreaOption>> fetchVillages(String districtCode) async {
    final body = await _httpClient.getBody(
      _config.villagesUri(districtCode),
      ttl: _config.wilayahCacheTtl,
      acceptHeader: 'application/json',
    );
    return WilayahDto.parseList(
      json.decode(body) as Map<String, dynamic>,
      level: 4,
    );
  }

  @override
  Future<RegionEntity?> resolveByCoordinates({
    required double latitude,
    required double longitude,
    String? adminAreaHint,
    String? subAdminAreaHint,
    String? districtHint,
    String? villageHint,
    String? localityHint,
  }) async {
    try {
      if (adminAreaHint == null || adminAreaHint.trim().isEmpty) {
        return null;
      }

      final provinces = await fetchProvinces();
      final matchedProvince = _findBestMatch(provinces, adminAreaHint);
      if (matchedProvince == null) {
        return null;
      }

      final regencies = await fetchRegencies(matchedProvince.code);
      final matchedRegency = _findBestMatch(
        regencies,
        subAdminAreaHint ?? districtHint ?? localityHint ?? '',
      );
      if (matchedRegency == null) {
        return null;
      }

      final districts = await fetchDistricts(matchedRegency.code);
      if (districts.isEmpty) {
        return null;
      }
      final matchedDistrict = _findBestMatch(
        districts,
        districtHint ?? localityHint ?? '',
      );
      if (matchedDistrict == null) {
        return null;
      }

      final villages = await fetchVillages(matchedDistrict.code);
      if (villages.isEmpty) {
        return null;
      }
      final matchedVillage = _findBestMatch(
        villages,
        villageHint ?? localityHint ?? '',
      );
      if (matchedVillage == null) {
        return null;
      }

      return RegionEntity(
        adm1: matchedProvince.code,
        adm2: matchedRegency.code,
        adm3: matchedDistrict.code,
        adm4: matchedVillage.code,
        provinsi: matchedProvince.name,
        kotkab: matchedRegency.name,
        kecamatan: matchedDistrict.name,
        desa: matchedVillage.name,
        latitude: latitude,
        longitude: longitude,
        isGpsResolved: true,
      );
    } catch (_) {
      return null;
    }
  }

  AdminAreaOption? _findBestMatch(
    List<AdminAreaOption> options,
    String rawHint,
  ) {
    final hint = _normalizeAdminLabel(rawHint);
    if (hint.isEmpty) return null;

    for (final option in options) {
      final candidate = _normalizeAdminLabel(option.name);
      if (candidate == hint ||
          candidate.contains(hint) ||
          hint.contains(candidate)) {
        return option;
      }
    }
    return null;
  }

  String _normalizeAdminLabel(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('east java', 'jawa timur')
        .replaceAll('west java', 'jawa barat')
        .replaceAll('central java', 'jawa tengah')
        .replaceAll('special region of yogyakarta', 'di yogyakarta')
        .replaceAll('special capital region of jakarta', 'dki jakarta')
        .replaceAll(
          RegExp(
            r'\b(provinsi|kota administrasi|kota adm\.|kota|kabupaten|kab\.|kecamatan|kec\.|kelurahan|kel\.|desa)\b',
          ),
          ' ',
        )
        .replaceAll('jakarta', 'dki jakarta')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
