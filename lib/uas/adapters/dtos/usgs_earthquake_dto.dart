import '../../domain/entities/earthquake_entity.dart';

/// Adapter DTO converting USGS Earthquake GeoJSON FeatureCollection payloads
/// into EarthquakeEntity objects.
class UsgsEarthquakeDto {
  static const Map<int, String> _monthNames = {
    1: 'Jan',
    2: 'Feb',
    3: 'Mar',
    4: 'Apr',
    5: 'Mei',
    6: 'Jun',
    7: 'Jul',
    8: 'Agu',
    9: 'Sep',
    10: 'Okt',
    11: 'Nov',
    12: 'Des',
  };

  static List<EarthquakeEntity> parseFeatureCollection(
    Map<String, dynamic> json, {
    int limit = 35,
  }) {
    final features = json['features'] as List<dynamic>? ?? const [];
    final List<EarthquakeEntity> result = [];

    for (final rawFeature in features) {
      if (result.length >= limit) break;
      if (rawFeature is! Map<String, dynamic>) continue;

      final props = rawFeature['properties'] as Map<String, dynamic>?;
      final geometry = rawFeature['geometry'] as Map<String, dynamic>?;
      final coords = geometry?['coordinates'] as List<dynamic>?;
      if (props == null || coords == null || coords.length < 2) continue;

      // GeoJSON coordinates are ordered as [longitude, latitude, depthKm].
      final lon = (coords[0] as num?)?.toDouble();
      final lat = (coords[1] as num?)?.toDouble();
      final depthKm = coords.length >= 3
          ? (coords[2] as num?)?.toDouble() ?? 10.0
          : 10.0;
      final mag = (props['mag'] as num?)?.toDouble();
      if (lon == null || lat == null || mag == null) continue;

      final epochMs = (props['time'] as num?)?.toInt();
      final dt = epochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true).toLocal()
          : DateTime.now();

      final dateStr =
          '${dt.day.toString().padLeft(2, '0')} ${_monthNames[dt.month] ?? ''} ${dt.year}';
      final timeStr =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

      final latText = '${lat.abs().toStringAsFixed(2)} ${lat < 0 ? 'LS' : 'LU'}';
      final lonText = '${lon.abs().toStringAsFixed(2)} ${lon >= 0 ? 'BT' : 'BB'}';
      final mmiNum = props['mmi'] as num?;
      final tsunamiFlag = (props['tsunami'] as num?)?.toInt() == 1;
      final place = props['place']?.toString().trim();

      result.add(
        EarthquakeEntity(
          tanggal: dateStr,
          jam: timeStr,
          dateTime: dt.toIso8601String(),
          coordinates: '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}',
          lintang: latText,
          bujur: lonText,
          magnitude: mag.toStringAsFixed(1),
          kedalaman: '${depthKm.round()} km',
          wilayah: (place != null && place.isNotEmpty)
              ? place
              : 'Global Seismic Event',
          potensi: tsunamiFlag
              ? 'Berpotensi tsunami (USGS Peringatan Tsunami)'
              : 'Tidak ada peringatan tsunami USGS',
          dirasakan:
              mmiNum != null ? 'MMI ${mmiNum.toStringAsFixed(1)}' : null,
          source: 'USGS',
          detailUrl: props['url']?.toString(),
        ),
      );
    }

    return result;
  }
}
