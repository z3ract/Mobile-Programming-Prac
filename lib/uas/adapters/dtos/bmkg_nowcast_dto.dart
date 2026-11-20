import '../../domain/entities/nowcast_alert_entity.dart';
import '../../infrastructure/parsers/bmkg_cap_xml_parser.dart';

/// Adapter DTO mapping parsed BMKG Nowcast RSS and CAP XML documents into entities.
class BmkgNowcastDto {
  static NowcastRssItemEntity fromRssMap(Map<String, String> raw) {
    final title = raw['title'] ?? '';
    final link = raw['link'] ?? '';
    final provinceName = _extractProvinceName(title);
    final idSource = link.isNotEmpty ? link : title;

    return NowcastRssItemEntity(
      id: idSource.hashCode.abs().toString(),
      title: title,
      detailUrl: link,
      description: raw['description'] ?? '',
      author: raw['author']?.isNotEmpty == true ? raw['author']! : 'BMKG',
      pubDate: raw['pubDate'] ?? '',
      provinceName: provinceName,
    );
  }

  static NowcastCapDetailEntity fromParsedCap(ParsedCapDocument doc) {
    final areas = doc.areas
        .map(
          (area) => CapAreaEntity(
            areaDesc: area.areaDesc,
            polygons: area.polygons
                .map(
                  (ring) => ring
                      .map(
                        (pt) => GeoPointEntity(
                          latitude: pt.lat,
                          longitude: pt.lon,
                        ),
                      )
                      .toList(),
                )
                .toList(),
          ),
        )
        .toList();

    return NowcastCapDetailEntity(
      identifier: doc.identifier,
      event: doc.event.isNotEmpty ? doc.event : 'Peringatan Dini Cuaca',
      severity: doc.severity.isNotEmpty ? doc.severity : 'Moderate',
      urgency: doc.urgency.isNotEmpty ? doc.urgency : 'Expected',
      certainty: doc.certainty.isNotEmpty ? doc.certainty : 'Likely',
      effective: doc.effective,
      expires: doc.expires,
      senderName: doc.senderName.isNotEmpty ? doc.senderName : 'BMKG',
      headline: doc.headline.isNotEmpty ? doc.headline : doc.event,
      description: doc.description,
      instruction: doc.instruction,
      infographicUrl: doc.infographicUrl,
      areas: areas,
    );
  }

  static String _extractProvinceName(String title) {
    var cleaned = title
        .replaceAll(
          RegExp(
            r'peringatan dini cuaca|weather early warning|wilayah|provinsi|bmkg|-',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) {
      cleaned = title.trim();
    }
    return cleaned;
  }
}
