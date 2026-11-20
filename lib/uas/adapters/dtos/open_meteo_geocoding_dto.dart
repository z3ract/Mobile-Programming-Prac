import '../../domain/entities/region_entity.dart';

/// Adapter DTO converting Open-Meteo Geocoding search results into RegionEntity items.
class OpenMeteoGeocodingDto {
  static List<RegionEntity> parseSearchResponse(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];
    final List<RegionEntity> regions = [];

    for (final item in rawResults) {
      if (item is! Map<String, dynamic>) continue;

      final name = item['name']?.toString().trim() ?? '';
      final lat = (item['latitude'] as num?)?.toDouble();
      final lon = (item['longitude'] as num?)?.toDouble();
      if (name.isEmpty || lat == null || lon == null) continue;

      final country = item['country']?.toString().trim() ?? '';
      final countryCode =
          item['country_code']?.toString().trim().toUpperCase() ?? '';
      final admin1 = item['admin1']?.toString().trim() ?? '';
      final admin2 = item['admin2']?.toString().trim() ?? '';
      final timezone = item['timezone']?.toString().trim() ?? 'auto';
      final id = item['id']?.toString() ??
          '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';

      final resolvedCountry = country.isNotEmpty ? country : 'Global';
      final resolvedProvince =
          admin1.isNotEmpty ? admin1 : resolvedCountry;
      final resolvedCity = admin2.isNotEmpty
          ? admin2
          : (admin1.isNotEmpty ? admin1 : resolvedCountry);

      regions.add(
        RegionEntity(
          adm1: countryCode.isEmpty ? 'XX' : countryCode,
          adm2: admin1,
          adm3: admin2,
          adm4: 'GLOBAL:${countryCode.isEmpty ? 'XX' : countryCode}:$id',
          provinsi: resolvedProvince,
          kotkab: resolvedCity,
          kecamatan: admin2,
          desa: name,
          latitude: lat,
          longitude: lon,
          timezone: timezone,
          country: resolvedCountry,
          countryCode: countryCode,
          isGlobal: countryCode != 'ID',
        ),
      );
    }

    return regions;
  }
}
