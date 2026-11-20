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

/// Resolves live GPS coordinates into the closest valid BMKG Indonesian adm4 region.
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

    if (!MeteorologyCalculator.isWithinIndonesiaBounds(
      coords.latitude,
      coords.longitude,
    )) {
      return GpsRegionResolution(
        region: fallbackRegion,
        isGpsSuccess: false,
        isOutsideIndonesia: true,
        statusMessage:
            'Lokasi GPS (${coords.latitude.toStringAsFixed(2)}, ${coords.longitude.toStringAsFixed(2)}) berada di luar cakupan layanan BMKG Indonesia.',
      );
    }

    final reverseHint = await _locationProvider.reverseGeocode(
      coords.latitude,
      coords.longitude,
    );

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
}
