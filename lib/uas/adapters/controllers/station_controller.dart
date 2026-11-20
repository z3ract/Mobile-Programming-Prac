import 'package:get/get.dart';
import '../../domain/entities/station_entity.dart';
import '../../usecases/fetch_station_telemetry_usecase.dart';

/// Reactive GetX controller managing live BMKG weather telemetry per observation station.
class StationController extends GetxController {
  final FetchStationTelemetryUseCase _fetchStationUseCase;

  StationController({
    required this._fetchStationUseCase,
  });

  final RxList<BmkgStationEntity> stations =
      FetchStationTelemetryUseCase.defaultStations.obs;
  final RxBool isLoading = false.obs;
  final Rxn<DateTime> lastSyncedAt = Rxn<DateTime>();
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    refreshStations();
  }

  Future<void> refreshStations({bool force = false}) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final liveStations = await _fetchStationUseCase.execute(
        forceRefresh: force,
      );
      stations.assignAll(liveStations);
      lastSyncedAt.value = DateTime.now();
    } catch (_) {
      errorMessage.value =
          'Gagal menyinkronkan telemetri stasiun dari API BMKG.';
    } finally {
      isLoading.value = false;
    }
  }

  int get onlineCount => stations.where((s) => s.isOnline).length;
}
