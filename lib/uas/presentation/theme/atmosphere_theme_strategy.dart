import 'package:flutter/material.dart';
import '../../domain/entities/notification_preference_entity.dart';
import '../../domain/strategies/weather_advisory_strategy.dart';
import 'app_colors.dart';

/// Immutable visual palette and icon theme representing a live atmospheric condition.
class AtmosphereVisualTheme {
  final List<Color> skyGradientColors;
  final Color ambientGlowColor;
  final Color accentColor;
  final IconData icon;
  final String badgeLabel;

  const AtmosphereVisualTheme({
    required this.skyGradientColors,
    required this.ambientGlowColor,
    required this.accentColor,
    required this.icon,
    required this.badgeLabel,
  });
}

/// Visual tokens for alert severity badges and category icons.
class SeverityVisualSpec {
  final Color color;
  final String label;
  final IconData icon;

  const SeverityVisualSpec({
    required this.color,
    required this.label,
    required this.icon,
  });
}

/// O(1) Strategy lookup registry mapping BMKG weather codes to dynamic UI themes.
class AtmosphereThemeRegistry {
  static const Map<WeatherConditionCategory, AtmosphereVisualTheme>
      _dayThemeMap = {
    WeatherConditionCategory.clear: AtmosphereVisualTheme(
      skyGradientColors: [
        Color(0xFF0A2444),
        Color(0xFF0E1D34),
        Color(0xFF141C29),
      ],
      ambientGlowColor: AppColors.secondary,
      accentColor: AppColors.secondary,
      icon: Icons.wb_sunny_rounded,
      badgeLabel: 'Cerah / Panas',
    ),
    WeatherConditionCategory.partlyCloudy: AtmosphereVisualTheme(
      skyGradientColors: [
        Color(0xFF091B33),
        Color(0xFF0D1727),
        Color(0xFF141C29),
      ],
      ambientGlowColor: AppColors.primaryContainer,
      accentColor: AppColors.primary,
      icon: Icons.wb_cloudy_rounded,
      badgeLabel: 'Cerah Berawan',
    ),
    WeatherConditionCategory.cloudy: AtmosphereVisualTheme(
      skyGradientColors: [
        Color(0xFF101926),
        Color(0xFF16202F),
        Color(0xFF111824),
      ],
      ambientGlowColor: AppColors.outline,
      accentColor: AppColors.onSurfaceVariant,
      icon: Icons.cloud_rounded,
      badgeLabel: 'Mendung',
    ),
    WeatherConditionCategory.hazeFog: AtmosphereVisualTheme(
      skyGradientColors: [
        Color(0xFF1A2029),
        Color(0xFF161E2B),
        Color(0xFF0D141F),
      ],
      ambientGlowColor: AppColors.outline,
      accentColor: AppColors.secondary,
      icon: Icons.foggy,
      badgeLabel: 'Kabut / Kabur',
    ),
    WeatherConditionCategory.lightRain: AtmosphereVisualTheme(
      skyGradientColors: [
        Color(0xFF071B2E),
        Color(0xFF0B1F33),
        Color(0xFF111926),
      ],
      ambientGlowColor: AppColors.tertiary,
      accentColor: AppColors.tertiary,
      icon: Icons.grain_rounded,
      badgeLabel: 'Hujan',
    ),
    WeatherConditionCategory.heavyRain: AtmosphereVisualTheme(
      skyGradientColors: [
        Color(0xFF061527),
        Color(0xFF0B1829),
        Color(0xFF121824),
      ],
      ambientGlowColor: AppColors.primaryContainer,
      accentColor: AppColors.tertiary,
      icon: Icons.water_drop_rounded,
      badgeLabel: 'Hujan Lebat',
    ),
    WeatherConditionCategory.thunderstorm: AtmosphereVisualTheme(
      skyGradientColors: [
        Color(0xFF16132B),
        Color(0xFF101526),
        Color(0xFF0A101C),
      ],
      ambientGlowColor: AppColors.secondary,
      accentColor: AppColors.secondary,
      icon: Icons.thunderstorm_rounded,
      badgeLabel: 'Hujan Petir',
    ),
  };

