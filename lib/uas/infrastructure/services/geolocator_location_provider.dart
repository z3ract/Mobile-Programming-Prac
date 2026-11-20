import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/services/i_location_provider.dart';
import '../../domain/utils/meteorology_calculator.dart';

/// Multi-tier high-accuracy platform location provider wrapping Geolocator 12.x & Geocoding.
/// Prioritizes Fused GPS + Wi-Fi (`LocationAccuracy.best`) and stream refinement
/// so fixes match Google Maps accuracy rather than coarse cell-tower estimates.
class GeolocatorLocationProvider implements ILocationProvider {
  static final RegExp _adminPrefixRegex = RegExp(
    r'^(kecamatan|kec\.?|kelurahan|kel\.?|desa)\s+',
    caseSensitive: false,
  );
  static final RegExp _streetPrefixRegex = RegExp(
    r'^(jl\.?|jalan|gg\.?|gang)\b',
    caseSensitive: false,
  );
  static final RegExp _digitsOnlyRegex = RegExp(r'^\d+$');

  @override
  Future<GeoFixResult?> getCurrentCoordinates() async {
    final attempt = await acquireCurrentLocation();
    return attempt.fix;
  }

  @override
  Future<GeoLocationAttempt> acquireCurrentLocation() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      return const GeoLocationAttempt.failure(
        GpsErrorType.unsupportedPlatform,
      );
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const GeoLocationAttempt.failure(GpsErrorType.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return const GeoLocationAttempt.failure(
          GpsErrorType.permissionDeniedForever,
        );
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return const GeoLocationAttempt.failure(GpsErrorType.permissionDenied);
      }
    } on MissingPluginException {
      return const GeoLocationAttempt.failure(
        GpsErrorType.unsupportedPlatform,
      );
    } on UnimplementedError {
      return const GeoLocationAttempt.failure(
        GpsErrorType.unsupportedPlatform,
      );
    } on LocationServiceDisabledException {
      return const GeoLocationAttempt.failure(GpsErrorType.serviceDisabled);
    } on PermissionDeniedException {
      return const GeoLocationAttempt.failure(GpsErrorType.permissionDenied);
    } catch (e) {
      debugPrint('Geolocator permission precheck error: $e');
      return GeoLocationAttempt.failure(
        GpsErrorType.unknown,
        diagnosticDetail: e.toString(),
      );
    }

    bool sawTimeout = false;
    String? lastError;

    // Tier 1: Google Maps-grade high accuracy Fused GPS + Wi-Fi.
    final tier1 = await _tryGetCurrentPosition(
      accuracy: LocationAccuracy.best,
      forceAndroidManager: false,
      timeout: const Duration(seconds: 12),
    );
    if (tier1.hardError != null) return tier1.hardError!;
    if (tier1.fix != null && _isPrecise(tier1.fix!, thresholdMeters: 150.0)) {
      return GeoLocationAttempt.success(tier1.fix!);
    }
    sawTimeout = sawTimeout || tier1.timedOut;
    lastError = tier1.errorMessage ?? lastError;

    GeoFixResult? bestCandidate = tier1.fix;

    // Tier 2: High-accuracy live stream refinement (accepts <=100m or sharpest fix in 8s).
    final streamResult = await _tryHighAccuracyStream();
    bestCandidate = _pickMoreAccurate(bestCandidate, streamResult.fix);
    sawTimeout = sawTimeout || streamResult.timedOut;
    lastError = streamResult.errorMessage ?? lastError;

    if (bestCandidate != null &&
        _isPrecise(bestCandidate, thresholdMeters: 500.0)) {
      return GeoLocationAttempt.success(bestCandidate);
    }

    // Tier 3: Android native LocationManager fallback (essential on non-GMS devices/emulators).
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final tier3 = await _tryGetCurrentPosition(
        accuracy: LocationAccuracy.high,
        forceAndroidManager: true,
        timeout: const Duration(seconds: 10),
      );
      if (tier3.hardError != null && bestCandidate == null) {
        return tier3.hardError!;
      }
      bestCandidate = _pickMoreAccurate(bestCandidate, tier3.fix);
      sawTimeout = sawTimeout || tier3.timedOut;
      lastError = tier3.errorMessage ?? lastError;
    }

    if (bestCandidate != null) {
      return GeoLocationAttempt.success(bestCandidate);
    }

    // Tier 4: Last-known cached fix only if all live high-accuracy tiers produced nothing.
    final lastKnown = await _tryLastKnownPosition();
    if (lastKnown != null) {
      return GeoLocationAttempt.success(lastKnown);
    }

    return GeoLocationAttempt.failure(
      sawTimeout ? GpsErrorType.timeout : GpsErrorType.unknown,
      diagnosticDetail: lastError,
    );
  }

  @override
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('openLocationSettings notice: $e');
      return false;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('openAppSettings notice: $e');
      return false;
    }
  }

  @override
  Future<ReverseGeocodeResult?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return null;
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 4));

      if (placemarks.isEmpty) return null;

      String? country;
      String? countryCode;
      String? adminArea;
      String? subAdminArea;
      String? locality;
      String? subLocality;

      for (final place in placemarks) {
        country ??= _cleanValidLabel(place.country);
        countryCode ??= _cleanRaw(place.isoCountryCode);
        adminArea ??= _cleanValidLabel(place.administrativeArea);
        subAdminArea ??= _cleanValidLabel(place.subAdministrativeArea);
        locality ??= _cleanValidLabel(place.locality);
        subLocality ??= _cleanValidLabel(place.subLocality);
      }

      final bool inIndonesia = (countryCode?.toUpperCase() == 'ID') ||
          MeteorologyCalculator.isWithinIndonesiaBounds(latitude, longitude);

      // Android Indonesian geocoder places Kelurahan in subLocality and Kecamatan in locality.
      final String? cleanSubLocality = _stripPrefix(subLocality);
      final String? cleanLocality = _stripPrefix(locality);
      final String? cleanCity = _stripPrefix(subAdminArea) ?? cleanLocality;

      return ReverseGeocodeResult(
        provinceHint: adminArea,
        cityHint: cleanCity,
        districtHint: inIndonesia ? cleanLocality : cleanSubLocality,
        villageHint: inIndonesia
            ? (cleanSubLocality ?? cleanLocality)
            : (cleanLocality ?? cleanSubLocality),
        countryHint: country,
        countryCodeHint: countryCode?.toUpperCase(),
      );
    } catch (e) {
      debugPrint('Reverse geocode notice: $e');
      return null;
    }
  }

  Future<
      ({
        GeoFixResult? fix,
        GeoLocationAttempt? hardError,
        bool timedOut,
        String? errorMessage,
      })> _tryGetCurrentPosition({
    required LocationAccuracy accuracy,
    required bool forceAndroidManager,
    required Duration timeout,
  }) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        forceAndroidLocationManager: forceAndroidManager,
        timeLimit: timeout,
      );
      return (
        fix: GeoFixResult(
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracyMeters: pos.accuracy,
        ),
        hardError: null,
        timedOut: false,
        errorMessage: null,
      );
    } on LocationServiceDisabledException {
      return (
        fix: null,
        hardError: const GeoLocationAttempt.failure(GpsErrorType.serviceDisabled),
        timedOut: false,
        errorMessage: null,
      );
    } on PermissionDeniedException {
      return (
        fix: null,
        hardError: const GeoLocationAttempt.failure(
          GpsErrorType.permissionDenied,
        ),
        timedOut: false,
        errorMessage: null,
      );
    } on TimeoutException catch (e) {
      debugPrint('Geolocator timeout (forceAndroid=$forceAndroidManager): $e');
      return (
        fix: null,
        hardError: null,
        timedOut: true,
        errorMessage: 'Timeout',
      );
    } on MissingPluginException {
      return (
        fix: null,
        hardError: const GeoLocationAttempt.failure(
          GpsErrorType.unsupportedPlatform,
        ),
        timedOut: false,
        errorMessage: null,
      );
    } catch (e) {
      debugPrint(
        'Geolocator attempt failed (forceAndroid=$forceAndroidManager): $e',
      );
      return (
        fix: null,
        hardError: null,
        timedOut: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<({GeoFixResult? fix, bool timedOut, String? errorMessage})>
      _tryHighAccuracyStream() async {
    final completer = Completer<({GeoFixResult? fix, bool timedOut, String? errorMessage})>();
    StreamSubscription<Position>? subscription;
    Timer? timer;
    GeoFixResult? sharpest;

    void finish(({GeoFixResult? fix, bool timedOut, String? errorMessage}) res) {
      if (!completer.isCompleted) {
        completer.complete(res);
      }
    }

    try {
      timer = Timer(const Duration(seconds: 8), () {
        finish((
          fix: sharpest,
          timedOut: sharpest == null,
          errorMessage: sharpest == null ? 'Stream timeout' : null,
        ));
      });

      subscription = Geolocator.getPositionStream(
        locationSettings: _buildStreamSettings(),
      ).listen(
        (pos) {
          final candidate = GeoFixResult(
            latitude: pos.latitude,
            longitude: pos.longitude,
            accuracyMeters: pos.accuracy,
          );
          sharpest = _pickMoreAccurate(sharpest, candidate);
          if (_isPrecise(candidate, thresholdMeters: 100.0)) {
            finish((fix: candidate, timedOut: false, errorMessage: null));
          }
        },
        onError: (Object err) {
          finish((
            fix: sharpest,
            timedOut: false,
            errorMessage: err.toString(),
          ));
        },
        onDone: () {
          finish((fix: sharpest, timedOut: false, errorMessage: null));
        },
        cancelOnError: true,
      );

      return await completer.future;
    } catch (e) {
      debugPrint('High-accuracy stream error: $e');
      return (fix: sharpest, timedOut: false, errorMessage: e.toString());
    } finally {
      timer?.cancel();
      await subscription?.cancel();
    }
  }

  Future<GeoFixResult?> _tryLastKnownPosition() async {
    GeoFixResult? best;
    try {
      final primary = await Geolocator.getLastKnownPosition();
      if (primary != null) {
        best = GeoFixResult(
          latitude: primary.latitude,
          longitude: primary.longitude,
          accuracyMeters: primary.accuracy,
        );
      }
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final legacy = await Geolocator.getLastKnownPosition(
          forceAndroidLocationManager: true,
        );
        if (legacy != null) {
          best = _pickMoreAccurate(
            best,
            GeoFixResult(
              latitude: legacy.latitude,
              longitude: legacy.longitude,
              accuracyMeters: legacy.accuracy,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Last known position notice: $e');
    }
    return best;
  }

  LocationSettings _buildStreamSettings() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );
  }

  bool _isPrecise(GeoFixResult fix, {required double thresholdMeters}) {
    final acc = fix.accuracyMeters;
    return acc == null || acc <= 0 || acc <= thresholdMeters;
  }

  GeoFixResult? _pickMoreAccurate(GeoFixResult? a, GeoFixResult? b) {
    if (a == null) return b;
    if (b == null) return a;
    final accA = a.accuracyMeters;
    final accB = b.accuracyMeters;
    if (accA == null || accA <= 0) return b;
    if (accB == null || accB <= 0) return a;
    return accB < accA ? b : a;
  }

  String? _cleanRaw(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _cleanValidLabel(String? value) {
    final trimmed = _cleanRaw(value);
    if (trimmed == null) return null;
    if (trimmed.contains('+') ||
        _digitsOnlyRegex.hasMatch(trimmed) ||
        _streetPrefixRegex.hasMatch(trimmed)) {
      return null;
    }
    return trimmed;
  }

  String? _stripPrefix(String? value) {
    final trimmed = _cleanRaw(value);
    if (trimmed == null) return null;
    final stripped = trimmed.replaceFirst(_adminPrefixRegex, '').trim();
    return stripped.isEmpty ? null : stripped;
  }
}
