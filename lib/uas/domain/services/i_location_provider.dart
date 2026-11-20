/// Raw GPS coordinate fix returned by the platform location provider.
class GeoFixResult {
  final double latitude;
  final double longitude;

  const GeoFixResult({
    required this.latitude,
    required this.longitude,
  });
}

/// Reverse-geocoded administrative hints derived from coordinates.
class ReverseGeocodeResult {
  final String? provinceHint;
  final String? cityHint;
  final String? districtHint;
  final String? villageHint;

  const ReverseGeocodeResult({
    this.provinceHint,
    this.cityHint,
    this.districtHint,
    this.villageHint,
  });
}

/// Platform-agnostic location provider boundary.
abstract interface class ILocationProvider {
  Future<GeoFixResult?> getCurrentCoordinates();
  Future<ReverseGeocodeResult?> reverseGeocode(
    double latitude,
    double longitude,
  );
}
