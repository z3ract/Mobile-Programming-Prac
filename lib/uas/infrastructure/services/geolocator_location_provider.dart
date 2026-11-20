import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/services/i_location_provider.dart';

/// Platform location provider wrapping Geolocator and Geocoding safely.
class GeolocatorLocationProvider implements ILocationProvider {
  @override
  Future<GeoFixResult?> getCurrentCoordinates() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 6),
      );

      return GeoFixResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('Geolocator notice: $e');
      return null;
    }
  }

  @override
  Future<ReverseGeocodeResult?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 4));

      if (placemarks.isEmpty) return null;
      final place = placemarks.first;

      return ReverseGeocodeResult(
        provinceHint: place.administrativeArea,
        cityHint: place.subAdministrativeArea ?? place.locality,
        districtHint: place.subLocality,
        villageHint: place.locality ?? place.name,
      );
    } catch (e) {
      debugPrint('Reverse geocode notice: $e');
      return null;
    }
  }
}
