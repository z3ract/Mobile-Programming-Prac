import 'package:flutter/material.dart';
import '../../domain/entities/weather_entity.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/atmosphere_theme_strategy.dart';
import 'glass_card.dart';

/// Multi-day BMKG summary card with dynamically scaled temperature range bars.
class DailyForecastCard extends StatelessWidget {
  final List<DailyWeatherSummaryEntity> daily;

  const DailyForecastCard({super.key, required this.daily});

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) return const SizedBox.shrink();

    double globalMin = daily.first.minTempC;
    double globalMax = daily.first.maxTempC;
    for (final item in daily) {
      if (item.minTempC < globalMin) globalMin = item.minTempC;
      if (item.maxTempC > globalMax) globalMax = item.maxTempC;
    }
    final double span = (globalMax - globalMin).clamp(6.0, 50.0);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 15,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'PRAKIRAAN ${daily.length} HARI KE DEPAN (BMKG)',
                  style: AppTypography.labelUppercase(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...daily.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final theme = AtmosphereThemeRegistry.resolveByWeatherCode(
              item.dominantWeatherCode,
              fallbackDesc: item.dominantCondition,
            );

            final double startRatio =
                ((item.minTempC - globalMin) / span).clamp(0.0, 0.78);
            final double endRatio =
                ((item.maxTempC - globalMin) / span).clamp(0.22, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 82,
                        child: Text(
                          item.dayLabel,
                          style: AppTypography.bodySm(
                            color: idx == 0
                                ? AppColors.onSurface
                                : AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(theme.icon, size: 20, color: theme.accentColor),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 44,
                        child: Text(
                          item.totalPrecipitationMm > 0
                              ? '${item.totalPrecipitationMm.toStringAsFixed(0)}mm'
                              : '${item.avgHumidity}%',
                          style: AppTypography.labelCompact(
                            color: item.totalPrecipitationMm > 0
                                ? AppColors.tertiary
                                : AppColors.outline,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${item.minTempC.round()}°',
                          textAlign: TextAlign.right,
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final totalW = constraints.maxWidth;
                            final barLeft = totalW * startRatio;
                            final barWidth = (totalW * (endRatio - startRatio))
                                .clamp(16.0, totalW);

                            return Stack(
                              alignment: Alignment.centerLeft,
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Positioned(
                                  left: barLeft,
                                  child: Container(
                                    height: 4,
                                    width: barWidth,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.tertiary,
                                          AppColors.secondary,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (item.currentTempC != null)
                                  Positioned(
                                    left: (totalW *
                                            ((item.currentTempC! - globalMin) /
                                                span))
                                        .clamp(0.0, (totalW - 6).clamp(0.0, totalW)),
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.surface,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${item.maxTempC.round()}°',
                          textAlign: TextAlign.left,
                          style: AppTypography.bodySm(color: AppColors.onSurface),
                        ),
                      ),
                    ],
                  ),
                  if (idx < daily.length - 1)
                    Divider(
                      color: Colors.white.withValues(alpha: 0.05),
                      height: 8,
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
