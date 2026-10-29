import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tipografi berbasis Cupertino & Inter dari pedoman desain:
/// ultralight hero displays, uppercase tracked labels, clean readable bodies.
class AppTypography {
  static TextStyle displayHero({Color color = AppColors.onSurface}) {
    return GoogleFonts.inter(
      fontSize: 76,
      fontWeight: FontWeight.w200,
      letterSpacing: -2.0,
      height: 1.0,
      color: color,
    );
  }

  static TextStyle headlineLg({Color color = AppColors.onSurface}) {
    return GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.5,
      color: color,
    );
  }

  static TextStyle headlineMd({Color color = AppColors.onSurface}) {
    return GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: color,
    );
  }

  static TextStyle headlineSm({Color color = AppColors.onSurface}) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: color,
    );
  }

  static TextStyle bodyLg({Color color = AppColors.onSurface}) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle bodyMd({Color color = AppColors.onSurface}) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle bodySm({Color color = AppColors.onSurfaceVariant}) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle labelUppercase({Color color = AppColors.onSurfaceVariant}) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      color: color,
    );
  }

  static TextStyle labelCompact({Color color = AppColors.onSurfaceVariant}) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }
}
