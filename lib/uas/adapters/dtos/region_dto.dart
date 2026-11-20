import '../../domain/entities/region_entity.dart';

/// Storage/adapter DTO keeping JSON serialization isolated from pure RegionEntity.
class RegionDto {
  static Map<String, dynamic> toMap(RegionEntity entity) {
    return {
      'adm1': entity.adm1,
      'adm2': entity.adm2,
      'adm3': entity.adm3,
      'adm4': entity.adm4,
      'provinsi': entity.provinsi,
      'kotkab': entity.kotkab,
      'kecamatan': entity.kecamatan,
      'desa': entity.desa,
      'latitude': entity.latitude,
      'longitude': entity.longitude,
      'timezone': entity.timezone,
      'isGpsResolved': entity.isGpsResolved,
    };
  }

  static RegionEntity fromMap(Map<String, dynamic> map) {
    return RegionEntity(
      adm1: map['adm1']?.toString() ?? '',
      adm2: map['adm2']?.toString() ?? '',
      adm3: map['adm3']?.toString() ?? '',
      adm4: map['adm4']?.toString() ?? '',
      provinsi: map['provinsi']?.toString() ?? '',
      kotkab: map['kotkab']?.toString() ?? '',
      kecamatan: map['kecamatan']?.toString() ?? '',
      desa: map['desa']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? -6.1624,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 106.8451,
      timezone: map['timezone']?.toString() ?? 'Asia/Jakarta',
      isGpsResolved: map['isGpsResolved'] == true,
    );
  }
}
