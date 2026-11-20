import 'package:flutter/material.dart';
import '../../domain/entities/notification_preference_entity.dart';
import '../../domain/strategies/weather_advisory_strategy.dart';
import 'app_colors.dart';

/// Atmospheric canvas and icon scene selector.
enum SkySceneType {
  sunny,
  partlyCloudy,
  cloudy,
  hazeFog,
  lightRain,
  storm,
  night,
}

/// Immutable visual palette, stops, and icon theme representing live atmospheric state.
class AtmosphereVisualTheme {
  final SkySceneType sceneType;
  final List<Color> skyGradientColors;
  final List<double> skyStops;
  final Color ambientGlowColor;
  final Color accentColor;
  final IconData icon;
  final String badgeLabel;

  const AtmosphereVisualTheme({
    required this.sceneType,
    required this.skyGradientColors,
    this.skyStops = const [0.0, 0.44, 0.78, 1.0],
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

/// O(1) Strategy lookup registry mapping BMKG weather codes to dynamic sky themes.
class AtmosphereThemeRegistry {
  static const List<Color> _sunnyGradient = [
    Color(0xFF1B65C4),
    Color(0xFF3A8EE6),
    Color(0xFF72B2EC),
    Color(0xFFD9A06C),
  ];

  static const List<Color> _cloudyGradient = [
    Color(0xFF2B3A55),
    Color(0xFF3C4F6D),
    Color(0xFF516582),
    Color(0xFF687B95),
  ];

  static const List<Color> _hazeGradient = [
    Color(0xFF1D2B3A),
    Color(0xFF2D4356),
    Color(0xFF435B70),
    Color(0xFF5C768D),
  ];

  static const List<Color> _lightRainGradient = [
    Color(0xFF1F2B3E),
    Color(0xFF2D3E57),
    Color(0xFF3C506B),
    Color(0xFF4D627D),
  ];

  static const List<Color> _stormGradient = [
    Color(0xFF0D1321),
    Color(0xFF172036),
    Color(0xFF222E48),
    Color(0xFF2D3A54),
  ];

  static const List<Color> _nightGradient = [
    Color(0xFF060913),
    Color(0xFF0D152B),
    Color(0xFF162242),
    Color(0xFF1F2D52),
  ];

  static const Map<WeatherConditionCategory, AtmosphereVisualTheme>
      _dayThemeMap = {
    WeatherConditionCategory.clear: AtmosphereVisualTheme(
      sceneType: SkySceneType.sunny,
      skyGradientColors: _sunnyGradient,
      ambientGlowColor: AppColors.secondary,
      accentColor: AppColors.secondary,
      icon: Icons.wb_sunny_rounded,
      badgeLabel: 'Cerah',
    ),
    WeatherConditionCategory.partlyCloudy: AtmosphereVisualTheme(
      sceneType: SkySceneType.partlyCloudy,
      skyGradientColors: _cloudyGradient,
      ambientGlowColor: AppColors.primary,
      accentColor: AppColors.primary,
      icon: Icons.wb_cloudy_rounded,
      badgeLabel: 'Cerah Berawan',
    ),
    WeatherConditionCategory.cloudy: AtmosphereVisualTheme(
      sceneType: SkySceneType.cloudy,
      skyGradientColors: _cloudyGradient,
      ambientGlowColor: AppColors.onSurfaceVariant,
      accentColor: AppColors.onSurfaceSoft,
      icon: Icons.cloud_rounded,
      badgeLabel: 'Berawan',
    ),
    WeatherConditionCategory.hazeFog: AtmosphereVisualTheme(
      sceneType: SkySceneType.hazeFog,
      skyGradientColors: _hazeGradient,
      ambientGlowColor: AppColors.onSurfaceMuted,
      accentColor: AppColors.tertiary,
      icon: Icons.foggy,
      badgeLabel: 'Kabut / Kabur',
    ),
    WeatherConditionCategory.lightRain: AtmosphereVisualTheme(
      sceneType: SkySceneType.lightRain,
      skyGradientColors: _lightRainGradient,
      ambientGlowColor: AppColors.tertiary,
      accentColor: AppColors.tertiary,
      icon: Icons.grain_rounded,
      badgeLabel: 'Hujan Ringan',
    ),
    WeatherConditionCategory.heavyRain: AtmosphereVisualTheme(
      sceneType: SkySceneType.storm,
      skyGradientColors: _stormGradient,
      ambientGlowColor: AppColors.primaryContainer,
      accentColor: AppColors.tertiary,
      icon: Icons.water_drop_rounded,
      badgeLabel: 'Hujan Lebat',
    ),
    WeatherConditionCategory.thunderstorm: AtmosphereVisualTheme(
      sceneType: SkySceneType.storm,
      skyGradientColors: _stormGradient,
      ambientGlowColor: AppColors.secondary,
      accentColor: AppColors.secondary,
      icon: Icons.thunderstorm_rounded,
      badgeLabel: 'Badai Petir',
    ),
  };

  static const Map<WeatherConditionCategory, AtmosphereVisualTheme>
      _nightThemeMap = {
    WeatherConditionCategory.clear: AtmosphereVisualTheme(
      sceneType: SkySceneType.night,
      skyGradientColors: _nightGradient,
      ambientGlowColor: AppColors.primary,
      accentColor: AppColors.primary,
      icon: Icons.nights_stay_rounded,
      badgeLabel: 'Malam Cerah',
    ),
    WeatherConditionCategory.partlyCloudy: AtmosphereVisualTheme(
      sceneType: SkySceneType.night,
      skyGradientColors: _nightGradient,
      ambientGlowColor: AppColors.primary,
      accentColor: AppColors.primary,
      icon: Icons.nights_stay_outlined,
      badgeLabel: 'Berawan Malam',
    ),
    WeatherConditionCategory.cloudy: AtmosphereVisualTheme(
      sceneType: SkySceneType.cloudy,
      skyGradientColors: _nightGradient,
      ambientGlowColor: AppColors.onSurfaceMuted,
      accentColor: AppColors.onSurfaceSoft,
      icon: Icons.cloud_rounded,
      badgeLabel: 'Mendung Malam',
    ),
    WeatherConditionCategory.hazeFog: AtmosphereVisualTheme(
      sceneType: SkySceneType.hazeFog,
      skyGradientColors: _hazeGradient,
      ambientGlowColor: AppColors.onSurfaceMuted,
      accentColor: AppColors.tertiary,
      icon: Icons.foggy,
      badgeLabel: 'Kabut Malam',
    ),
    WeatherConditionCategory.lightRain: AtmosphereVisualTheme(
      sceneType: SkySceneType.lightRain,
      skyGradientColors: _lightRainGradient,
      ambientGlowColor: AppColors.tertiary,
      accentColor: AppColors.tertiary,
      icon: Icons.grain_rounded,
      badgeLabel: 'Hujan Malam',
    ),
    WeatherConditionCategory.heavyRain: AtmosphereVisualTheme(
      sceneType: SkySceneType.storm,
      skyGradientColors: _stormGradient,
      ambientGlowColor: AppColors.primaryContainer,
      accentColor: AppColors.tertiary,
      icon: Icons.water_drop_rounded,
      badgeLabel: 'Hujan Lebat',
    ),
    WeatherConditionCategory.thunderstorm: AtmosphereVisualTheme(
      sceneType: SkySceneType.storm,
      skyGradientColors: _stormGradient,
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
