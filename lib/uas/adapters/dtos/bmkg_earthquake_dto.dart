import '../../domain/entities/earthquake_entity.dart';

/// Adapter DTO converting BMKG TEWS earthquake JSON payloads to EarthquakeEntity.
class BmkgEarthquakeDto {
  static EarthquakeEntity fromJson(Map<String, dynamic> json) {
    return EarthquakeEntity(
      tanggal: json['Tanggal']?.toString() ?? '-',
      jam: json['Jam']?.toString() ?? '-',
      dateTime: json['DateTime']?.toString(),
      coordinates: json['Coordinates']?.toString() ?? '0,0',
      lintang: json['Lintang']?.toString() ?? '-',
      bujur: json['Bujur']?.toString() ?? '-',
      magnitude: json['Magnitude']?.toString() ?? '0.0',
      kedalaman: json['Kedalaman']?.toString() ?? '-',
      wilayah: json['Wilayah']?.toString() ?? '-',
      potensi: json['Potensi']?.toString() ?? 'Tidak berpotensi tsunami',
      dirasakan: json['Dirasakan']?.toString(),
      shakemap: json['Shakemap']?.toString(),
    );
  }

  static EarthquakeEntity parseAutoGempaResponse(Map<String, dynamic> json) {
    final info = json['Infogempa'] as Map<String, dynamic>? ?? const {};
    final gempa = info['gempa'] as Map<String, dynamic>?;
    if (gempa == null) {
      throw const FormatException('Missing Infogempa.gempa object.');
    }
    return fromJson(gempa);
  }

  static List<EarthquakeEntity> parseGempaListResponse(
    Map<String, dynamic> json,
  ) {
    final info = json['Infogempa'] as Map<String, dynamic>? ?? const {};
    final rawList = info['gempa'] as List<dynamic>? ?? const [];
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }
}
