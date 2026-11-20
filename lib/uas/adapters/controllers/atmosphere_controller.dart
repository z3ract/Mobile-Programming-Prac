import 'package:get/get.dart';
import '../../domain/entities/region_entity.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/i_region_repository.dart';
import '../../domain/services/i_location_provider.dart';
import '../../domain/utils/meteorology_calculator.dart';
import '../../usecases/fetch_weather_forecast_usecase.dart';
import '../../usecases/manage_saved_regions_usecase.dart';
import '../../usecases/resolve_gps_region_usecase.dart';

/// Reactive GetX controller orchestrating active region, live weather, GPS, map selection & favorites.
class AtmosphereController extends GetxController {
  final FetchWeatherForecastUseCase _fetchWeatherUseCase;
  final ResolveGpsRegionUseCase _resolveGpsUseCase;
  final ManageSavedRegionsUseCase _manageRegionsUseCase;
  final IRegionRepository _regionRepository;
  final ILocationProvider? _locationProvider;

  AtmosphereController({
    required this._fetchWeatherUseCase,
    required this._resolveGpsUseCase,
    required this._manageRegionsUseCase,
    required IRegionRepository regionRepository,
    this._locationProvider,
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
  final Rx<GpsErrorType> gpsErrorType = GpsErrorType.none.obs;

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
          'Gagal memuat prakiraan cuaca Open-Meteo. Periksa koneksi internet Anda.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectRegion(RegionEntity region) async {
    gpsNotice.value = null;
    gpsErrorType.value = GpsErrorType.none;
    activeRegion.value = region;
    await _manageRegionsUseCase.setActiveRegion(region);
    await refreshWeather(force: true);
  }

  Future<RegionEntity> selectCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    ReverseGeocodeResult? reverse;
    try {
      reverse = await _locationProvider?.reverseGeocode(latitude, longitude);
    } catch (_) {
      reverse = null;
    }

    final inIndonesia = MeteorologyCalculator.isWithinIndonesiaBounds(
      latitude,
      longitude,
    );
    final coordLabel =
        '${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';
    final country = _nonEmptyOrNull(reverse?.countryHint) ??
        (inIndonesia ? 'Indonesia' : 'Global');
    final province = _nonEmptyOrNull(reverse?.provinceHint) ?? country;
    final city = _nonEmptyOrNull(reverse?.cityHint) ??
        _nonEmptyOrNull(reverse?.provinceHint) ??
        coordLabel;
    final title = _nonEmptyOrNull(reverse?.villageHint) ??
        _nonEmptyOrNull(reverse?.cityHint) ??
        _nonEmptyOrNull(reverse?.provinceHint) ??
        'Titik $coordLabel';
    final countryCode = (reverse?.countryCodeHint ?? '').trim().toUpperCase();

    final entity = RegionEntity(
      adm1: countryCode.isEmpty ? (inIndonesia ? 'ID' : 'XX') : countryCode,
      adm2: province,
      adm3: reverse?.districtHint?.trim() ?? '',
      adm4: 'COORD:${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}',
      provinsi: province,
      kotkab: city,
      kecamatan: reverse?.districtHint?.trim() ?? '',
      desa: title,
      latitude: latitude,
      longitude: longitude,
      timezone: 'auto',
      isGpsResolved: false,
      country: country,
      countryCode: countryCode,
      isGlobal: !inIndonesia,
    );

    await selectRegion(entity);
    return entity;
  }

  String? _nonEmptyOrNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> detectGpsLocation() async {
    isResolvingGps.value = true;
    gpsNotice.value = null;
    gpsErrorType.value = GpsErrorType.none;

    try {
      final resolution = await _resolveGpsUseCase.execute(
        fallbackRegion: activeRegion.value,
      );
      gpsNotice.value = resolution.statusMessage;
      gpsErrorType.value = resolution.errorType;

      if (resolution.isGpsSuccess && resolution.region != null) {
        activeRegion.value = resolution.region!;
        await _manageRegionsUseCase.setActiveRegion(resolution.region!);
        await refreshWeather(force: true);
      }
    } catch (e) {
      gpsErrorType.value = GpsErrorType.unknown;
      gpsNotice.value = 'Gagal mendeteksi lokasi GPS: $e';
    } finally {
      isResolvingGps.value = false;
    }
  }

  Future<void> openGpsSettings() async {
    await _locationProvider?.openLocationSettings();
  }

  Future<void> openAppLocationSettings() async {
    await _locationProvider?.openAppSettings();
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
