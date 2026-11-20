import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/atmosphere_theme_strategy.dart';

/// Strategy contract for painting a scaled 64x64 vector weather emblem.
abstract interface class IWeatherIconPainterStrategy {
  void paint(Canvas canvas, double s, double phase);
}

/// Custom vector weather icon inspired by contoh.html with O(1) strategy dispatch.
class WeatherConditionIcon extends StatefulWidget {
  final int weatherCode;
  final String? fallbackDesc;
  final bool isNight;
  final double size;
  final bool animate;

  const WeatherConditionIcon({
    super.key,
    required this.weatherCode,
    this.fallbackDesc,
    this.isNight = false,
    this.size = 26,
    this.animate = false,
  });

  @override
  State<WeatherConditionIcon> createState() => _WeatherConditionIconState();
}

class _WeatherConditionIconState extends State<WeatherConditionIcon>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant WeatherConditionIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate || oldWidget.size != widget.size) {
      _syncController();
    }
  }

  void _syncController() {
    final shouldAnimate = widget.animate && widget.size >= 56;
    if (shouldAnimate && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 12),
      )..repeat();
    } else if (!shouldAnimate && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AtmosphereThemeRegistry.resolveByWeatherCode(
      widget.weatherCode,
      fallbackDesc: widget.fallbackDesc,
      isNight: widget.isNight,
    );
    final strategy = _WeatherIconRegistry.resolve(theme.sceneType);

    if (_controller == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _WeatherIconCanvasPainter(strategy: strategy, phase: 0.25),
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller!,
        builder: (_, _) => CustomPaint(
          painter: _WeatherIconCanvasPainter(
            strategy: strategy,
            phase: _controller!.value,
          ),
        ),
      ),
    );
  }
}

class _WeatherIconCanvasPainter extends CustomPainter {
  final IWeatherIconPainterStrategy strategy;
  final double phase;

  const _WeatherIconCanvasPainter({
    required this.strategy,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = math.min(size.width, size.height) / 64.0;
    strategy.paint(canvas, scale, phase);
  }

  @override
  bool shouldRepaint(covariant _WeatherIconCanvasPainter oldDelegate) =>
      oldDelegate.strategy != strategy || oldDelegate.phase != phase;
}

class _WeatherIconRegistry {
  static const Map<SkySceneType, IWeatherIconPainterStrategy> _strategies = {
    SkySceneType.sunny: _SunnyIconPainter(),
    SkySceneType.partlyCloudy: _PartlyCloudyIconPainter(),
    SkySceneType.cloudy: _CloudyIconPainter(),
    SkySceneType.hazeFog: _HazeFogIconPainter(),
    SkySceneType.lightRain: _LightRainIconPainter(),
    SkySceneType.storm: _StormIconPainter(),
    SkySceneType.night: _NightIconPainter(),
  };

  static IWeatherIconPainterStrategy resolve(SkySceneType type) =>
      _strategies[type] ?? const _PartlyCloudyIconPainter();
}

void _drawCloudShape(
  Canvas canvas,
  double s, {
  required Offset offset,
  required double widthScale,
  required Color topColor,
  required Color bottomColor,
}) {
  final rect = Rect.fromLTWH(
    (10 + offset.dx) * s,
    (16 + offset.dy) * s,
    44 * widthScale * s,
    24 * widthScale * s,
  );
  final paint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [topColor, bottomColor],
    ).createShader(rect);

  final path = Path();
  final double ox = offset.dx * s;
  final double oy = offset.dy * s;
  final double w = widthScale * s;

  path.addRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(10 * w + ox, 25 * w + oy, 44 * w, 15 * w),
      Radius.circular(7.5 * w),
    ),
  );
  path.addOval(
    Rect.fromCircle(center: Offset(23 * w + ox, 25 * w + oy), radius: 9.5 * w),
  );
  path.addOval(
    Rect.fromCircle(center: Offset(35 * w + ox, 21.5 * w + oy), radius: 12 * w),
  );
  path.addOval(
    Rect.fromCircle(center: Offset(44.5 * w + ox, 28 * w + oy), radius: 8.5 * w),
  );
  canvas.drawPath(path, paint);
}

