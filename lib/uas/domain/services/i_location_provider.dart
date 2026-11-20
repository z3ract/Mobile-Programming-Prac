/// Structured failure categories for GPS acquisition diagnostics.
enum GpsErrorType {
  none,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unsupportedPlatform,
  unknown,
}

/// Raw GPS coordinate fix returned by the platform location provider.
class GeoFixResult {
  final double latitude;
  final double longitude;
  final double? accuracyMeters;

  const GeoFixResult({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });
}

/// Diagnostic outcome of attempting to acquire live device GPS coordinates.
class GeoLocationAttempt {
  final GeoFixResult? fix;
  final GpsErrorType errorType;
  final String? diagnosticDetail;

  const GeoLocationAttempt._({
    this.fix,
    required this.errorType,
    this.diagnosticDetail,
  });

  const GeoLocationAttempt.success(GeoFixResult fix)
      : this._(
          fix: fix,
          errorType: GpsErrorType.none,
        );

  const GeoLocationAttempt.failure(
    GpsErrorType errorType, {
    String? diagnosticDetail,
  }) : this._(
          errorType: errorType,
          diagnosticDetail: diagnosticDetail,
        );

  bool get isSuccess => fix != null && errorType == GpsErrorType.none;
}

/// Reverse-geocoded administrative hints derived from coordinates.
class ReverseGeocodeResult {
  final String? provinceHint;
  final String? cityHint;
  final String? districtHint;
  final String? villageHint;
  final String? countryHint;
  final String? countryCodeHint;

  const ReverseGeocodeResult({
    this.provinceHint,
    this.cityHint,
    this.districtHint,
    this.villageHint,
    this.countryHint,
    this.countryCodeHint,
  });
}

/// Platform-agnostic location provider boundary.
abstract interface class ILocationProvider {
  Future<GeoFixResult?> getCurrentCoordinates();
  Future<GeoLocationAttempt> acquireCurrentLocation();
  Future<bool> openLocationSettings();
  Future<bool> openAppSettings();
  Future<ReverseGeocodeResult?> reverseGeocode(
    double latitude,
    double longitude,
  );
}
