import 'dart:convert';
import '../../adapters/dtos/wilayah_dto.dart';
import '../../domain/entities/region_entity.dart';
import '../../domain/repositories/i_region_repository.dart';
import '../../domain/utils/meteorology_calculator.dart';
import '../config/bmkg_api_config.dart';
import '../http/bmkg_http_client.dart';

/// Resolves Indonesian Kemendagri ADM1-ADM4 codes via wilayah.id and O(1) verified presets.
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
  };

  @override
  List<RegionEntity> getPresetRegions() => _presetRegistry.values.toList();

  @override
  RegionEntity getDefaultRegion() => _presetRegistry[_defaultAdm4]!;

  @override
  RegionEntity findNearestPreset(double latitude, double longitude) {
    RegionEntity best = getDefaultRegion();
    double bestDistance = double.infinity;

    for (final preset in _presetRegistry.values) {
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
    String? localityHint,
  }) async {
    try {
      if (adminAreaHint == null || adminAreaHint.trim().isEmpty) {
        return findNearestPreset(latitude, longitude);
      }

      final provinces = await fetchProvinces();
      final matchedProvince = _findBestMatch(provinces, adminAreaHint);
      if (matchedProvince == null) {
        return findNearestPreset(latitude, longitude);
      }

      final regencies = await fetchRegencies(matchedProvince.code);
      final matchedRegency = _findBestMatch(
        regencies,
        subAdminAreaHint ?? localityHint ?? '',
      );
      if (matchedRegency == null) {
        return findNearestPreset(latitude, longitude);
      }

      final districts = await fetchDistricts(matchedRegency.code);
      if (districts.isEmpty) {
        return findNearestPreset(latitude, longitude);
      }
      final matchedDistrict =
          _findBestMatch(districts, localityHint ?? '') ?? districts.first;

      final villages = await fetchVillages(matchedDistrict.code);
      if (villages.isEmpty) {
        return findNearestPreset(latitude, longitude);
      }
      final matchedVillage =
          _findBestMatch(villages, localityHint ?? '') ?? villages.first;

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
      return findNearestPreset(latitude, longitude);
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
