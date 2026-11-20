import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/utils/meteorology_calculator.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';

/// Modular 2x2 translucent glass grid displaying BMKG metrics and wind compass.
class WeatherBentoGrid extends StatelessWidget {
  final WeatherForecastEntity forecast;
  final bool useFahrenheit;

  const WeatherBentoGrid({
    super.key,
    required this.forecast,
    this.useFahrenheit = false,
  });

  int _convertTemp(double celsius) =>
      useFahrenheit ? ((celsius * 9.0 / 5.0) + 32.0).round() : celsius.round();

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
        ? 'Langit relatif bersih'
        : slot.cloudCoverPct <= 65
            ? 'Berawan sebagian'
            : 'Tutupan awan tebal';

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildWindCompassCard(slot, windFrom, windTo)),
              const SizedBox(width: 12),
              Expanded(child: _buildHumidityCard(slot)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildCloudCoverCard(slot, cloudLabel)),
              const SizedBox(width: 12),
              Expanded(child: _buildVisibilityCard(slot)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWindCompassCard(
    WeatherSlotEntity slot,
    String windFrom,
    String windTo,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCardHeader(icon: Icons.air_rounded, title: 'ANGIN'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${slot.windSpeedKm.round()}',
                          style: AppTypography.metricLg(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'km/j',
                          style: AppTypography.labelCompact(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      windFrom,
                      style: AppTypography.bodySm(color: AppColors.onSurface)
                          .copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 54,
                height: 54,
                child: CustomPaint(
                  painter: _WindCompassPainter(degree: slot.windDegree),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Menuju $windTo (${slot.windDegree}°)',
            style: AppTypography.labelCompact(color: AppColors.onSurfaceMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityCard(WeatherSlotEntity slot) {
    final double ratio = (slot.humidity / 100.0).clamp(0.05, 1.0);
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCardHeader(icon: Icons.water_drop_rounded, title: 'KELEMBAPAN'),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('${slot.humidity}', style: AppTypography.metricLg()),
                  const SizedBox(width: 2),
                  Text(
                    '%',
                    style: AppTypography.bodyMd(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 6,
                  color: Colors.white.withValues(alpha: 0.14),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7DD3FC), Color(0xFFA5F3FC)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Titik embun ${_convertTemp(forecast.dewPointC)}° saat ini.',
            style: AppTypography.labelCompact(color: AppColors.onSurfaceMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCloudCoverCard(WeatherSlotEntity slot, String cloudLabel) {
    final double ratio = (slot.cloudCoverPct / 100.0).clamp(0.05, 1.0);
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCardHeader(
            icon: Icons.cloud_queue_rounded,
            title: 'TUTUPAN AWAN',
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${slot.cloudCoverPct}',
                    style: AppTypography.metricLg(),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '%',
                    style: AppTypography.bodyMd(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 6,
                  color: Colors.white.withValues(alpha: 0.14),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF93C5FD), Color(0xFFE2E8F0)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$cloudLabel · ${slot.weatherDesc}.',
            style: AppTypography.labelCompact(color: AppColors.onSurfaceMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityCard(WeatherSlotEntity slot) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCardHeader(
            icon: Icons.visibility_rounded,
            title: 'JARAK PANDANG',
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slot.visibilityText,
                style: AppTypography.metricMd(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Terasa ${_convertTemp(forecast.feelsLikeC)}°',
                style: AppTypography.bodySm(color: AppColors.onSurfaceSoft),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Hujan ${slot.precipitationMm.toStringAsFixed(1)} mm · ${forecast.region.timezone}.',
            style: AppTypography.labelCompact(color: AppColors.onSurfaceMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader({required IconData icon, required String title}) {
    return Row(
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
    );
  }
}

class _WindCompassPainter extends CustomPainter {
  final int degree;

  const _WindCompassPainter({required this.degree});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.0, size.height / 2.0);
    final double radius = math.min(size.width, size.height) * 0.44;

    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, radius, ringPaint);

    _drawCardinal(canvas, center, radius, 'U', const Offset(0, -1));
    _drawCardinal(canvas, center, radius, 'S', const Offset(0, 1));
    _drawCardinal(canvas, center, radius, 'T', const Offset(1, 0));
    _drawCardinal(canvas, center, radius, 'B', const Offset(-1, 0));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(degree * math.pi / 180.0);

    final tip = Path()
      ..moveTo(0, -radius * 0.70)
      ..lineTo(3.4, 0)
      ..lineTo(0, -2.5)
      ..lineTo(-3.4, 0)
      ..close();
    canvas.drawPath(tip, Paint()..color = Colors.white);

    final tail = Path()
      ..moveTo(0, radius * 0.70)
      ..lineTo(3.0, 0)
      ..lineTo(0, 2.5)
      ..lineTo(-3.0, 0)
      ..close();
    canvas.drawPath(
      tail,
      Paint()..color = Colors.white.withValues(alpha: 0.32),
    );
    canvas.restore();

    canvas.drawCircle(center, 2.4, Paint()..color = Colors.white);
  }

  void _drawCardinal(
    Canvas canvas,
    Offset center,
    double radius,
    String text,
    Offset dir,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: text == 'U'
              ? Colors.white.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.45),
          fontSize: 7.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pos = Offset(
      center.dx + dir.dx * (radius * 0.74) - tp.width / 2.0,
      center.dy + dir.dy * (radius * 0.74) - tp.height / 2.0,
    );
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _WindCompassPainter oldDelegate) =>
      oldDelegate.degree != degree;
}
