import '../domain/entities/region_entity.dart';
import '../domain/repositories/i_region_repository.dart';
import '../domain/services/i_location_provider.dart';
import '../domain/utils/meteorology_calculator.dart';

/// Outcome of attempting to map device GPS coordinates to an Indonesian ADM4 region.
class GpsRegionResolution {
  final RegionEntity? region;
  final bool isGpsSuccess;
  final bool isOutsideIndonesia;
  final String statusMessage;

  const GpsRegionResolution({
    required this.region,
    required this.isGpsSuccess,
    required this.isOutsideIndonesia,
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

  Future<GpsRegionResolution> execute({
    required RegionEntity fallbackRegion,
  }) async {
    final coords = await _locationProvider.getCurrentCoordinates();
    if (coords == null) {
      return GpsRegionResolution(
        region: null,
        isGpsSuccess: false,
        isOutsideIndonesia: false,
        statusMessage:
            'Layanan GPS tidak aktif atau izin lokasi belum diberikan.',
      );
    }

    final reverseHint = await _locationProvider.reverseGeocode(
      coords.latitude,
      coords.longitude,
    );

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
            'Lokasi GPS global terdeteksi di ${globalRegion.displayTitle}, ${globalRegion.country}.',
      );
    }

    final resolved = await _regionRepository.resolveByCoordinates(
      latitude: coords.latitude,
      longitude: coords.longitude,
      adminAreaHint: reverseHint?.provinceHint,
      subAdminAreaHint: reverseHint?.cityHint,
      localityHint: reverseHint?.villageHint ?? reverseHint?.districtHint,
    );

    final target = resolved ??
        _regionRepository.findNearestPreset(coords.latitude, coords.longitude);

    final localizedRegion = target.copyWith(
      latitude: coords.latitude,
      longitude: coords.longitude,
      isGpsResolved: true,
    );

    return GpsRegionResolution(
      region: localizedRegion,
      isGpsSuccess: true,
      isOutsideIndonesia: false,
      statusMessage:
          'Lokasi GPS terdeteksi di ${localizedRegion.displayTitle}, ${localizedRegion.kotkab}.',
    );
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
