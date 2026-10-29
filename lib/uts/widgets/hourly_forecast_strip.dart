import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import 'glass_card.dart';

class HourlyForecastStrip extends StatelessWidget {
  final List<HourlyForecast> hourly;

  const HourlyForecastStrip({
    super.key,
    required this.hourly,
  });

  IconData _getIcon(String code) {
    switch (code) {
      case 'sunny':
        return Icons.wb_sunny_rounded;
      case 'partly_cloudy':
        return Icons.wb_cloudy_rounded;
      case 'rain':
        return Icons.grain_rounded;
      case 'thunder':
        return Icons.thunderstorm_rounded;
      case 'night_clear':
        return Icons.nightlight_round;
      default:
        return Icons.cloud_rounded;
    }
  }

  Color _getIconColor(String code) {
    if (code == 'sunny') return AppColors.secondary;
    if (code == 'thunder') return AppColors.secondary;
    if (code == 'rain') return AppColors.tertiary;
    return AppColors.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    if (hourly.isEmpty) return const SizedBox.shrink();

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
                    const Icon(Icons.schedule_rounded, size: 15, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'PRAKIRAAN PER JAM',
                        style: AppTypography.labelUppercase(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Hujan ringan',
                style: AppTypography.labelCompact(color: AppColors.tertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: hourly.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = hourly[index];
                final bool isNow = index == 0;

                return Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isNow
                        ? AppColors.surfaceBright.withValues(alpha: 0.35)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: isNow
                        ? Border.all(color: Colors.white.withValues(alpha: 0.15))
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.time,
                        style: AppTypography.labelCompact(
                          color: isNow ? AppColors.onSurface : AppColors.onSurfaceVariant,
                        ),
                      ),
                      Icon(
                        _getIcon(item.iconCode),
                        size: 22,
                        color: _getIconColor(item.iconCode),
                      ),
                      Text(
                        '${item.tempC}°',
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
