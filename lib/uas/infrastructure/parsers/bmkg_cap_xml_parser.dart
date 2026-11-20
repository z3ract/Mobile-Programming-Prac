/// Parsed CAP area block containing area description and polygon coordinate rings.
class ParsedCapArea {
  final String areaDesc;
  final List<List<({double lat, double lon})>> polygons;

  const ParsedCapArea({
    required this.areaDesc,
    required this.polygons,
  });
}

/// Parsed Common Alerting Protocol (CAP) XML document returned by BMKG Nowcast.
class ParsedCapDocument {
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
  final List<ParsedCapArea> areas;

  const ParsedCapDocument({
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
}

/// Pure Dart standard-library parser for BMKG Nowcast RSS feeds and CAP XML alerts.
class BmkgCapXmlParser {
  static final RegExp _rssItemPattern = RegExp(
    r'<item\b[^>]*>([\s\S]*?)</item>',
    caseSensitive: false,
  );
  static final RegExp _capAreaPattern = RegExp(
    r'<(?:\w+:)?area\b[^>]*>([\s\S]*?)</(?:\w+:)?area>',
    caseSensitive: false,
  );
  static final RegExp _capPolygonPattern = RegExp(
    r'<(?:\w+:)?polygon\b[^>]*>([\s\S]*?)</(?:\w+:)?polygon>',
    caseSensitive: false,
  );
  static final RegExp _cdataPattern = RegExp(
    r'<!\[CDATA\[([\s\S]*?)\]\]>',
    caseSensitive: false,
  );

  /// Extracts provincial warning items from BMKG RSS Nowcast XML feed.
  static List<Map<String, String>> parseNowcastRss(String xmlBody) {
    final List<Map<String, String>> items = [];
    for (final match in _rssItemPattern.allMatches(xmlBody)) {
      final block = match.group(1) ?? '';
      final title = _extractTag(block, 'title');
      final link = _extractTag(block, 'link');
      if (title.isEmpty && link.isEmpty) continue;

      items.add({
        'title': title,
        'link': link,
        'description': _extractTag(block, 'description'),
        'author': _extractTag(block, 'author'),
        'pubDate': _extractTag(block, 'pubDate'),
      });
    }
    return items;
  }

  /// Extracts alert metadata, instructions, and GIS polygons from CAP XML.
  static ParsedCapDocument parseNowcastCapDetail(String xmlBody) {
    final List<ParsedCapArea> areas = [];
    for (final areaMatch in _capAreaPattern.allMatches(xmlBody)) {
      final areaBlock = areaMatch.group(1) ?? '';
      final areaDesc = _extractTag(areaBlock, 'areaDesc');
      final List<List<({double lat, double lon})>> polygons = [];

      for (final polyMatch in _capPolygonPattern.allMatches(areaBlock)) {
        final rawPoly = _cleanText(polyMatch.group(1) ?? '');
        final ring = _parsePolygonCoordinates(rawPoly);
        if (ring.length >= 3) {
          polygons.add(ring);
        }
      }

      if (areaDesc.isNotEmpty || polygons.isNotEmpty) {
        areas.add(ParsedCapArea(areaDesc: areaDesc, polygons: polygons));
      }
    }

    return ParsedCapDocument(
      identifier: _extractTag(xmlBody, 'identifier'),
      event: _extractTag(xmlBody, 'event'),
      severity: _extractTag(xmlBody, 'severity'),
      urgency: _extractTag(xmlBody, 'urgency'),
      certainty: _extractTag(xmlBody, 'certainty'),
      effective: _extractTag(xmlBody, 'effective'),
      expires: _extractTag(xmlBody, 'expires'),
      senderName: _extractTag(xmlBody, 'senderName'),
      headline: _extractTag(xmlBody, 'headline'),
      description: _extractTag(xmlBody, 'description'),
      instruction: _extractTag(xmlBody, 'instruction'),
      infographicUrl: _extractTag(xmlBody, 'web'),
      areas: areas,
    );
  }

  static String _extractTag(String source, String tagName) {
    final escapedTag = RegExp.escape(tagName);
    final pattern = RegExp(
      '<(?:\\w+:)?$escapedTag\\b[^>]*>([\\s\\S]*?)</(?:\\w+:)?$escapedTag>',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(source);
    if (match == null) return '';
    return _cleanText(match.group(1) ?? '');
  }

  static String _cleanText(String raw) {
    var value = raw.trim();
    final cdataMatch = _cdataPattern.firstMatch(value);
    if (cdataMatch != null) {
      value = (cdataMatch.group(1) ?? '').trim();
    }
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<({double lat, double lon})> _parsePolygonCoordinates(
    String raw,
  ) {
    final List<({double lat, double lon})> points = [];
    final tokens = raw.split(RegExp(r'\s+'));
    for (final token in tokens) {
      final parts = token.split(',');
      if (parts.length < 2) continue;
      final lat = double.tryParse(parts[0].trim());
      final lon = double.tryParse(parts[1].trim());
      if (lat != null && lon != null) {
        points.add((lat: lat, lon: lon));
      }
    }
    return points;
  }
}
