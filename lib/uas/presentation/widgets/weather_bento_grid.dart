import 'package:flutter/material.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/utils/meteorology_calculator.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';

/// Modular 2x2 Bento Grid displaying real BMKG meteorological parameters.
class WeatherBentoGrid extends StatelessWidget {
  final WeatherForecastEntity forecast;

  const WeatherBentoGrid({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    final slot = forecast.current;
    final windFrom = MeteorologyCalculator.windDirectionLabel(
      slot.windDirection,
    );
    final windTo = MeteorologyCalculator.windDirectionLabel(
      slot.windDirectionTo,
    );
    final cloudLabel = slot.cloudCoverPct <= 25
        ? 'Langit relatif cerah'
        : slot.cloudCoverPct <= 65
            ? 'Berawan sebagian'
            : 'Tutupan awan tebal';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBentoTile(
                icon: Icons.cloud_queue_rounded,
                title: 'TUTUPAN AWAN',
                value: '${slot.cloudCoverPct}',
                unit: '%',
                subtitle: cloudLabel,
                desc: 'Kondisi: ${slot.weatherDesc}.',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoTile(
                icon: Icons.air_rounded,
                title: 'ANGIN',
                value: slot.windSpeedKm.toStringAsFixed(1),
                unit: 'km/j',
                subtitle: '$windFrom (${slot.windDegree}°)',
                desc: 'Bertiup menuju $windTo.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBentoTile(
                icon: Icons.water_drop_rounded,
                title: 'KELEMBAPAN',
                value: '${slot.humidity}',
                unit: '%',
                subtitle: 'Titik embun ${forecast.dewPointC.round()}°C',
                desc:
                    'Curah hujan ${slot.precipitationMm.toStringAsFixed(1)} mm / 3 jam.',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoTile(
                icon: Icons.visibility_rounded,
                title: 'JARAK PANDANG',
                value: slot.visibilityText,
                subtitle: 'Terasa ${forecast.feelsLikeC.round()}°C',
                desc: 'Zona waktu ${forecast.region.timezone}.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoTile({
    required IconData icon,
    required String title,
    required String value,
    String? unit,
    required String subtitle,
    required String desc,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      height: 154,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelUppercase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: AppTypography.headlineLg(
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (unit != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySm(color: AppColors.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Text(
            desc,
            style: AppTypography.labelCompact(
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