  static const Map<WeatherConditionCategory, AtmosphereVisualTheme>
      _nightThemeMap = {
    WeatherConditionCategory.clear: AtmosphereVisualTheme(
      skyGradientColors: [
        Color(0xFF040B18),
        Color(0xFF0A1424),
        Color(0xFF121A28),
      ],
      ambientGlowColor: AppColors.primaryContainer,
      accentColor: AppColors.primary,
      icon: Icons.nights_stay_rounded,
      badgeLabel: 'Cerah Malam',
    ),
    WeatherConditionCategory.partlyCloudy: AtmosphereVisualTheme(
      skyGradientColors: [
        Color(0xFF050D1A),
        Color(0xFF0B1422),
        Color(0xFF131B29),
      ],
      ambientGlowColor: AppColors.primaryContainer,
      accentColor: AppColors.primary,
      icon: Icons.nights_stay_outlined,
      badgeLabel: 'Berawan Malam',
    ),
    WeatherConditionCategory.cloudy: AtmosphereVisualTheme(
      skyGradientColors: [
        Color(0xFF0A101B),
        Color(0xFF101824),
        Color(0xFF151E2B),
      ],
      ambientGlowColor: AppColors.outline,
      accentColor: AppColors.onSurfaceVariant,
      icon: Icons.cloud_rounded,
      badgeLabel: 'Mendung Malam',
    ),
    WeatherConditionCategory.hazeFog: AtmosphereVisualTheme(
      skyGradientColors: [
        Color(0xFF0F141D),
        Color(0xFF141B26),
        Color(0xFF0C121B),
      ],
      ambientGlowColor: AppColors.outline,
      accentColor: AppColors.secondary,
      icon: Icons.foggy,
      badgeLabel: 'Kabut Malam',
    ),
    WeatherConditionCategory.lightRain: AtmosphereVisualTheme(
      skyGradientColors: [
        Color(0xFF051120),
        Color(0xFF091829),
        Color(0xFF0D1623),
      ],
      ambientGlowColor: AppColors.tertiary,
      accentColor: AppColors.tertiary,
      icon: Icons.grain_rounded,
      badgeLabel: 'Hujan Malam',
    ),
    WeatherConditionCategory.heavyRain: AtmosphereVisualTheme(
      skyGradientColors: [
        Color(0xFF040E1C),
        Color(0xFF081424),
        Color(0xFF0D1420),
      ],
      ambientGlowColor: AppColors.primaryContainer,
      accentColor: AppColors.tertiary,
      icon: Icons.water_drop_rounded,
      badgeLabel: 'Hujan Lebat',
    ),
    WeatherConditionCategory.thunderstorm: AtmosphereVisualTheme(
      skyGradientColors: [
        Color(0xFF110D22),
        Color(0xFF0B1020),
        Color(0xFF070C16),
      ],
      ambientGlowColor: AppColors.secondary,
      accentColor: AppColors.secondary,
      icon: Icons.thunderstorm_rounded,
      badgeLabel: 'Petir Malam',
    ),
  };

  static AtmosphereVisualTheme resolveByWeatherCode(
    int weatherCode, {
    String? fallbackDesc,
    bool isNight = false,
  }) {
    final category = WeatherCodeRegistry.resolveCategory(
      weatherCode,
      fallbackDesc: fallbackDesc,
    );
    final paletteMap = isNight ? _nightThemeMap : _dayThemeMap;
    return paletteMap[category] ??
        _dayThemeMap[WeatherConditionCategory.partlyCloudy]!;
  }
}

/// O(1) visual registry for alert severity badges and categories.
class SeverityVisualRegistry {
  static const Map<AlertSeverity, SeverityVisualSpec> _severityMap = {
    AlertSeverity.info: SeverityVisualSpec(
      color: AppColors.primary,
      label: 'INFO',
      icon: Icons.info_outline_rounded,
    ),
    AlertSeverity.advisory: SeverityVisualSpec(
      color: AppColors.tertiary,
      label: 'IMBAUAN',
      icon: Icons.visibility_rounded,
    ),
    AlertSeverity.warning: SeverityVisualSpec(
      color: AppColors.secondary,
      label: 'WASPADA',
      icon: Icons.warning_amber_rounded,
    ),
    AlertSeverity.danger: SeverityVisualSpec(
      color: AppColors.accentRose,
      label: 'BAHAYA',
      icon: Icons.crisis_alert_rounded,
    ),
  };

  static const Map<AlertCategory, IconData> _categoryIcons = {
    AlertCategory.nowcast: Icons.campaign_rounded,
    AlertCategory.rain: Icons.thunderstorm_rounded,
    AlertCategory.heat: Icons.wb_sunny_rounded,
    AlertCategory.earthquake: Icons.waves_rounded,
    AlertCategory.visibility: Icons.foggy,
  };

  static SeverityVisualSpec resolveSeverity(AlertSeverity severity) {
    return _severityMap[severity] ?? _severityMap[AlertSeverity.info]!;
  }

  static IconData resolveCategoryIcon(AlertCategory category) {
    return _categoryIcons[category] ?? Icons.notifications_active_rounded;
  }
}
