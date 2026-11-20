import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Translucent frosted glass container modeled after contoh.html glass-card.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.blur = 20,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  /// High-contrast dark frosted surface for overlays, bottom nav, or alerts.
  factory GlassCard.dark({
    Key? key,
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 22,
    double blur = 24,
    Color? borderColor,
    VoidCallback? onTap,
  }) {
    return GlassCard(
      key: key,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blur: blur,
      backgroundColor: AppColors.glassDarkFill,
      borderColor: borderColor ?? AppColors.glassBorder,
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.glassFill,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    final glass = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: Colors.white.withValues(alpha: 0.14),
            highlightColor: Colors.white.withValues(alpha: 0.06),
            child: glass,
          ),
        ),
      );
    }

    return Container(margin: margin, child: glass);
  }
}
