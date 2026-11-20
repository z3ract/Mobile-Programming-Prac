import 'package:get/get.dart';
import '../../domain/entities/notification_preference_entity.dart';
import '../../domain/entities/nowcast_alert_entity.dart';
import '../../domain/repositories/i_nowcast_repository.dart';
import '../../domain/repositories/i_storage_repository.dart';
import '../../domain/services/i_notification_dispatcher.dart';
import '../../usecases/evaluate_weather_alerts_usecase.dart';
import 'atmosphere_controller.dart';
import 'seismic_controller.dart';

/// Reactive GetX controller for BMKG CAP Nowcast alerts, alert rules, and local OS notifications.
class AlertController extends GetxController {
  final INowcastRepository _nowcastRepository;
  final IStorageRepository _storageRepository;
  final INotificationDispatcher _notificationDispatcher;
  final EvaluateWeatherAlertsUseCase _evaluateAlertsUseCase;
  final AtmosphereController _atmosphereController;
  final SeismicController _seismicController;

  AlertController({
    required this._nowcastRepository,
    required this._storageRepository,
    required this._notificationDispatcher,
    required this._evaluateAlertsUseCase,
    required this._atmosphereController,
    required this._seismicController,
  });

  final RxList<NowcastRssItemEntity> nowcastItems =
      <NowcastRssItemEntity>[].obs;
  final Rxn<NowcastCapDetailEntity> selectedCapDetail =
      Rxn<NowcastCapDetailEntity>();
  final RxBool isLoadingCapDetail = false.obs;
  final RxnString capDetailError = RxnString();

  final RxList<AlertEvaluationEntity> evaluatedAlerts =
      <AlertEvaluationEntity>[].obs;
  final Rx<NotificationPreferenceEntity> preferences =
      const NotificationPreferenceEntity().obs;

  final RxBool isLoading = false.obs;
  final RxnString nowcastError = RxnString();
  final RxnString lastTestStatus = RxnString();

  final List<Worker> _workers = [];

  @override
  void onInit() {
    super.onInit();
    _workers.addAll([
      ever(_atmosphereController.forecast, (_) => reEvaluateAlerts()),
      ever(_seismicController.autoGempa, (_) => reEvaluateAlerts()),
    ]);
    bootstrap();
  }

  Future<void> bootstrap() async {
    final savedPrefs = await _storageRepository.loadNotificationPreferences();
    preferences.value = savedPrefs;
    await refreshNowcast();
  }

  Future<void> refreshNowcast({bool force = false}) async {
    isLoading.value = true;
    nowcastError.value = null;

    try {
      final items = await _nowcastRepository.fetchActiveNowcasts(
        forceRefresh: force,
      );
      nowcastItems.assignAll(items);
    } catch (_) {
      nowcastError.value =
          'Gagal memuat feed Peringatan Dini Cuaca BMKG (Nowcast).';
    } finally {
      isLoading.value = false;
      await reEvaluateAlerts();
    }
  }

  Future<void> openCapDetail(NowcastRssItemEntity item) async {
    isLoadingCapDetail.value = true;
    capDetailError.value = null;
    selectedCapDetail.value = null;

    try {
      final detail = await _nowcastRepository.fetchCapDetail(item.detailUrl);
      selectedCapDetail.value = detail;
    } catch (_) {
      capDetailError.value =
          'Detail CAP XML tidak dapat diunduh. Coba muat ulang.';
    } finally {
      isLoadingCapDetail.value = false;
    }
  }

  Future<void> reEvaluateAlerts({bool dispatchOsNotifications = true}) async {
    final evaluated = await _evaluateAlertsUseCase.execute(
      region: _atmosphereController.activeRegion.value,
      forecast: _atmosphereController.forecast.value,
      nowcasts: nowcastItems.toList(),
      latestQuake: _seismicController.autoGempa.value,
      preferences: preferences.value,
      dispatchOsNotifications: dispatchOsNotifications,
    );
    evaluatedAlerts.assignAll(evaluated);
  }

  Future<void> updatePreferences(NotificationPreferenceEntity updated) async {
    preferences.value = updated;
    await _storageRepository.saveNotificationPreferences(updated);
    await reEvaluateAlerts(dispatchOsNotifications: false);
  }

  Future<void> sendTestNotification() async {
    await _notificationDispatcher.requestPermissionIfNeeded();
    final region = _atmosphereController.activeRegion.value;
    final current = _atmosphereController.forecast.value?.current;
    final conditionText = current != null
        ? '${current.weatherDesc} (${current.tempC.round()}°C)'
        : 'Pemantauan aktif BMKG';

    final sampleAlert = AlertEvaluationEntity(
      id: 'demo_notif_${DateTime.now().millisecondsSinceEpoch}',
      category: AlertCategory.nowcast,
      severity: AlertSeverity.warning,
      title: 'TerraCast Alert • ${region.displayTitle}',
      message: '$conditionText di ${region.kotkab}.',
      advice:
          'Sistem notifikasi dini cuaca & gempa BMKG aktif dan terhubung.',
      timestamp: DateTime.now(),
      isOfficialBmkg: true,
    );

    await _notificationDispatcher.dispatchAlert(sampleAlert);
    lastTestStatus.value =
        'Notifikasi uji dikirim untuk ${region.displayTitle} (${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}).';
  }

  List<NowcastRssItemEntity> get matchingProvinceNowcasts {
    final activeProv = _normalize(_atmosphereController.activeRegion.value.provinsi);
    if (activeProv.isEmpty) return const [];
    return nowcastItems.where((item) {
      final itemProv = _normalize(item.provinceName);
      final itemTitle = _normalize(item.title);
      return itemProv.contains(activeProv) ||
          activeProv.contains(itemProv) ||
          itemTitle.contains(activeProv);
    }).toList();
  }

  List<List<GeoPointEntity>> get activePolygonRings =>
      selectedCapDetail.value?.allPolygons ?? const [];

  String _normalize(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('daerah khusus ibukota', 'dki')
        .replaceAll('daerah istimewa', 'di')
        .replaceAll('provinsi', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  void onClose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }
}
