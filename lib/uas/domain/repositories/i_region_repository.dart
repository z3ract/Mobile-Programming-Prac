import '../entities/region_entity.dart';

/// Contract for resolving Indonesian Kemendagri ADM1-ADM4 codes and presets.
abstract interface class IRegionRepository {
  List<RegionEntity> getPresetRegions();
  RegionEntity getDefaultRegion();
  RegionEntity findNearestPreset(double latitude, double longitude);
  Future<List<AdminAreaOption>> fetchProvinces();
  Future<List<AdminAreaOption>> fetchRegencies(String provinceCode);
  Future<List<AdminAreaOption>> fetchDistricts(String regencyCode);
  Future<List<AdminAreaOption>> fetchVillages(String districtCode);
  Future<RegionEntity?> resolveByCoordinates({
    required double latitude,
    required double longitude,
    String? adminAreaHint,
    String? subAdminAreaHint,
    String? localityHint,
  });
}
