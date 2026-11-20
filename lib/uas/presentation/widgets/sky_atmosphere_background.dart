import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/atmosphere_theme_strategy.dart';

/// Strategy contract for painting animated atmospheric sky scenes.
abstract interface class ISkyScenePainter {
  void paint(Canvas canvas, Size size, double phase);
}

/// Full-bleed atmospheric sky backdrop combining 4-stop gradients, procedural
/// sky phenomena (sun bokeh, drifting clouds, rain streaks, stars), and a contrast vignette.
class SkyAtmosphereBackground extends StatefulWidget {
  final AtmosphereVisualTheme visualTheme;
  final Widget child;
  final bool enableMotion;

  const SkyAtmosphereBackground({
    super.key,
    required this.visualTheme,
    required this.child,
    this.enableMotion = true,
  });

  @override
  State<SkyAtmosphereBackground> createState() =>
      _SkyAtmosphereBackgroundState();
}

class _SkyAtmosphereBackgroundState extends State<SkyAtmosphereBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant SkyAtmosphereBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enableMotion != widget.enableMotion) {
      _syncController();
    }
  }

  void _syncController() {
    if (widget.enableMotion && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 24),
      )..repeat();
    } else if (!widget.enableMotion && _controller != null) {
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
    final scenePainter = _SkySceneRegistry.resolve(widget.visualTheme.sceneType);

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-0.35, -1.0),
              end: const Alignment(0.35, 1.0),
              colors: widget.visualTheme.skyGradientColors,
              stops: widget.visualTheme.skyStops,
            ),
          ),
        ),
        IgnorePointer(
          child: _controller == null
              ? CustomPaint(
                  painter: _SkyCanvasPainter(
                    strategy: scenePainter,
                    phase: 0.35,
                  ),
                )
              : AnimatedBuilder(
                  animation: _controller!,
                  builder: (_, _) => CustomPaint(
                    painter: _SkyCanvasPainter(
                      strategy: scenePainter,
                      phase: _controller!.value,
                    ),
                  ),
                ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.22),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.42),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _SkyCanvasPainter extends CustomPainter {
  final ISkyScenePainter strategy;
  final double phase;

  const _SkyCanvasPainter({required this.strategy, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    strategy.paint(canvas, size, phase);
  }

  @override
  bool shouldRepaint(covariant _SkyCanvasPainter oldDelegate) =>
      oldDelegate.strategy != strategy || oldDelegate.phase != phase;
}

class _SkySceneRegistry {
  static const Map<SkySceneType, ISkyScenePainter> _painters = {
    SkySceneType.sunny: _SunnySkyPainter(),
    SkySceneType.partlyCloudy: _CloudySkyPainter(density: 5, opacityScale: 1.0),
    SkySceneType.cloudy: _CloudySkyPainter(density: 7, opacityScale: 1.15),
    SkySceneType.hazeFog: _HazeSkyPainter(),
    SkySceneType.lightRain: _RainSkyPainter(isStorm: false),
    SkySceneType.storm: _RainSkyPainter(isStorm: true),
    SkySceneType.night: _NightSkyPainter(),
  };

  static ISkyScenePainter resolve(SkySceneType type) =>
      _painters[type] ?? const _CloudySkyPainter(density: 5, opacityScale: 1.0);
}

void _drawSoftCloudBand(
  Canvas canvas,
  Offset center,
  double rx,
  double ry,
  double alpha,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(1.0, ry / rx);
  final paint = Paint()
    ..shader = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: alpha),
        const Color(0xFFE2EEFF).withValues(alpha: alpha * 0.45),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.58, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: rx));
  canvas.drawCircle(Offset.zero, rx, paint);
  canvas.restore();
}

class _SunnySkyPainter implements ISkyScenePainter {
  const _SunnySkyPainter();

  @override
  void paint(Canvas canvas, Size size, double phase) {
    final double pulse = 1.0 + math.sin(phase * math.pi * 4.0) * 0.04;
    final sunOrigin = Offset(size.width * 0.85, size.height * 0.09);
    final double glowRadius = math.max(size.width * 0.6, 220) * pulse;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF5C8).withValues(alpha: 0.36),
          const Color(0xFFFFD68C).withValues(alpha: 0.14),
          const Color(0xFFFFD68C).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: sunOrigin, radius: glowRadius));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.65),
      glowPaint,
    );

    for (int i = 0; i < 14; i++) {
      final double seed = (i * 0.6180339) % 1.0;
      final double x = ((seed + phase * (0.12 + (i % 3) * 0.04)) % 1.0) *
          size.width;
      final double y = (((i * 0.37) % 1.0) * 0.55 + 0.04) * size.height;
      final double r = 2.0 + (i % 4) * 1.1;
      final double alpha =
          (0.08 + (i % 3) * 0.05) *
          (0.75 + 0.25 * math.sin((phase * 6.0 + i) * math.pi));
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = const Color(0xFFFFF8DC).withValues(alpha: alpha),
      );
    }
  }
}

