import 'package:flutter/material.dart';

/// Pure directional horizontal slide transition with an ease-in-ease-out curve
/// and zero opacity dimming for pushed Material routes.
class SmoothSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothSlidePageTransitionsBuilder();

  static final Animatable<Offset> _primarySlideTween = Tween<Offset>(
    begin: const Offset(1.0, 0.0),
    end: Offset.zero,
  ).chain(CurveTween(curve: Curves.easeInOutCubic));

  static final Animatable<Offset> _secondarySlideTween = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-0.28, 0.0),
  ).chain(CurveTween(curve: Curves.easeInOutCubic));

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: animation.drive(_primarySlideTween),
      child: SlideTransition(
        position: secondaryAnimation.drive(_secondarySlideTween),
        child: child,
      ),
    );
  }
}
