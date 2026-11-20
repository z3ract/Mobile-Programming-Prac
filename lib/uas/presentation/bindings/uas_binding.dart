import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../adapters/controllers/alert_controller.dart';
import '../../adapters/controllers/atmosphere_controller.dart';
import '../../adapters/controllers/region_picker_controller.dart';
import '../../adapters/controllers/seismic_controller.dart';
import '../../adapters/controllers/station_controller.dart';
import '../../domain/entities/notification_preference_entity.dart';
import '../../domain/entities/region_entity.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/i_earthquake_repository.dart';
import '../../domain/repositories/i_nowcast_repository.dart';
import '../../domain/repositories/i_region_repository.dart';
import '../../domain/repositories/i_storage_repository.dart';
import '../../domain/repositories/i_weather_repository.dart';
import '../../domain/services/i_location_provider.dart';
import '../../domain/services/i_notification_dispatcher.dart';
import '../../infrastructure/config/bmkg_api_config.dart';
import '../../infrastructure/http/bmkg_http_client.dart';
import '../../infrastructure/repositories/bmkg_earthquake_repository.dart';
import '../../infrastructure/repositories/bmkg_nowcast_repository.dart';
import '../../infrastructure/repositories/open_meteo_weather_repository.dart';
import '../../infrastructure/repositories/shared_prefs_storage_repository.dart';
import '../../infrastructure/repositories/wilayah_region_repository.dart';
import '../../infrastructure/services/geolocator_location_provider.dart';
import '../../infrastructure/services/local_notification_dispatcher.dart';
import '../../usecases/evaluate_weather_alerts_usecase.dart';
import '../../usecases/fetch_station_telemetry_usecase.dart';
import '../../usecases/fetch_weather_forecast_usecase.dart';
import '../../usecases/manage_saved_regions_usecase.dart';
import '../../usecases/resolve_gps_region_usecase.dart';

/// Dependency injection wiring for TerraCast UAS Clean Architecture + GetX modules.
class UasBinding extends Bindings {
  final SharedPreferences? prefs;
  final BmkgApiConfig? configOverride;
  final IWeatherRepository? weatherRepositoryOverride;
  final IEarthquakeRepository? earthquakeRepositoryOverride;
  final INowcastRepository? nowcastRepositoryOverride;
  final IRegionRepository? regionRepositoryOverride;
  final IStorageRepository? storageRepositoryOverride;
  final ILocationProvider? locationProviderOverride;
  final INotificationDispatcher? notificationDispatcherOverride;

  UasBinding({
    this.prefs,
    this.configOverride,
    this.weatherRepositoryOverride,
    this.earthquakeRepositoryOverride,
    this.nowcastRepositoryOverride,
    this.regionRepositoryOverride,
    this.storageRepositoryOverride,
    this.locationProviderOverride,
    this.notificationDispatcherOverride,
  });

