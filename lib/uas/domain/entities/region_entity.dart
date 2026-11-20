/// Pure domain representation of an Indonesian administrative region (Kepmendagri ADM1-ADM4).
class RegionEntity {
  final String adm1;
  final String adm2;
  final String adm3;
  final String adm4;
  final String provinsi;
  final String kotkab;
  final String kecamatan;
  final String desa;
  final double latitude;
  final double longitude;
  final String timezone;
  final bool isGpsResolved;

  const RegionEntity({
    required this.adm1,
    required this.adm2,
    required this.adm3,
    required this.adm4,
    required this.provinsi,
    required this.kotkab,
    required this.kecamatan,
    required this.desa,
    required this.latitude,
    required this.longitude,
    this.timezone = 'Asia/Jakarta',
    this.isGpsResolved = false,
  });

  String get displayTitle => desa.isNotEmpty ? desa : kotkab;

  String get displaySubtitle {
    final parts = [kecamatan, kotkab].where((e) => e.trim().isNotEmpty).toList();
    return parts.isEmpty ? provinsi : parts.join(', ');
  }

  RegionEntity copyWith({
    String? adm1,
    String? adm2,
    String? adm3,
    String? adm4,
    String? provinsi,
    String? kotkab,
    String? kecamatan,
    String? desa,
    double? latitude,
    double? longitude,
    String? timezone,
    bool? isGpsResolved,
  }) {
    return RegionEntity(
      adm1: adm1 ?? this.adm1,
      adm2: adm2 ?? this.adm2,
      adm3: adm3 ?? this.adm3,
      adm4: adm4 ?? this.adm4,
      provinsi: provinsi ?? this.provinsi,
      kotkab: kotkab ?? this.kotkab,
      kecamatan: kecamatan ?? this.kecamatan,
      desa: desa ?? this.desa,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      isGpsResolved: isGpsResolved ?? this.isGpsResolved,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegionEntity && other.adm4 == adm4;
  }

  @override
  int get hashCode => adm4.hashCode;
}

/// Represents a selectable administrative unit from wilayah.id (level 1..4).
class AdminAreaOption {
  final String code;
  final String name;
  final int level;

  const AdminAreaOption({
    required this.code,
    required this.name,
    required this.level,
  });
}
