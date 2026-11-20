import '../domain/entities/region_entity.dart';
import '../domain/repositories/i_region_repository.dart';
import '../domain/services/i_location_provider.dart';
import '../domain/utils/meteorology_calculator.dart';

/// Outcome of attempting to map device GPS coordinates to an Indonesian ADM4 or global region.
class GpsRegionResolution {
  final RegionEntity? region;
  final bool isGpsSuccess;
  final bool isOutsideIndonesia;
  final GpsErrorType errorType;
  final String statusMessage;

  const GpsRegionResolution({
    required this.region,
    required this.isGpsSuccess,
    required this.isOutsideIndonesia,
    this.errorType = GpsErrorType.none,
    required this.statusMessage,
  });
}

/// Resolves live GPS coordinates into an Indonesian ADM4 region (inside Indonesia)
/// or a localized global weather region anywhere in the world.
class ResolveGpsRegionUseCase {
  final ILocationProvider _locationProvider;
  final IRegionRepository _regionRepository;

  const ResolveGpsRegionUseCase({
    required this._locationProvider,
    required this._regionRepository,
  });

  static const Map<GpsErrorType, String> _errorMessages = {
    GpsErrorType.serviceDisabled:
        'Layanan lokasi (GPS) perangkat sedang nonaktif. Aktifkan Lokasi di pengaturan.',
    GpsErrorType.permissionDenied:
        'Izin akses lokasi ditolak. Berikan izin lokasi untuk mendeteksi posisi Anda.',
    GpsErrorType.permissionDeniedForever:
        'Izin lokasi ditolak permanen oleh sistem. Buka Pengaturan Izin untuk mengaktifkannya.',
    GpsErrorType.timeout:
        'Waktu pencarian sinyal GPS habis. Coba di area terbuka atau pilih kota secara manual.',
    GpsErrorType.unsupportedPlatform:
        'Sensor GPS tidak didukung pada platform ini. Pilih kota lewat pencarian atau Peta.',
    GpsErrorType.unknown: 'Gagal mendeteksi koordinat GPS perangkat.',
  };

  static const Map<String, String> _indonesianProvinceAlias = {
    'east java': 'Jawa Timur',
    'west java': 'Jawa Barat',
    'central java': 'Jawa Tengah',
    'special region of yogyakarta': 'DI Yogyakarta',
    'special capital region of jakarta': 'DKI Jakarta',
    'jakarta': 'DKI Jakarta',
    'north sumatra': 'Sumatera Utara',
    'west sumatra': 'Sumatera Barat',
    'south sumatra': 'Sumatera Selatan',
    'south sulawesi': 'Sulawesi Selatan',
    'north sulawesi': 'Sulawesi Utara',
    'east kalimantan': 'Kalimantan Timur',
    'west kalimantan': 'Kalimantan Barat',
    'south kalimantan': 'Kalimantan Selatan',
  };

