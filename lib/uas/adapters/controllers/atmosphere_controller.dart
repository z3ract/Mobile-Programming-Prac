import 'package:get/get.dart';
import '../../domain/entities/region_entity.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/i_region_repository.dart';
import '../../usecases/fetch_weather_forecast_usecase.dart';
import '../../usecases/manage_saved_regions_usecase.dart';
import '../../usecases/resolve_gps_region_usecase.dart';

/// Reactive GetX controller orchestrating active region, live BMKG weather, GPS & favorites.
class AtmosphereController extends GetxController {
  final FetchWeatherForecastUseCase _fetchWeatherUseCase;
  final ResolveGpsRegionUseCase _resolveGpsUseCase;
  final ManageSavedRegionsUseCase _manageRegionsUseCase;
  final IRegionRepository _regionRepository;

  AtmosphereController({
    required this._fetchWeatherUseCase,
    required this._resolveGpsUseCase,
    required this._manageRegionsUseCase,
    required IRegionRepository regionRepository,
  })  : _regionRepository = regionRepository,
        activeRegion = regionRepository.getDefaultRegion().obs;

  final Rx<RegionEntity> activeRegion;
  final Rxn<WeatherForecastEntity> forecast = Rxn<WeatherForecastEntity>();
  final RxList<RegionEntity> favoriteRegions = <RegionEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isResolvingGps = false.obs;
  final RxBool useFahrenheit = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnString gpsNotice = RxnString();

  void toggleTemperatureUnit() => useFahrenheit.value = !useFahrenheit.value;

  int convertTemp(double celsius) =>
      useFahrenheit.value ? ((celsius * 9.0 / 5.0) + 32.0).round() : celsius.round();

  String get unitSymbol => useFahrenheit.value ? '°F' : '°C';

  final Set<String> _favoriteAdm4Set = {};
  bool _bootstrapped = false;

  @override
  void onInit() {
    super.onInit();
    bootstrap();
  }

  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    final savedActive = await _manageRegionsUseCase.loadActiveRegion();
    activeRegion.value = savedActive;

    final favorites = await _manageRegionsUseCase.loadFavorites();
    _syncFavorites(favorites);

    await refreshWeather();
  }

  Future<void> refreshWeather({bool force = false}) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await _fetchWeatherUseCase.execute(
        activeRegion.value,
        forceRefresh: force,
      );
      forecast.value = result;
      activeRegion.value = result.region;
      await _manageRegionsUseCase.setActiveRegion(result.region);
    } catch (_) {
      errorMessage.value =
          'Gagal memuat prakiraan cuaca BMKG. Periksa koneksi internet Anda.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectRegion(RegionEntity region) async {
    gpsNotice.value = null;
    activeRegion.value = region;
    await _manageRegionsUseCase.setActiveRegion(region);
    await refreshWeather(force: true);
  }

  Future<void> detectGpsLocation() async {
    isResolvingGps.value = true;
    gpsNotice.value = null;

    try {
      final resolution = await _resolveGpsUseCase.execute(
        fallbackRegion: activeRegion.value,
      );
      gpsNotice.value = resolution.statusMessage;

      if (resolution.isGpsSuccess && resolution.region != null) {
        activeRegion.value = resolution.region!;
        await _manageRegionsUseCase.setActiveRegion(resolution.region!);
        await refreshWeather(force: true);
      }
    } finally {
      isResolvingGps.value = false;
    }
  }

  Future<void> toggleFavorite(RegionEntity region) async {
    final updated = await _manageRegionsUseCase.toggleFavorite(region);
    _syncFavorites(updated);
  }

  bool isFavorite(String adm4) => _favoriteAdm4Set.contains(adm4);

  List<RegionEntity> get presetRegions => _regionRepository.getPresetRegions();

  void _syncFavorites(List<RegionEntity> updated) {
    _favoriteAdm4Set
      ..clear()
      ..addAll(updated.map((r) => r.adm4));
    favoriteRegions.assignAll(updated);
  }
}