  @override
  void dependencies() {
    final config = configOverride ?? BmkgApiConfig.fromEnvironment();
    Get.put<BmkgApiConfig>(config, permanent: true);

    final httpClient = BmkgHttpClient(config: config);
    Get.put<BmkgHttpClient>(httpClient, permanent: true);

    final weatherRepo = weatherRepositoryOverride ??
        OpenMeteoWeatherRepository(httpClient: httpClient, config: config);
    final earthquakeRepo = earthquakeRepositoryOverride ??
        BmkgEarthquakeRepository(httpClient: httpClient, config: config);
    final nowcastRepo = nowcastRepositoryOverride ??
        BmkgNowcastRepository(httpClient: httpClient, config: config);
    final regionRepo = regionRepositoryOverride ??
        WilayahRegionRepository(httpClient: httpClient, config: config);
    final storageRepo = storageRepositoryOverride ??
        (prefs != null
            ? SharedPrefsStorageRepository(prefs: prefs!, config: config)
            : _InMemoryStorageRepository());
    final locationProvider =
        locationProviderOverride ?? GeolocatorLocationProvider();
    final notificationDispatcher =
        notificationDispatcherOverride ?? LocalNotificationDispatcher();

    Get.put<IWeatherRepository>(weatherRepo, permanent: true);
    Get.put<IEarthquakeRepository>(earthquakeRepo, permanent: true);
    Get.put<INowcastRepository>(nowcastRepo, permanent: true);
    Get.put<IRegionRepository>(regionRepo, permanent: true);
    Get.put<IStorageRepository>(storageRepo, permanent: true);
    Get.put<ILocationProvider>(locationProvider, permanent: true);
    Get.put<INotificationDispatcher>(notificationDispatcher, permanent: true);

    final fetchWeatherUseCase = FetchWeatherForecastUseCase(
      weatherRepository: weatherRepo,
      storageRepository: storageRepo,
    );
    final resolveGpsUseCase = ResolveGpsRegionUseCase(
      locationProvider: locationProvider,
      regionRepository: regionRepo,
    );
    final manageRegionsUseCase = ManageSavedRegionsUseCase(
      storageRepository: storageRepo,
      regionRepository: regionRepo,
    );
    final evaluateAlertsUseCase = EvaluateWeatherAlertsUseCase(
      storageRepository: storageRepo,
      notificationDispatcher: notificationDispatcher,
    );
    final fetchStationUseCase = FetchStationTelemetryUseCase(
      weatherRepository: weatherRepo,
    );

    final atmosphereCtrl = Get.put<AtmosphereController>(
      AtmosphereController(
        fetchWeatherUseCase: fetchWeatherUseCase,
        resolveGpsUseCase: resolveGpsUseCase,
        manageRegionsUseCase: manageRegionsUseCase,
        regionRepository: regionRepo,
        locationProvider: locationProvider,
      ),
      permanent: true,
    );

    final seismicCtrl = Get.put<SeismicController>(
      SeismicController(
        earthquakeRepository: earthquakeRepo,
        atmosphereController: atmosphereCtrl,
      ),
      permanent: true,
    );

    Get.put<AlertController>(
      AlertController(
        nowcastRepository: nowcastRepo,
        storageRepository: storageRepo,
        notificationDispatcher: notificationDispatcher,
        evaluateAlertsUseCase: evaluateAlertsUseCase,
        atmosphereController: atmosphereCtrl,
        seismicController: seismicCtrl,
      ),
      permanent: true,
    );

    Get.put<StationController>(
      StationController(fetchStationUseCase: fetchStationUseCase),
      permanent: true,
    );

    Get.put<RegionPickerController>(
      RegionPickerController(
        regionRepository: regionRepo,
        atmosphereController: atmosphereCtrl,
      ),
      permanent: true,
    );
  }
}

class _InMemoryStorageRepository implements IStorageRepository {
  RegionEntity? _activeRegion;
  List<RegionEntity> _favorites = const [];
  NotificationPreferenceEntity _prefs = const NotificationPreferenceEntity();
  final Map<String, WeatherForecastEntity> _weatherCache = {};
  final Set<String> _notifiedIds = {};

  @override
  Future<RegionEntity?> loadActiveRegion() async => _activeRegion;

  @override
  Future<void> saveActiveRegion(RegionEntity region) async {
    _activeRegion = region;
  }

  @override
  Future<List<RegionEntity>> loadFavoriteRegions() async => _favorites;

  @override
  Future<void> saveFavoriteRegions(List<RegionEntity> regions) async {
    _favorites = regions;
  }

  @override
  Future<NotificationPreferenceEntity> loadNotificationPreferences() async =>
      _prefs;

  @override
  Future<void> saveNotificationPreferences(
    NotificationPreferenceEntity prefs,
  ) async {
    _prefs = prefs;
  }

  @override
  Future<WeatherForecastEntity?> loadWeatherCache(String adm4) async =>
      _weatherCache[adm4];

  @override
  Future<void> saveWeatherCache(
    String adm4,
    WeatherForecastEntity forecast,
  ) async {
    _weatherCache[adm4] = forecast;
  }

  @override
  Future<bool> hasNotifiedAlert(String alertId) async =>
      _notifiedIds.contains(alertId);

  @override
  Future<void> markAlertNotified(String alertId) async {
    _notifiedIds.add(alertId);
  }
}
