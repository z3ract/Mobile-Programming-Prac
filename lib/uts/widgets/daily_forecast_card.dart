import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import 'glass_card.dart';

class DailyForecastCard extends StatelessWidget {
  final List<DailyForecast> daily;

  const DailyForecastCard({
    super.key,
    required this.daily,
  });

  IconData _getIcon(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('petir') || lower.contains('thunder')) return Icons.thunderstorm_rounded;
    if (lower.contains('hujan') || lower.contains('rain')) return Icons.grain_rounded;
    if (lower.contains('cerah') && lower.contains('berawan')) return Icons.wb_cloudy_rounded;
    if (lower.contains('cerah')) return Icons.wb_sunny_rounded;
    return Icons.cloud_rounded;
  }

  Color _getIconColor(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('petir')) return AppColors.secondary;
    if (lower.contains('hujan')) return AppColors.tertiary;
    if (lower.contains('cerah')) return AppColors.secondary;
    return AppColors.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) return const SizedBox.shrink();

    // Nilai terendah & tertinggi untuk normalisasi baris
    double globalMin = 20;
    double globalMax = 35;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 15, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('PRAKIRAAN 7 HARI KE DEPAN', style: AppTypography.labelUppercase()),
            ],
          ),
          const SizedBox(height: 10),
          ...daily.asMap().entries.map((entry) {
            final int idx = entry.key;
            final item = entry.value;

            // Normalisasi posisi bar
            final double startRatio = ((item.minTemp - globalMin) / (globalMax - globalMin)).clamp(0.0, 0.8);
            final double endRatio = ((item.maxTemp - globalMin) / (globalMax - globalMin)).clamp(0.2, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Day name
                      SizedBox(
                        width: 80,
                        child: Text(
                          item.day,
                          style: AppTypography.bodySm(
                            color: idx == 0 ? AppColors.onSurface : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      // Icon
                      Icon(
                        _getIcon(item.condition),
                        size: 20,
                        color: _getIconColor(item.condition),
                      ),
                      const SizedBox(width: 14),
                      // Min Temp
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${item.minTemp.toInt()}°',
                          textAlign: TextAlign.right,
                          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Range Bar
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double totalW = constraints.maxWidth;
                            final double barLeft = totalW * startRatio;
                            final double barWidth = (totalW * (endRatio - startRatio)).clamp(16.0, totalW);

                            return Stack(
                              alignment: Alignment.centerLeft,
                              clipBehavior: Clip.none,
                              children: [
                                // Background track
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                // Active range bar
                                Positioned(
                                  left: barLeft,
                                  child: Container(
                                    height: 4,
                                    width: barWidth,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      gradient: const LinearGradient(
                                        colors: [AppColors.tertiary, AppColors.secondary],
                                      ),
                                    ),
                                  ),
                                ),
                                // Current temperature dot (today only)
                                if (item.currentTemp != null) ...[
                                  Positioned(
                                    left: (totalW * ((item.currentTemp! - globalMin) / (globalMax - globalMin))).clamp(0.0, totalW - 6),
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.surface, width: 1),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Max Temp
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${item.maxTemp.toInt()}°',
                          textAlign: TextAlign.left,
                          style: AppTypography.bodySm(color: AppColors.onSurface),
                        ),
                      ),
                    ],
                  ),
                  if (idx < daily.length - 1)
                    Divider(color: Colors.white.withValues(alpha: 0.05), height: 8),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
