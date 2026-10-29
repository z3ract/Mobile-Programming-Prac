import 'package:flutter/material.dart';

/// Palet warna Cupertino Atmosphere yang disesuaikan dari spesifikasi desain
/// F:\TUGAS\SEMESTER 5\MOBILE PROGRAMMING PRAC\MODUL\TUGAS\sc\UTS\cupertino_atmosphere\DESIGN.md
class AppColors {
  // Surfaces & Backgrounds
  static const Color surface = Color(0xFF0B1420);
  static const Color surfaceDim = Color(0xFF0B1420);
  static const Color surfaceBright = Color(0xFF323947);
  static const Color surfaceContainerLowest = Color(0xFF060E1B);
  static const Color surfaceContainerLow = Color(0xFF141C29);
  static const Color surfaceContainer = Color(0xFF18202D);
  static const Color surfaceContainerHigh = Color(0xFF222A38);
  static const Color surfaceContainerHighest = Color(0xFF2D3543);
  static const Color background = Color(0xFF0B1420);

  // Text & On-Colors
  static const Color onSurface = Color(0xFFDBE3F5);
  static const Color onSurfaceVariant = Color(0xFFC0C7D3);
  static const Color onBackground = Color(0xFFDBE3F5);
  static const Color outline = Color(0xFF8A919D);
  static const Color outlineVariant = Color(0xFF404751);

  // Accents
  static const Color primary = Color(0xFF9DCAFF);
  static const Color primaryContainer = Color(0xFF3898EC); // Azure sky blue
  static const Color onPrimary = Color(0xFF003257);
  static const Color secondary = Color(0xFFFFB955); // Sunlight amber
  static const Color secondaryContainer = Color(0xFFDC9100);
  static const Color onSecondary = Color(0xFF452B00);
  static const Color tertiary = Color(0xFF74D1FF); // Precipitation cyan
  static const Color error = Color(0xFFFFB4AB);
  static const Color accentRose = Color(0xFFF43F5E);
  static const Color accentEmerald = Color(0xFF10B981);

  // Glass Material Fill & Borders
  static final Color glassFill = const Color(0xFF18202D).withValues(alpha: 0.60);
  static final Color glassFillActive = const Color(0xFF222A38).withValues(alpha: 0.75);
  static final Color glassBorder = Colors.white.withValues(alpha: 0.12);
  static final Color glassBorderSubtle = Colors.white.withValues(alpha: 0.06);

  // Helper warna magnitudo gempa bumi (Seismik)
  static Color getMagnitudeColor(double magnitude) {
    if (magnitude >= 6.0) {
      return accentRose; // Bahaya / Sangat Kuat
    } else if (magnitude >= 5.0) {
      return secondary; // Waspada / Menengah
    } else {
      return accentEmerald; // Ringan / Aman
    }
  }
}
