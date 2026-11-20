import '../entities/earthquake_entity.dart';

/// Contract for fetching live earthquake feeds from BMKG TEWS.
abstract interface class IEarthquakeRepository {
  Future<EarthquakeEntity> fetchAutoGempa({bool forceRefresh = false});
  Future<List<EarthquakeEntity>> fetchGempaTerkini({bool forceRefresh = false});
  Future<List<EarthquakeEntity>> fetchGempaDirasakan({
    bool forceRefresh = false,
  });
}