class _CloudySkyPainter implements ISkyScenePainter {
  final int density;
  final double opacityScale;

  const _CloudySkyPainter({
    required this.density,
    required this.opacityScale,
  });

  @override
  void paint(Canvas canvas, Size size, double phase) {
    for (int i = 0; i < density; i++) {
      final double seed = (i * 0.41) % 1.0;
      final double span = size.width + 260;
      final double x = ((seed * span + phase * (160 + (i % 3) * 70)) % span) -
          130;
      final double y = size.height * (0.08 + ((i * 0.19) % 0.42));
      final double rx = 105.0 + (i % 3) * 45.0;
      final double ry = 32.0 + (i % 2) * 14.0;
      final double alpha = (0.06 + (i % 3) * 0.025) * opacityScale;
      _drawSoftCloudBand(canvas, Offset(x, y), rx, ry, alpha.clamp(0.03, 0.16));
    }
  }
}

class _HazeSkyPainter implements ISkyScenePainter {
  const _HazeSkyPainter();

  @override
  void paint(Canvas canvas, Size size, double phase) {
    const _CloudySkyPainter(density: 4, opacityScale: 0.9).paint(
      canvas,
      size,
      phase,
    );
    for (int i = 0; i < 4; i++) {
      final double y = size.height * (0.22 + i * 0.14);
      final double shift = math.sin((phase + i * 0.2) * math.pi * 2.0) * 18.0;
      _drawSoftCloudBand(
        canvas,
        Offset(size.width * 0.5 + shift, y),
        size.width * 0.72,
        24,
        0.075,
      );
    }
  }
}

class _RainSkyPainter implements ISkyScenePainter {
  final bool isStorm;

  const _RainSkyPainter({required this.isStorm});

  @override
  void paint(Canvas canvas, Size size, double phase) {
    const _CloudySkyPainter(density: 4, opacityScale: 0.85).paint(
      canvas,
      size,
      phase,
    );

    final int count = isStorm ? 72 : 44;
    final double speedCycles = isStorm ? 18.0 : 12.0;
    final double driftX = isStorm ? -10.0 : -4.0;
    final rainPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = isStorm ? 1.3 : 1.0;

    for (int i = 0; i < count; i++) {
      final double seedX = (i * 0.61803) % 1.0;
      final double seedY = (i * 0.38197) % 1.0;
      final double progress = (seedY + phase * speedCycles) % 1.0;
      final double x = ((seedX * (size.width + 60)) - progress * 30) %
          (size.width + 40);
      final double y = progress * (size.height + 40) - 20;
      final double len = 11.0 + (i % 4) * 4.5;
      final double alpha = (isStorm ? 0.14 : 0.11) + (i % 3) * 0.05;
      rainPaint.color = const Color(0xFFCDE4FF).withValues(alpha: alpha);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + driftX * 0.45, y + len),
        rainPaint,
      );
    }

    if (isStorm) {
      final double pulseCycle = (phase * 6.0) % 1.0;
      if (pulseCycle > 0.90) {
        final double flashAlpha = ((1.0 - pulseCycle) / 0.10) * 0.16;
        final flashPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(0.2, -0.65),
            radius: 0.9,
            colors: [
              const Color(0xFFD7E8FF).withValues(alpha: flashAlpha),
              const Color(0xFFB4CDFF).withValues(alpha: 0.0),
            ],
          ).createShader(Offset.zero & size);
        canvas.drawRect(Offset.zero & size, flashPaint);
      }
    }
  }
}

class _NightSkyPainter implements ISkyScenePainter {
  const _NightSkyPainter();

  @override
  void paint(Canvas canvas, Size size, double phase) {
    final moonOrigin = Offset(size.width * 0.82, size.height * 0.12);
    final moonGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE1ECFF).withValues(alpha: 0.22),
          const Color(0xFF94B2EB).withValues(alpha: 0.08),
          const Color(0xFF94B2EB).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: moonOrigin, radius: 135));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.52),
      moonGlow,
    );

    for (int i = 0; i < 48; i++) {
      final double x = ((i * 0.6180339) % 1.0) * size.width;
      final double y = ((i * 0.4319) % 1.0) * size.height * 0.66;
      final double r = 0.7 + (i % 3) * 0.45;
      final double twinkle =
          0.42 + 0.58 * math.sin((phase * 12.0 + i * 0.7) * math.pi);
      final double baseAlpha = 0.22 + (i % 4) * 0.14;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color =
              const Color(0xFFF0F6FF).withValues(alpha: baseAlpha * twinkle),
      );
    }
  }
}
