import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography pairing Plus Jakarta Sans (display & numeric metrics) with Inter (body & UI).
class AppTypography {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static TextStyle displayHero({Color color = AppColors.onSurface}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 80,
      fontWeight: FontWeight.w200,
      letterSpacing: -3.2,
      height: 1.0,
      color: color,
      fontFeatures: _tabular,
    );
  }

  static TextStyle metricLg({Color color = AppColors.onSurface}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.6,
      height: 1.05,
      color: color,
      fontFeatures: _tabular,
    );
  }

  static TextStyle metricMd({Color color = AppColors.onSurface}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.4,
      height: 1.1,
      color: color,
      fontFeatures: _tabular,
    );
  }

  static TextStyle headlineLg({Color color = AppColors.onSurface}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      color: color,
    );
  }

  static TextStyle headlineMd({Color color = AppColors.onSurface}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: color,
    );
  }

  static TextStyle headlineSm({Color color = AppColors.onSurface}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: color,
    );
  }

  static TextStyle bodyLg({Color color = AppColors.onSurface}) {
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  static TextStyle bodyMd({Color color = AppColors.onSurface}) {
    return GoogleFonts.inter(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle bodySm({Color color = AppColors.onSurfaceVariant}) {
    return GoogleFonts.inter(
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle labelUppercase({Color color = AppColors.onSurfaceVariant}) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.9,
      color: color,
    );
  }

  static TextStyle labelCompact({Color color = AppColors.onSurfaceVariant}) {
    return GoogleFonts.inter(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  static TextStyle tabularSm({Color color = AppColors.onSurfaceVariant}) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: color,
      fontFeatures: _tabular,
    );
  }
}