class _SunnyIconPainter implements IWeatherIconPainterStrategy {
  const _SunnyIconPainter();

  @override
  void paint(Canvas canvas, double s, double phase) {
    final center = Offset(32 * s, 32 * s);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFDE68A).withValues(alpha: 0.36),
          const Color(0xFFF59E0B).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 29 * s));
    canvas.drawCircle(center, 29 * s, glowPaint);

    final rayPaint = Paint()
      ..color = const Color(0xFFFDE68A).withValues(alpha: 0.92)
      ..strokeWidth = 2.6 * s
      ..strokeCap = StrokeCap.round;

    final double baseAngle = phase * math.pi * 2.0;
    for (int i = 0; i < 8; i++) {
      final double a = baseAngle + (i * math.pi / 4.0);
      final p1 = Offset(
        center.dx + math.cos(a) * 19.5 * s,
        center.dy + math.sin(a) * 19.5 * s,
      );
      final p2 = Offset(
        center.dx + math.cos(a) * 25.0 * s,
        center.dy + math.sin(a) * 25.0 * s,
      );
      canvas.drawLine(p1, p2, rayPaint);
    }

    final sunRect = Rect.fromCircle(center: center, radius: 14 * s);
    final sunPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        colors: [Color(0xFFFFF7C2), Color(0xFFFCD34D), Color(0xFFF59E0B)],
        stops: [0.0, 0.58, 1.0],
      ).createShader(sunRect);
    canvas.drawCircle(center, 14 * s, sunPaint);
  }
}

class _PartlyCloudyIconPainter implements IWeatherIconPainterStrategy {
  const _PartlyCloudyIconPainter();

  @override
  void paint(Canvas canvas, double s, double phase) {
    final double bob = math.sin(phase * math.pi * 2.0) * 1.4;
    final sunCenter = Offset(42 * s, 21 * s);
    final sunPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        colors: [Color(0xFFFEF08A), Color(0xFFF59E0B)],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 10.5 * s));
    canvas.drawCircle(sunCenter, 10.5 * s, sunPaint);

    _drawCloudShape(
      canvas,
      s,
      offset: Offset(0, 6 + bob),
      widthScale: 1.0,
      topColor: Colors.white,
      bottomColor: const Color(0xFFDBEAFE),
    );
  }
}

class _CloudyIconPainter implements IWeatherIconPainterStrategy {
  const _CloudyIconPainter();

  @override
  void paint(Canvas canvas, double s, double phase) {
    final double bob = math.sin(phase * math.pi * 2.0) * 1.4;
    _drawCloudShape(
      canvas,
      s,
      offset: Offset(5, -2 - bob * 0.5),
      widthScale: 0.78,
      topColor: const Color(0xFFE2E8F0).withValues(alpha: 0.78),
      bottomColor: const Color(0xFF94A3B8).withValues(alpha: 0.78),
    );
    _drawCloudShape(
      canvas,
      s,
      offset: Offset(-1, 5 + bob),
      widthScale: 1.0,
      topColor: Colors.white,
      bottomColor: const Color(0xFFCBD5E1),
    );
  }
}

class _HazeFogIconPainter implements IWeatherIconPainterStrategy {
  const _HazeFogIconPainter();

  @override
  void paint(Canvas canvas, double s, double phase) {
    final double bob = math.sin(phase * math.pi * 2.0) * 1.1;
    _drawCloudShape(
      canvas,
      s,
      offset: Offset(0, -1 + bob),
      widthScale: 0.96,
      topColor: const Color(0xFFF1F5F9),
      bottomColor: const Color(0xFF94A3B8),
    );

    final mistPaint = Paint()
      ..color = const Color(0xFFBAE6FD).withValues(alpha: 0.85)
      ..strokeWidth = 2.6 * s
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(14 * s, 45 * s), Offset(50 * s, 45 * s), mistPaint);
    canvas.drawLine(Offset(19 * s, 51 * s), Offset(45 * s, 51 * s), mistPaint);
  }
}

