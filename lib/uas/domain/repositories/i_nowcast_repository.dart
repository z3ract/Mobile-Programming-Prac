import '../entities/nowcast_alert_entity.dart';

/// Contract for fetching BMKG Nowcast RSS feed and CAP XML details.
abstract interface class INowcastRepository {
  Future<List<NowcastRssItemEntity>> fetchActiveNowcasts({
    bool forceRefresh = false,
  });
  Future<NowcastCapDetailEntity> fetchCapDetail(String detailUrl);
}
