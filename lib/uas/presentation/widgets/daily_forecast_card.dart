import 'package:flutter/material.dart';
import '../../domain/entities/weather_entity.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';
import 'weather_condition_icon.dart';

/// Multi-day BMKG summary card featuring gradient temperature range bars and
/// tap-to-expand daily meteorological details.
class DailyForecastCard extends StatefulWidget {
  final List<DailyWeatherSummaryEntity> daily;
  final bool useFahrenheit;

  const DailyForecastCard({
    super.key,
    required this.daily,
    this.useFahrenheit = false,
  });

  @override
  State<DailyForecastCard> createState() => _DailyForecastCardState();
}

class _DailyForecastCardState extends State<DailyForecastCard> {
  int? _expandedIndex;

  int _convertTemp(double celsius) => widget.useFahrenheit
      ? ((celsius * 9.0 / 5.0) + 32.0).round()
      : celsius.round();

  @override
  Widget build(BuildContext context) {
    if (widget.daily.isEmpty) return const SizedBox.shrink();

    double globalMin = widget.daily.first.minTempC;
    double globalMax = widget.daily.first.maxTempC;
    for (final item in widget.daily) {
      if (item.minTempC < globalMin) globalMin = item.minTempC;
      if (item.maxTempC > globalMax) globalMax = item.maxTempC;
    }
    final double span = (globalMax - globalMin).clamp(4.0, 50.0);

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
                      Icons.calendar_month_rounded,
                      size: 15,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'PRAKIRAAN ${widget.daily.length} HARI',
                        style: AppTypography.labelUppercase(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Ketuk untuk detail',
                style: AppTypography.labelCompact(
                  color: AppColors.onSurfaceMuted,
                ).copyWith(fontSize: 10.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...widget.daily.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isOpen = _expandedIndex == idx;

            final double startRatio =
                ((item.minTempC - globalMin) / span).clamp(0.0, 0.78);
            final double endRatio =
                ((item.maxTempC - globalMin) / span).clamp(0.22, 1.0);

            return Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() {
                    _expandedIndex = isOpen ? null : idx;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 78,
                          child: Text(
                            item.dayLabel,
                            style: AppTypography.bodySm(
                              color: idx == 0
                                  ? AppColors.onSurface
                                  : AppColors.onSurfaceSoft,
                            ).copyWith(
                              fontWeight:
                                  idx == 0 ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        WeatherConditionIcon(
                          weatherCode: item.dominantWeatherCode,
                          fallbackDesc: item.dominantCondition,
                          size: 23,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: Text(
                            item.totalPrecipitationMm > 0
                                ? '${item.totalPrecipitationMm.toStringAsFixed(0)}mm'
                                : '${item.avgHumidity}%',
                            style: AppTypography.tabularSm(
                              color: item.totalPrecipitationMm > 0
                                  ? AppColors.tertiary
                                  : AppColors.onSurfaceMuted,
                            ).copyWith(fontSize: 11),
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${_convertTemp(item.minTempC)}°',
                            textAlign: TextAlign.right,
                            style: AppTypography.tabularSm(
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final totalW = constraints.maxWidth;
                              final barLeft = totalW * startRatio;
                              final barWidth =
                                  (totalW * (endRatio - startRatio))
                                      .clamp(16.0, totalW);

                              return Stack(
                                alignment: Alignment.centerLeft,
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  Positioned(
                                    left: barLeft,
                                    child: Container(
                                      height: 5,
                                      width: barWidth,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF7DD3FC),
                                            Color(0xFFFDE68A),
                                            Color(0xFFFB923C),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (item.currentTempC != null)
                                    Positioned(
                                      left: (totalW *
                                              ((item.currentTempC! -
                                                      globalMin) /
                                                  span))
                                          .clamp(
                                        0.0,
                                        (totalW - 7).clamp(0.0, totalW),
                                      ),
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.surface,
                                            width: 1.2,
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
                          width: 30,
                          child: Text(
                            '${_convertTemp(item.maxTempC)}°',
                            textAlign: TextAlign.left,
                            style: AppTypography.tabularSm(
                              color: AppColors.onSurface,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        AnimatedRotation(
                          turns: isOpen ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 220),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    margin: const EdgeInsets.only(top: 2, bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.09),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dominan ${item.dominantCondition} pada ${item.dayLabel.toLowerCase()}.',
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceSoft,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Divider(
                          color: Colors.white.withValues(alpha: 0.08),
                          height: 1,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricMini(
                                label: 'Kelembapan',
                                value: '${item.avgHumidity}%',
                              ),
                            ),
                            Expanded(
                              child: _buildMetricMini(
                                label: 'Total Hujan',
                                value:
                                    '${item.totalPrecipitationMm.toStringAsFixed(1)} mm',
                              ),
                            ),
                            Expanded(
                              child: _buildMetricMini(
                                label: 'Rentang',
                                value:
                                    '${_convertTemp(item.minTempC)}° / ${_convertTemp(item.maxTempC)}°',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: isOpen
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                ),
                if (idx < widget.daily.length - 1)
                  Divider(
                    color: Colors.white.withValues(alpha: 0.08),
                    height: 1,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricMini({required String label, required String value}) {
    return Column(
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
          style: AppTypography.tabularSm(color: AppColors.onSurface)
              .copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
