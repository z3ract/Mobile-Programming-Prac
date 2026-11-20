import 'package:flutter/material.dart';

/// Refined Cupertino & Awan translucent glass color tokens for TerraCast UAS.
class AppColors {
  // Base fallback & dark sheet surfaces
  static const Color surface = Color(0xFF0B1420);
  static const Color surfaceDim = Color(0xFF07090E);
  static const Color surfaceBright = Color(0xFF2B3548);
  static const Color surfaceContainerLowest = Color(0xFF060E1B);
  static const Color surfaceContainerLow = Color(0xFF111623);
  static const Color surfaceContainer = Color(0xFF161D2B);
  static const Color surfaceContainerHigh = Color(0xFF1F283A);
  static const Color surfaceContainerHighest = Color(0xFF2D3543);
  static const Color background = Color(0xFF0B1420);

  // High-contrast foreground typography over dynamic sky gradients
  static const Color onSurface = Colors.white;
  static const Color onSurfaceSoft = Color(0xFFE2E8F0);
  static const Color onSurfaceVariant = Color(0xFFCBD5E1);
  static const Color onSurfaceMuted = Color(0xFF94A3B8);
  static const Color onBackground = Colors.white;
  static const Color outline = Color(0xFF94A3B8);
  static const Color outlineVariant = Color(0xFF475569);

  // Semantic accents
  static const Color primary = Color(0xFF9DCAFF);
  static const Color primaryContainer = Color(0xFF3898EC);
  static const Color onPrimary = Color(0xFF003257);
  static const Color secondary = Color(0xFFFCD34D);
  static const Color secondaryContainer = Color(0xFFF59E0B);
  static const Color onSecondary = Color(0xFF452B00);
  static const Color tertiary = Color(0xFF7DD3FC);
  static const Color error = Color(0xFFFDA4AF);
  static const Color accentRose = Color(0xFFF43F5E);
  static const Color accentEmerald = Color(0xFF34D399);

  // Translucent Frosted Glass Surfaces (inspired by contoh.html)
  static final Color glassFill = Colors.white.withValues(alpha: 0.09);
  static final Color glassFillStrong = Colors.white.withValues(alpha: 0.14);
  static final Color glassFillActive = Colors.white.withValues(alpha: 0.20);
  static final Color glassDarkFill =
      const Color(0xFF0F1420).withValues(alpha: 0.62);
  static final Color glassBorder = Colors.white.withValues(alpha: 0.15);
  static final Color glassBorderStrong = Colors.white.withValues(alpha: 0.28);
  static final Color glassBorderSubtle = Colors.white.withValues(alpha: 0.08);
  static final Color glassHighlight = Colors.white.withValues(alpha: 0.22);

  static Color getMagnitudeColor(double magnitude) {
    if (magnitude >= 6.0) return accentRose;
    if (magnitude >= 5.0) return secondary;
    return accentEmerald;
  }
}
