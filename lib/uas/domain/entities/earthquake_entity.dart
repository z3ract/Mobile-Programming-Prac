/// Pure domain model representing an earthquake event from BMKG TEWS or USGS Global.
class EarthquakeEntity {
  final String tanggal;
  final String jam;
  final String? dateTime;
  final String coordinates;
  final String lintang;
  final String bujur;
  final String magnitude;
  final String kedalaman;
  final String wilayah;
  final String potensi;
  final String? dirasakan;
  final String? shakemap;
  final String source;
  final String? detailUrl;

  const EarthquakeEntity({
    required this.tanggal,
    required this.jam,
    this.dateTime,
    required this.coordinates,
    required this.lintang,
    required this.bujur,
    required this.magnitude,
    required this.kedalaman,
    required this.wilayah,
    required this.potensi,
    this.dirasakan,
    this.shakemap,
    this.source = 'BMKG',
    this.detailUrl,
  });

  bool get isGlobalSource => source.toUpperCase() != 'BMKG';

  double get magnitudeValue => double.tryParse(magnitude.trim()) ?? 0.0;

  double? get latitude {
    final parts = coordinates.split(',');
    if (parts.isEmpty) return null;
    return double.tryParse(parts[0].trim());
  }

  double? get longitude {
    final parts = coordinates.split(',');
    if (parts.length < 2) return null;
    return double.tryParse(parts[1].trim());
  }

  String? get shakemapUrl {
    final raw = shakemap?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return 'https://data.bmkg.go.id/DataMKG/TEWS/$raw';
  }

  bool get hasTsunamiPotential {
    final lower = potensi.toLowerCase();
    return lower.contains('tsunami') && !lower.contains('tidak');
  }

  String get uniqueKey => '${tanggal}_${jam}_$coordinates';
}
