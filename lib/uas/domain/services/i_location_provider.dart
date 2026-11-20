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
  Future<ReverseGeocodeResult?> reverseGeocode(
    double latitude,
    double longitude,
  );
}
