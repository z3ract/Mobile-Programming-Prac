import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/utils/meteorology_calculator.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';
import 'weather_condition_icon.dart';

/// Interactive 3-hourly BMKG strip featuring a cubic-bezier temperature curve
/// and a reactive 3-column detail summary for the selected time slot.
class HourlyForecastStrip extends StatefulWidget {
  final List<WeatherSlotEntity> slots;
  final WeatherSlotEntity currentSlot;
  final bool useFahrenheit;

  const HourlyForecastStrip({
    super.key,
    required this.slots,
    required this.currentSlot,
    this.useFahrenheit = false,
  });

  @override
  State<HourlyForecastStrip> createState() => _HourlyForecastStripState();
}

class _HourlyForecastStripState extends State<HourlyForecastStrip> {
  int _selectedIndex = 0;

  static const double _cardWidth = 68.0;
  static const double _cardGap = 8.0;
  static const double _curveHeight = 56.0;

  int _convertTemp(double celsius) => widget.useFahrenheit
      ? ((celsius * 9.0 / 5.0) + 32.0).round()
      : celsius.round();

  @override
  Widget build(BuildContext context) {
    if (widget.slots.isEmpty) return const SizedBox.shrink();

    final visibleSlots = widget.slots.take(10).toList();
    final safeIndex = _selectedIndex.clamp(0, visibleSlots.length - 1);
    final selectedSlot = visibleSlots[safeIndex];
    final feelsLike = MeteorologyCalculator.calculateFeelsLikeC(
      selectedSlot.tempC,
      selectedSlot.humidity,
    );

    final double trackWidth = visibleSlots.length * _cardWidth +
        math.max(0, visibleSlots.length - 1) * _cardGap;
    final List<int> temps =
        visibleSlots.map((s) => _convertTemp(s.tempC)).toList();

    return GlassCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(16),
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
                        'PRAKIRAAN PER 3 JAM',
                        style: AppTypography.labelUppercase(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                selectedSlot.localDateTime == widget.currentSlot.localDateTime
                    ? 'Saat ini'
                    : 'Pukul ${selectedSlot.timeLabel}',
                style: AppTypography.labelCompact(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: trackWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: trackWidth,
                    height: _curveHeight,
                    child: CustomPaint(
                      painter: _HourlyTempCurvePainter(
                        temperatures: temps,
                        selectedIndex: safeIndex,
                        cardWidth: _cardWidth,
                        cardGap: _cardGap,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(visibleSlots.length, (index) {
                      final slot = visibleSlots[index];
                      final isSelected = index == safeIndex;
                      final isNow = slot.localDateTime ==
                          widget.currentSlot.localDateTime;

                      return Padding(
                        padding: EdgeInsets.only(
                          right: index == visibleSlots.length - 1
                              ? 0
                              : _cardGap,
                        ),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _cardWidth,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.20)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.38)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isNow ? 'Sekarang' : slot.timeLabel,
                                  style: AppTypography.labelCompact(
                                    color: isSelected
                                        ? AppColors.onSurface
                                        : AppColors.onSurfaceVariant,
                                  ).copyWith(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                WeatherConditionIcon(
                                  weatherCode: slot.weatherCode,
                                  fallbackDesc: slot.weatherDesc,
                                  isNight: slot.isNightTime,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  slot.precipitationMm > 0
                                      ? '${slot.precipitationMm.toStringAsFixed(1)}mm'
                                      : '${slot.humidity}%',
                                  style: AppTypography.tabularSm(
                                    color: slot.precipitationMm > 0
                                        ? AppColors.tertiary
                                        : AppColors.onSurfaceMuted,
                                  ).copyWith(fontSize: 10.5),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailPill(
                  label: 'Curah Hujan',
                  value:
                      '${selectedSlot.precipitationMm.toStringAsFixed(1)} mm',
                  valueColor: AppColors.tertiary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailPill(
                  label: 'Angin',
                  value: '${selectedSlot.windSpeedKm.round()} km/j',
                  valueColor: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailPill(
                  label: 'Suhu Terasa',
                  value: '${_convertTemp(feelsLike)}°',
                  valueColor: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPill({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.labelCompact(color: AppColors.onSurfaceMuted)
                .copyWith(fontSize: 10.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.tabularSm(color: valueColor).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HourlyTempCurvePainter extends CustomPainter {
  final List<int> temperatures;
  final int selectedIndex;
  final double cardWidth;
  final double cardGap;

  const _HourlyTempCurvePainter({
    required this.temperatures,
    required this.selectedIndex,
    required this.cardWidth,
    required this.cardGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (temperatures.isEmpty) return;

    int minT = temperatures.first;
    int maxT = temperatures.first;
    for (final t in temperatures) {
      if (t < minT) minT = t;
      if (t > maxT) maxT = t;
    }
    final int span = math.max(maxT - minT, 1);

    final List<Offset> points = List.generate(temperatures.length, (i) {
      final double x = i * (cardWidth + cardGap) + (cardWidth / 2.0);
      final double norm =
          temperatures.length == 1 ? 0.5 : (temperatures[i] - minT) / span;
      final double y = (size.height - 14.0) - norm * (size.height - 32.0);
      return Offset(x, y);
    });

    if (points.length > 1) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final cx = (p0.dx + p1.dx) / 2.0;
        linePath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
      }

      final areaPath = Path.from(linePath)
        ..lineTo(points.last.dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();

      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size);
      canvas.drawPath(areaPath, areaPaint);

      final strokePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(linePath, strokePaint);
    }

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isSelected = i == selectedIndex;

      if (isSelected) {
        canvas.drawCircle(
          pt,
          7.5,
          Paint()..color = Colors.white.withValues(alpha: 0.22),
        );
      }
      canvas.drawCircle(
        pt,
        isSelected ? 4.0 : 2.6,
        Paint()
          ..color =
              isSelected ? Colors.white : Colors.white.withValues(alpha: 0.72),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${temperatures[i]}°',
          style: TextStyle(
            color:
                isSelected ? Colors.white : Colors.white.withValues(alpha: 0.75),
            fontSize: isSelected ? 11.5 : 10.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(pt.dx - (textPainter.width / 2.0), pt.dy - textPainter.height - 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HourlyTempCurvePainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.temperatures != temperatures;
}
