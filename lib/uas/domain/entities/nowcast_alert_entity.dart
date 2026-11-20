/// Pure latitude/longitude coordinate pair for CAP warning polygons.
class GeoPointEntity {
  final double latitude;
  final double longitude;

  const GeoPointEntity({
    required this.latitude,
    required this.longitude,
  });
}

/// Affected geographic area and boundary polygons inside a BMKG CAP alert.
class CapAreaEntity {
  final String areaDesc;
  final List<List<GeoPointEntity>> polygons;

  const CapAreaEntity({
    required this.areaDesc,
    required this.polygons,
  });
}

/// Provincial weather early warning summary item from BMKG RSS Nowcast feed.
class NowcastRssItemEntity {
  final String id;
  final String title;
  final String detailUrl;
  final String description;
  final String author;
  final String pubDate;
  final String provinceName;

  const NowcastRssItemEntity({
    required this.id,
    required this.title,
    required this.detailUrl,
    required this.description,
    required this.author,
    required this.pubDate,
    required this.provinceName,
  });
}

/// Detailed BMKG Common Alerting Protocol (CAP) weather early warning.
class NowcastCapDetailEntity {
  final String identifier;
  final String event;
  final String severity;
  final String urgency;
  final String certainty;
  final String effective;
  final String expires;
  final String senderName;
  final String headline;
  final String description;
  final String instruction;
  final String infographicUrl;
  final List<CapAreaEntity> areas;

  const NowcastCapDetailEntity({
    required this.identifier,
    required this.event,
    required this.severity,
    required this.urgency,
    required this.certainty,
    required this.effective,
    required this.expires,
    required this.senderName,
    required this.headline,
    required this.description,
    required this.instruction,
    required this.infographicUrl,
    required this.areas,
  });

  List<List<GeoPointEntity>> get allPolygons =>
      areas.expand((area) => area.polygons).toList();
}
