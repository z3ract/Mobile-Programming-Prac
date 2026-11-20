import 'package:http/http.dart' as http;
import '../config/bmkg_api_config.dart';

/// Structured HTTP failure raised when an external API call fails or returns non-200.
class BmkgHttpException implements Exception {
  final Uri uri;
  final int? statusCode;
  final String message;

  const BmkgHttpException({
    required this.uri,
    this.statusCode,
    required this.message,
  });

  @override
  String toString() =>
      'BmkgHttpException($statusCode) at $uri: $message';
}

class _CacheEntry {
  final String body;
  final DateTime expiresAt;

  const _CacheEntry({
    required this.body,
    required this.expiresAt,
  });

  bool get isFresh => DateTime.now().isBefore(expiresAt);
}

/// Asynchronous HTTP client with configurable timeouts and O(1) TTL response cache.
class BmkgHttpClient {
  final http.Client _client;
  final BmkgApiConfig _config;
  final Map<String, _CacheEntry> _cache = {};

  BmkgHttpClient({
    http.Client? client,
    BmkgApiConfig? config,
  })  : _client = client ?? http.Client(),
        _config = config ?? const BmkgApiConfig();

  Future<String> getBody(
    Uri uri, {
    Duration? ttl,
    bool forceRefresh = false,
    String acceptHeader =
        'application/json, application/xml, text/xml;q=0.9',
  }) async {
    final cacheKey = uri.toString();
    if (!forceRefresh) {
      final cached = _cache[cacheKey];
      if (cached != null && cached.isFresh) {
        return cached.body;
      }
    }

    final response = await _client
        .get(
          uri,
          headers: {
            'Accept': acceptHeader,
            'User-Agent': 'TerraCast-UAS/${_config.userAgentPackageName}',
          },
        )
        .timeout(_config.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BmkgHttpException(
        uri: uri,
        statusCode: response.statusCode,
        message: 'Server returned HTTP ${response.statusCode}',
      );
    }

    if (ttl != null && ttl > Duration.zero) {
      _cache[cacheKey] = _CacheEntry(
        body: response.body,
        expiresAt: DateTime.now().add(ttl),
      );
    }

    return response.body;
  }

  void clearCache() => _cache.clear();
}