  Future<GpsRegionResolution> execute({
    required RegionEntity fallbackRegion,
  }) async {
    final attempt = await _locationProvider.acquireCurrentLocation();
    final coords = attempt.fix;
    if (!attempt.isSuccess || coords == null) {
      final baseMessage =
          _errorMessages[attempt.errorType] ?? _errorMessages[GpsErrorType.unknown]!;
      final detail = attempt.diagnosticDetail?.trim();
      final fullMessage = (attempt.errorType == GpsErrorType.unknown &&
              detail != null &&
              detail.isNotEmpty)
          ? '$baseMessage ($detail)'
          : baseMessage;

      return GpsRegionResolution(
        region: null,
        isGpsSuccess: false,
        isOutsideIndonesia: false,
        errorType: attempt.errorType,
        statusMessage: fullMessage,
      );
    }

    final reverseHint = await _locationProvider.reverseGeocode(
      coords.latitude,
      coords.longitude,
    );
    final accuracySuffix =
        (coords.accuracyMeters != null && coords.accuracyMeters! > 0)
            ? ' (akurasi ±${coords.accuracyMeters!.round()} m)'
            : '';

    if (!MeteorologyCalculator.isWithinIndonesiaBounds(
      coords.latitude,
      coords.longitude,
    )) {
      final latStr = coords.latitude.toStringAsFixed(3);
      final lonStr = coords.longitude.toStringAsFixed(3);
      final country = _firstNonEmpty([reverseHint?.countryHint]) ?? 'Global';
      final province =
          _firstNonEmpty([reverseHint?.provinceHint, country]) ?? 'Global';
      final city = _firstNonEmpty([
            reverseHint?.cityHint,
            reverseHint?.provinceHint,
            country,
          ]) ??
          'Global';
      final title = _firstNonEmpty([
            reverseHint?.villageHint,
            reverseHint?.cityHint,
            reverseHint?.provinceHint,
            reverseHint?.countryHint,
          ]) ??
          'Lokasi GPS';
      final countryCode =
          (reverseHint?.countryCodeHint ?? '').trim().toUpperCase();

      final globalRegion = RegionEntity(
        adm1: countryCode.isEmpty ? 'XX' : countryCode,
        adm2: province,
        adm3: reverseHint?.districtHint?.trim() ?? '',
        adm4: 'COORD:$latStr,$lonStr',
        provinsi: province,
        kotkab: city,
        kecamatan: reverseHint?.districtHint?.trim() ?? '',
        desa: title,
        latitude: coords.latitude,
        longitude: coords.longitude,
        timezone: 'auto',
        isGpsResolved: true,
        country: country,
        countryCode: countryCode,
        isGlobal: true,
      );

      return GpsRegionResolution(
        region: globalRegion,
        isGpsSuccess: true,
        isOutsideIndonesia: true,
        statusMessage:
            'Lokasi GPS global terdeteksi di ${globalRegion.displayTitle}, ${globalRegion.country}$accuracySuffix.',
      );
    }

    final normalizedProvinceHint = _normalizeProvinceName(
      reverseHint?.provinceHint,
      fallback: '',
    );

    final resolved = await _regionRepository
        .resolveByCoordinates(
          latitude: coords.latitude,
          longitude: coords.longitude,
          adminAreaHint: normalizedProvinceHint.isNotEmpty
              ? normalizedProvinceHint
              : reverseHint?.provinceHint,
          subAdminAreaHint: reverseHint?.cityHint,
          districtHint: reverseHint?.districtHint,
          villageHint: reverseHint?.villageHint,
          localityHint: reverseHint?.villageHint ?? reverseHint?.districtHint,
        )
        .timeout(const Duration(seconds: 5), onTimeout: () => null);

    late final RegionEntity localizedRegion;
    if (resolved != null) {
      localizedRegion = resolved.copyWith(
        latitude: coords.latitude,
        longitude: coords.longitude,
        isGpsResolved: true,
      );
    } else if (_firstNonEmpty([
          reverseHint?.villageHint,
          reverseHint?.districtHint,
          reverseHint?.cityHint,
        ]) !=
        null) {
      final latStr = coords.latitude.toStringAsFixed(3);
      final lonStr = coords.longitude.toStringAsFixed(3);
      final province = _normalizeProvinceName(
        reverseHint?.provinceHint,
        fallback: 'Indonesia',
      );
      final district = reverseHint?.districtHint?.trim() ?? '';
      final city = _firstNonEmpty([
            reverseHint?.cityHint,
            district.isNotEmpty ? district : null,
            province,
          ]) ??
          'Indonesia';
      final village = _firstNonEmpty([
            reverseHint?.villageHint,
            district.isNotEmpty ? district : null,
            reverseHint?.cityHint,
          ]) ??
          'Lokasi GPS';
      localizedRegion = RegionEntity(
        adm1: 'ID',
        adm2: city,
        adm3: district,
        adm4: 'COORD:$latStr,$lonStr',
        provinsi: province,
        kotkab: city,
        kecamatan: district,
        desa: village,
        latitude: coords.latitude,
        longitude: coords.longitude,
        timezone: 'auto',
        isGpsResolved: true,
        country: 'Indonesia',
        countryCode: 'ID',
        isGlobal: false,
      );
    } else {
      final nearest = _regionRepository.findNearestPreset(
        coords.latitude,
        coords.longitude,
      );
      final kmToNearest = MeteorologyCalculator.calculateDistanceKm(
        coords.latitude,
        coords.longitude,
        nearest.latitude,
        nearest.longitude,
      );
      if (kmToNearest <= 25.0) {
        localizedRegion = nearest.copyWith(
          latitude: coords.latitude,
          longitude: coords.longitude,
          isGpsResolved: true,
        );
      } else {
        final latStr = coords.latitude.toStringAsFixed(3);
        final lonStr = coords.longitude.toStringAsFixed(3);
        localizedRegion = RegionEntity(
          adm1: 'ID',
          adm2: '$latStr, $lonStr',
          adm3: '',
          adm4: 'COORD:$latStr,$lonStr',
          provinsi: 'Indonesia',
          kotkab: '$latStr, $lonStr',
          kecamatan: '',
          desa: 'Lokasi GPS',
          latitude: coords.latitude,
          longitude: coords.longitude,
          timezone: 'auto',
          isGpsResolved: true,
          country: 'Indonesia',
          countryCode: 'ID',
          isGlobal: false,
        );
      }
    }

    return GpsRegionResolution(
      region: localizedRegion,
      isGpsSuccess: true,
      isOutsideIndonesia: false,
      statusMessage:
          'Lokasi GPS terdeteksi di ${localizedRegion.displayTitle}, ${localizedRegion.kotkab}$accuracySuffix.',
    );
  }

  String _normalizeProvinceName(String? raw, {String fallback = 'Indonesia'}) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return fallback;
    return _indonesianProvinceAlias[trimmed.toLowerCase()] ?? trimmed;
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
