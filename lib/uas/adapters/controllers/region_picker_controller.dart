import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/region_entity.dart';
import '../../domain/repositories/i_region_repository.dart';
import 'atmosphere_controller.dart';

/// Reactive GetX controller handling Indonesian city search and 4-level wilayah.id cascade.
class RegionPickerController extends GetxController {
  final IRegionRepository _regionRepository;
  final AtmosphereController _atmosphereController;

  RegionPickerController({
    required this._regionRepository,
    required this._atmosphereController,
  });

  final TextEditingController quickSearchController = TextEditingController();
  final RxString quickSearchQuery = ''.obs;

  final RxList<AdminAreaOption> provinces = <AdminAreaOption>[].obs;
  final RxList<AdminAreaOption> regencies = <AdminAreaOption>[].obs;
  final RxList<AdminAreaOption> districts = <AdminAreaOption>[].obs;
  final RxList<AdminAreaOption> villages = <AdminAreaOption>[].obs;

  final Rxn<AdminAreaOption> selectedProvince = Rxn<AdminAreaOption>();
  final Rxn<AdminAreaOption> selectedRegency = Rxn<AdminAreaOption>();
  final Rxn<AdminAreaOption> selectedDistrict = Rxn<AdminAreaOption>();

  final RxBool isLoadingLevel = false.obs;
  final RxnString levelError = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadProvinces();
  }

  void updateQuickSearch(String value) {
    quickSearchQuery.value = value.trim().toLowerCase();
  }

  void clearQuickSearch() {
    quickSearchController.clear();
    quickSearchQuery.value = '';
  }

  List<RegionEntity> get filteredPresets {
    final presets = _regionRepository.getPresetRegions();
    final query = quickSearchQuery.value;
    if (query.isEmpty) return presets;

    return presets.where((region) {
      return region.desa.toLowerCase().contains(query) ||
          region.kecamatan.toLowerCase().contains(query) ||
          region.kotkab.toLowerCase().contains(query) ||
          region.provinsi.toLowerCase().contains(query) ||
          region.adm4.contains(query);
    }).toList();
  }

  Future<void> loadProvinces() async {
    isLoadingLevel.value = true;
    levelError.value = null;
    try {
      final list = await _regionRepository.fetchProvinces();
      provinces.assignAll(list);
    } catch (_) {
      levelError.value =
          'Daftar provinsi wilayah.id gagal dimuat. Gunakan pencarian kota atau coba lagi.';
    } finally {
      isLoadingLevel.value = false;
    }
  }

  Future<void> selectProvince(AdminAreaOption province) async {
    selectedProvince.value = province;
    selectedRegency.value = null;
    selectedDistrict.value = null;
    regencies.clear();
    districts.clear();
    villages.clear();

    isLoadingLevel.value = true;
    levelError.value = null;
    try {
      final list = await _regionRepository.fetchRegencies(province.code);
      regencies.assignAll(list);
    } catch (_) {
      levelError.value = 'Gagal memuat kabupaten/kota untuk ${province.name}.';
    } finally {
      isLoadingLevel.value = false;
    }
  }

  Future<void> selectRegency(AdminAreaOption regency) async {
    selectedRegency.value = regency;
    selectedDistrict.value = null;
    districts.clear();
    villages.clear();

    isLoadingLevel.value = true;
    levelError.value = null;
    try {
      final list = await _regionRepository.fetchDistricts(regency.code);
      districts.assignAll(list);
    } catch (_) {
      levelError.value = 'Gagal memuat kecamatan untuk ${regency.name}.';
    } finally {
      isLoadingLevel.value = false;
    }
  }

  Future<void> selectDistrict(AdminAreaOption district) async {
    selectedDistrict.value = district;
    villages.clear();

    isLoadingLevel.value = true;
    levelError.value = null;
    try {
      final list = await _regionRepository.fetchVillages(district.code);
      villages.assignAll(list);
    } catch (_) {
      levelError.value =
          'Gagal memuat kelurahan/desa untuk ${district.name}.';
    } finally {
      isLoadingLevel.value = false;
    }
  }

  Future<void> selectVillage(AdminAreaOption village) async {
    final province = selectedProvince.value;
    final regency = selectedRegency.value;
    final district = selectedDistrict.value;
    final currentFallback = _atmosphereController.activeRegion.value;

    final newRegion = RegionEntity(
      adm1: province?.code ?? currentFallback.adm1,
      adm2: regency?.code ?? currentFallback.adm2,
      adm3: district?.code ?? currentFallback.adm3,
      adm4: village.code,
      provinsi: province?.name ?? currentFallback.provinsi,
      kotkab: regency?.name ?? currentFallback.kotkab,
      kecamatan: district?.name ?? currentFallback.kecamatan,
      desa: village.name,
      latitude: currentFallback.latitude,
      longitude: currentFallback.longitude,
    );

    await _atmosphereController.selectRegion(newRegion);
  }

  @override
  void onClose() {
    quickSearchController.dispose();
    super.onClose();
  }
}
