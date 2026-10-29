import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import 'glass_card.dart';

class WeatherBentoGrid extends StatelessWidget {
  final WeatherModel weather;

  const WeatherBentoGrid({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: UV Index & Wind
        Row(
          children: [
            Expanded(
              child: _buildBentoTile(
                icon: Icons.wb_sunny_rounded,
                title: 'INDEKS UV',
                value: '${weather.uvIndex}',
                subtitle: weather.uvIndex >= 6 ? 'Tinggi' : 'Sedang',
                desc: 'Gunakan tabir surya hingga pukul 16.00.',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoTile(
                icon: Icons.air_rounded,
                title: 'ANGIN',
                value: weather.windSpeedKm,
                unit: 'km/j',
                subtitle: weather.windDirection,
                desc: 'Hembusan angin sepoi-sepoi stabil.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Humidity & Pressure / Feels Like
        Row(
          children: [
            Expanded(
              child: _buildBentoTile(
                icon: Icons.water_drop_rounded,
                title: 'KELEMBAPAN',
                value: weather.humidity,
                unit: '%',
                subtitle: 'Lembap',
                desc: 'Titik embun ${weather.dewPoint} saat ini.',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoTile(
                icon: Icons.thermostat_rounded,
                title: 'SUHU TERASA',
                value: weather.feelsLikeC,
                unit: '°C',
                subtitle: 'Lebih hangat',
                desc: 'Tekanan ${weather.pressureMb}.',
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
      padding: const EdgeInsets.all(16),
      height: 156,
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
                  Text(
                    value,
                    style: AppTypography.headlineLg(color: AppColors.onSurface),
                  ),
                  if (unit != null) ...[
                    const SizedBox(width: 3),
                    Text(
                      unit,
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySm(color: AppColors.onSurface),
              ),
            ],
          ),
          Text(
            desc,
            style: AppTypography.labelCompact(color: AppColors.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
