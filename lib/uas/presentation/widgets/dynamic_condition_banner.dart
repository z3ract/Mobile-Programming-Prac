import 'package:flutter/material.dart';
import '../../domain/entities/nowcast_alert_entity.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/strategies/weather_advisory_strategy.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/atmosphere_theme_strategy.dart';
import 'glass_card.dart';

/// Displays active BMKG provincial CAP warning when present, or dynamic condition advice.
class DynamicConditionBanner extends StatelessWidget {
  final WeatherForecastEntity? forecast;
  final List<NowcastRssItemEntity> matchingNowcasts;
  final VoidCallback onOpenAlerts;

  const DynamicConditionBanner({
    super.key,
    required this.forecast,
    required this.matchingNowcasts,
    required this.onOpenAlerts,
  });

  @override
  Widget build(BuildContext context) {
    if (matchingNowcasts.isNotEmpty) {
      final nowcast = matchingNowcasts.first;
      return GlassCard(
        borderRadius: 22,
        padding: const EdgeInsets.all(14),
        backgroundColor: AppColors.accentRose.withValues(alpha: 0.18),
        borderColor: AppColors.accentRose.withValues(alpha: 0.48),
        onTap: onOpenAlerts,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accentRose.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.accentRose,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PERINGATAN DINI CUACA BMKG',
                    style: AppTypography.labelUppercase(
                      color: AppColors.accentRose,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    nowcast.title,
                    style: AppTypography.bodySm(color: AppColors.onSurface)
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nowcast.description,
                    style: AppTypography.labelCompact(
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      );
    }

    if (forecast == null) return const SizedBox.shrink();

    final slot = forecast!.current;
    final policy = WeatherCodeRegistry.resolvePolicy(
      slot.weatherCode,
      fallbackDesc: slot.weatherDesc,
    );
    final severitySpec = SeverityVisualRegistry.resolveSeverity(policy.severity);

    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(14),
      onTap: onOpenAlerts,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: severitySpec.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: severitySpec.color.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              severitySpec.icon,
              color: severitySpec.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      severitySpec.label,
                      style: AppTypography.labelCompact(
                        color: severitySpec.color,
                      ).copyWith(fontSize: 10.5, fontWeight: FontWeight.w700),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '·',
                        style: TextStyle(color: AppColors.onSurfaceMuted),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        policy.advisoryHeadline,
                        style: AppTypography.bodySm(color: AppColors.onSurface)
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  policy.activityRecommendation,
                  style: AppTypography.bodySm(
                    color: AppColors.onSurfaceVariant,
                  ).copyWith(height: 1.38),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
