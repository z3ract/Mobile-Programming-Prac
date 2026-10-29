import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import 'glass_card.dart';

class AirQualityBarCard extends StatelessWidget {
  final int aqi;
  final String status;

  const AirQualityBarCard({
    super.key,
    this.aqi = 42,
    this.status = 'Baik / Memuaskan',
  });

  @override
  Widget build(BuildContext context) {
    // Persentase posisi indikator (0 - 300 skala AQI)
    final double percent = (aqi / 200).clamp(0.05, 0.95);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.air_rounded, size: 15, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text('KUALITAS UDARA (AQI)', style: AppTypography.labelUppercase()),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('AQI $aqi • $status', style: AppTypography.labelCompact(color: AppColors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Horizontal Gradient Bar with dot
          LayoutBuilder(
            builder: (context, constraints) {
              final double barWidth = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 6,
                    width: barWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.tertiary,
                          AppColors.accentEmerald,
                          AppColors.secondary,
                          AppColors.accentRose,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (barWidth * percent) - 6,
                    top: -3,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            'Kualitas udara saat ini memuaskan dan risiko polusi sangat minim untuk sebagian besar orang.',
            style: AppTypography.bodySm(color: AppColors.onSurface),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PM2.5: 9 µg/m³', style: AppTypography.labelCompact()),
              Text('PM10: 18 µg/m³', style: AppTypography.labelCompact()),
              Text('NO₂: 12 ppb', style: AppTypography.labelCompact()),
            ],
          ),
        ],
      ),
    );
  }
}
