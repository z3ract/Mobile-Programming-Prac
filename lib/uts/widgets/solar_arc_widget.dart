import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import 'glass_card.dart';

class SolarArcCard extends StatelessWidget {
  final String sunrise;
  final String sunset;

  const SolarArcCard({
    super.key,
    this.sunrise = '05:41 WIB',
    this.sunset = '17:54 WIB',
  });

  @override
  Widget build(BuildContext context) {
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
                  const Icon(Icons.wb_twilight_rounded, size: 15, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text('MATAHARI & SOL', style: AppTypography.labelUppercase()),
                ],
              ),
              Text('Durasi Siang: 12j 13m', style: AppTypography.labelCompact()),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            width: double.infinity,
            child: CustomPaint(
              painter: _SolarCurvePainter(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text('Terbit: $sunrise', style: AppTypography.bodySm(color: AppColors.onSurface)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.nights_stay_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('Terbenam: $sunset', style: AppTypography.bodySm(color: AppColors.onSurface)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SolarCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final horizonPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final arcPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.45)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double horizonY = size.height * 0.82;

    // Horizon line
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(size.width, horizonY),
      horizonPaint,
    );

    // Arch curve
    final path = Path();
    path.moveTo(size.width * 0.05, horizonY);
    path.quadraticBezierTo(
      size.width * 0.5,
      0,
      size.width * 0.95,
      horizonY,
    );
    canvas.drawPath(path, arcPaint);

    // Active Sun indicator at ~ 65% of day
    final double sunX = size.width * 0.62;
    final double sunY = size.height * 0.28;

    final sunGlow = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sunX, sunY), 10, sunGlow);

    final sunPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sunX, sunY), 5, sunPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
