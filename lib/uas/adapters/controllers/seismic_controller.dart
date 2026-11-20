import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/earthquake_entity.dart';
import '../../domain/repositories/i_earthquake_repository.dart';
import '../../domain/utils/meteorology_calculator.dart';
import 'atmosphere_controller.dart';

/// Reactive GetX controller for BMKG TEWS (Indonesia) and USGS (Global) earthquake feeds.
class SeismicController extends GetxController {
  final IEarthquakeRepository _earthquakeRepository;
  final AtmosphereController _atmosphereController;

  SeismicController({
    required this._earthquakeRepository,
    required this._atmosphereController,
  });

  final TextEditingController searchController = TextEditingController();

  final Rxn<EarthquakeEntity> autoGempa = Rxn<EarthquakeEntity>();
  final RxList<EarthquakeEntity> gempaTerkini = <EarthquakeEntity>[].obs;
  final RxList<EarthquakeEntity> gempaDirasakan = <EarthquakeEntity>[].obs;
  final RxList<EarthquakeEntity> gempaGlobal = <EarthquakeEntity>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnString globalErrorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll({bool force = false}) async {
    isLoading.value = true;
    errorMessage.value = null;
    globalErrorMessage.value = null;

    await Future.wait([
      _refreshBmkg(force: force),
      _refreshGlobal(force: force),
    ]);

    isLoading.value = false;
  }

  Future<void> _refreshBmkg({required bool force}) async {
    try {
      final results = await Future.wait([
        _earthquakeRepository.fetchAutoGempa(forceRefresh: force),
        _earthquakeRepository.fetchGempaTerkini(forceRefresh: force),
        _earthquakeRepository.fetchGempaDirasakan(forceRefresh: force),
      ]);

      autoGempa.value = results[0] as EarthquakeEntity;
      gempaTerkini.assignAll(results[1] as List<EarthquakeEntity>);
      gempaDirasakan.assignAll(results[2] as List<EarthquakeEntity>);
    } catch (_) {
      errorMessage.value =
          'Gagal memuat data seismik BMKG TEWS. Periksa koneksi Anda.';
    }
  }

  Future<void> _refreshGlobal({required bool force}) async {
    try {
      final global = await _earthquakeRepository.fetchGlobalEarthquakes(
        forceRefresh: force,
      );
      gempaGlobal.assignAll(global);
    } catch (_) {
      globalErrorMessage.value =
          'Gagal memuat data gempa global USGS. Periksa koneksi Anda.';
    }
  }

  void updateSearchQuery(String value) {
    searchQuery.value = value.trim().toLowerCase();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  List<EarthquakeEntity> get filteredGempaTerkini =>
      _filterList(gempaTerkini);

  List<EarthquakeEntity> get filteredGempaDirasakan =>
      _filterList(gempaDirasakan);

  List<EarthquakeEntity> get filteredGempaGlobal =>
      _filterList(gempaGlobal);

  double? distanceFromActiveRegionKm(EarthquakeEntity quake) {
    final lat = quake.latitude;
    final lon = quake.longitude;
    if (lat == null || lon == null) return null;

    final region = _atmosphereController.activeRegion.value;
    return MeteorologyCalculator.calculateDistanceKm(
      region.latitude,
      region.longitude,
      lat,
      lon,
    );
  }

  List<EarthquakeEntity> _filterList(List<EarthquakeEntity> source) {
    final query = searchQuery.value;
    if (query.isEmpty) return source.toList();
    return source
        .where(
          (item) =>
              item.wilayah.toLowerCase().contains(query) ||
              (item.dirasakan?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
