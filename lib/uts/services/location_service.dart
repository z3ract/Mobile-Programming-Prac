import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class UserLocationResult {
  final double latitude;
  final double longitude;
  final String cityName;
  final String provinceName;
  final bool isGps;

  UserLocationResult({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.provinceName,
    required this.isGps,
  });
}

class LocationService {
  /// Mencoba mengambil posisi GPS perangkat dengan timeout 6 detik
  /// Mengembalikan null jika GPS tidak aktif atau izin ditolak pengguna
  static Future<UserLocationResult?> getGpsLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
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

      String city = 'Jakarta Pusat';
      String province = 'DKI Jakarta';

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 4));

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.subAdministrativeArea ?? place.locality ?? place.name ?? 'Jakarta Pusat';
          province = place.administrativeArea ?? 'Indonesia';
        }
      } catch (e) {
        debugPrint('Geocoding notice: $e');
      }

      return UserLocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: city,
        provinceName: province,
        isGps: true,
      );
    } catch (e) {
      debugPrint('GPS check notice: $e');
      return null;
    }
  }

  /// Menghitung jarak garis lurus (Haversine) dalam kilometer antara dua titik koordinat
  static double calculateDistanceKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    double distanceInMeters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    return distanceInMeters / 1000.0;
  }

  /// Format angka jarak yang nyaman dibaca (contoh: "142 km" atau "650 m")
  static String formatDistance(double km) {
    if (km < 1) {
      int meters = (km * 1000).round();
      return '$meters m';
    } else {
      return '${km.toStringAsFixed(1)} km';
    }
  }
}