class _LightRainIconPainter implements IWeatherIconPainterStrategy {
  const _LightRainIconPainter();

  @override
  void paint(Canvas canvas, double s, double phase) {
    final double bob = math.sin(phase * math.pi * 2.0) * 1.3;
    _drawCloudShape(
      canvas,
      s,
      offset: Offset(0, -1 + bob),
      widthScale: 1.0,
      topColor: Colors.white,
      bottomColor: const Color(0xFFCBD5E1),
    );

    final dropPaint = Paint()
      ..color = const Color(0xFF7DD3FC)
      ..strokeWidth = 2.6 * s
      ..strokeCap = StrokeCap.round;

    final double fall = (phase * 3.0) % 1.0;
    final drops = [
      (x: 22.0, y: 43.0 + fall * 4.0),
      (x: 32.0, y: 45.0 + ((fall + 0.35) % 1.0) * 4.0),
      (x: 42.0, y: 43.0 + ((fall + 0.7) % 1.0) * 4.0),
    ];
    for (final d in drops) {
      canvas.drawLine(
        Offset(d.x * s, d.y * s),
        Offset((d.x - 2.4) * s, (d.y + 7.2) * s),
        dropPaint,
      );
    }
  }
}

class _StormIconPainter implements IWeatherIconPainterStrategy {
  const _StormIconPainter();

  @override
  void paint(Canvas canvas, double s, double phase) {
    final double bob = math.sin(phase * math.pi * 2.0) * 1.2;
    _drawCloudShape(
      canvas,
      s,
      offset: Offset(0, -2 + bob),
      widthScale: 1.0,
      topColor: const Color(0xFFE2E8F0),
      bottomColor: const Color(0xFF94A3B8),
    );

    final boltPaint = Paint()..color = const Color(0xFFFDE047);
    final bolt = Path()
      ..moveTo(33.5 * s, 37 * s)
      ..lineTo(26.5 * s, 47.5 * s)
      ..lineTo(32 * s, 47.5 * s)
      ..lineTo(29.5 * s, 56 * s)
      ..lineTo(38.5 * s, 44.5 * s)
      ..lineTo(32.5 * s, 44.5 * s)
      ..close();
    canvas.drawPath(bolt, boltPaint);

    final rainPaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(20 * s, 43 * s), Offset(17.5 * s, 50 * s), rainPaint);
    canvas.drawLine(Offset(44 * s, 43 * s), Offset(41.5 * s, 50 * s), rainPaint);
  }
}

class _NightIconPainter implements IWeatherIconPainterStrategy {
  const _NightIconPainter();

  @override
  void paint(Canvas canvas, double s, double phase) {
    final double bob = math.sin(phase * math.pi * 2.0) * 1.4;
    final moonCenter = Offset(29 * s, (30 + bob) * s);

    final moonPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFEF9C3), Color(0xFFCBD5E1)],
      ).createShader(Rect.fromCircle(center: moonCenter, radius: 17 * s));

    final fullMoon = Path()
      ..addOval(Rect.fromCircle(center: moonCenter, radius: 16.5 * s));
    final cutout = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(moonCenter.dx + 8.5 * s, moonCenter.dy - 6.5 * s),
          radius: 13.5 * s,
        ),
      );
    final crescent = Path.combine(PathOperation.difference, fullMoon, cutout);
    canvas.drawPath(crescent, moonPaint);

    final double twinkle = 0.55 + 0.45 * math.sin(phase * math.pi * 4.0);
    canvas.drawCircle(
      Offset(46 * s, 18 * s),
      2.3 * s,
      Paint()..color = const Color(0xFFFEF08A).withValues(alpha: twinkle),
    );
    canvas.drawCircle(
      Offset(51 * s, 28 * s),
      1.5 * s,
      Paint()..color = const Color(0xFFE0E7FF).withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      Offset(37 * s, 13 * s),
      1.3 * s,
      Paint()..color = const Color(0xFFE0E7FF).withValues(alpha: 0.75),
    );
  }
}
