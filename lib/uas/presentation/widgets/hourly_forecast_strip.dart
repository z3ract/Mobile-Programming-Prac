import 'package:flutter/material.dart';
import '../../domain/entities/weather_entity.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/atmosphere_theme_strategy.dart';
import 'glass_card.dart';

/// Horizontal strip displaying BMKG 3-hourly forecast slots for the next 24-30 hours.
class HourlyForecastStrip extends StatelessWidget {
  final List<WeatherSlotEntity> slots;
  final WeatherSlotEntity currentSlot;

  const HourlyForecastStrip({
    super.key,
    required this.slots,
    required this.currentSlot,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();
    final visibleSlots = slots.take(10).toList();
    final currentTheme = AtmosphereThemeRegistry.resolveByWeatherCode(
      currentSlot.weatherCode,
      fallbackDesc: currentSlot.weatherDesc,
      isNight: currentSlot.isNightTime,
    );

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'PRAKIRAAN PER 3 JAM (BMKG)',
                        style: AppTypography.labelUppercase(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  currentSlot.weatherDesc,
                  style: AppTypography.labelCompact(
                    color: currentTheme.accentColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: visibleSlots.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = visibleSlots[index];
                final isCurrent = item.localDateTime == currentSlot.localDateTime;
                final theme = AtmosphereThemeRegistry.resolveByWeatherCode(
                  item.weatherCode,
                  fallbackDesc: item.weatherDesc,
                  isNight: item.isNightTime,
                );

                return Container(
                  width: 68,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.surfaceBright.withValues(alpha: 0.42)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: isCurrent
                        ? Border.all(
                            color: theme.accentColor.withValues(alpha: 0.45),
                          )
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCurrent ? 'Saat ini' : item.timeLabel,
                        style: AppTypography.labelCompact(
                          color: isCurrent
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Icon(theme.icon, size: 22, color: theme.accentColor),
                      Text(
                        item.precipitationMm > 0
                            ? '${item.precipitationMm.toStringAsFixed(1)}mm'
                            : '${item.humidity}%',
                        style: AppTypography.labelCompact(
                          color: item.precipitationMm > 0
                              ? AppColors.tertiary
                              : AppColors.outline,
                        ),
                      ),
                      Text(
                        '${item.tempC.round()}°',
                        style: AppTypography.headlineSm(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
