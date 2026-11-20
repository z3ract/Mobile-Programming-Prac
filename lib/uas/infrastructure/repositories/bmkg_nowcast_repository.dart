import '../../adapters/dtos/bmkg_nowcast_dto.dart';
import '../../domain/entities/nowcast_alert_entity.dart';
import '../../domain/repositories/i_nowcast_repository.dart';
import '../config/bmkg_api_config.dart';
import '../http/bmkg_http_client.dart';
import '../parsers/bmkg_cap_xml_parser.dart';

/// Fetches live BMKG weather early warning RSS feeds and CAP XML polygon details.
class BmkgNowcastRepository implements INowcastRepository {
  final BmkgHttpClient _httpClient;
  final BmkgApiConfig _config;

  const BmkgNowcastRepository({
    required this._httpClient,
    required this._config,
  });

  @override
  Future<List<NowcastRssItemEntity>> fetchActiveNowcasts({
    bool forceRefresh = false,
  }) async {
    final body = await _httpClient.getBody(
      Uri.parse(_config.nowcastRssUrl),
      ttl: _config.nowcastCacheTtl,
      forceRefresh: forceRefresh,
      acceptHeader: 'application/rss+xml, application/xml, text/xml',
    );
    final parsedItems = BmkgCapXmlParser.parseNowcastRss(body);
    return parsedItems.map(BmkgNowcastDto.fromRssMap).toList();
  }

  @override
  Future<NowcastCapDetailEntity> fetchCapDetail(String detailUrl) async {
    final body = await _httpClient.getBody(
      Uri.parse(detailUrl),
      ttl: _config.nowcastCacheTtl,
      acceptHeader: 'application/xml, text/xml',
    );
    final parsedDoc = BmkgCapXmlParser.parseNowcastCapDetail(body);
    return BmkgNowcastDto.fromParsedCap(parsedDoc);
  }
}
