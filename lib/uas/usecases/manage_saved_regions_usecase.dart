import '../domain/entities/region_entity.dart';
import '../domain/repositories/i_region_repository.dart';
import '../domain/repositories/i_storage_repository.dart';

/// Persists and deduplicates the user's active Indonesian ADM4 region and favorite cities.
class ManageSavedRegionsUseCase {
  final IStorageRepository _storageRepository;
  final IRegionRepository _regionRepository;

  const ManageSavedRegionsUseCase({
    required this._storageRepository,
    required this._regionRepository,
  });

  static const RegionEntity kemayoranDefault = RegionEntity(
    adm1: '31',
    adm2: '31.71',
    adm3: '31.71.03',
    adm4: '31.71.03.1001',
    provinsi: 'DKI Jakarta',
    kotkab: 'Kota Adm. Jakarta Pusat',
    kecamatan: 'Kemayoran',
    desa: 'Kemayoran',
    latitude: -6.1624,
    longitude: 106.8451,
  );

  Future<RegionEntity> loadActiveRegion() async {
    final saved = await _storageRepository.loadActiveRegion();
    return saved ?? _regionRepository.getDefaultRegion();
  }

  Future<void> setActiveRegion(RegionEntity region) async {
    await _storageRepository.saveActiveRegion(region);
  }

  Future<List<RegionEntity>> loadFavorites() async {
    final saved = await _storageRepository.loadFavoriteRegions();
    if (saved.isNotEmpty) {
      return _deduplicate(saved);
    }
    final defaults = _deduplicate([
      _regionRepository.getDefaultRegion(),
      kemayoranDefault,
    ]);
    await _storageRepository.saveFavoriteRegions(defaults);
    return defaults;
  }

  Future<List<RegionEntity>> toggleFavorite(RegionEntity region) async {
    final current = await loadFavorites();
    final exists = current.any((item) => item.adm4 == region.adm4);
    final updated = exists
        ? current.where((item) => item.adm4 != region.adm4).toList()
        : [region, ...current];
    final deduplicated = _deduplicate(updated);
    await _storageRepository.saveFavoriteRegions(deduplicated);
    return deduplicated;
  }

  List<RegionEntity> _deduplicate(List<RegionEntity> regions) {
    final Map<String, RegionEntity> unique = {};
    for (final region in regions) {
      unique.putIfAbsent(region.adm4, () => region);
    }
    return unique.values.toList();
  }
}
