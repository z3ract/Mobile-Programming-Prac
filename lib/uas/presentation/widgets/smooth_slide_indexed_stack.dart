import 'package:flutter/material.dart';

/// Indexed stack that glides outgoing and incoming tabs horizontally with an
/// ease-in-ease-out curve while preserving every tab's state and scroll offset.
class SmoothSlideIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const SmoothSlideIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 320),
  });

  @override
  State<SmoothSlideIndexedStack> createState() =>
      _SmoothSlideIndexedStackState();
}

class _SmoothSlideIndexedStackState extends State<SmoothSlideIndexedStack>
    with SingleTickerProviderStateMixin {
  static const Animation<Offset> _zeroOffsetAnimation =
      AlwaysStoppedAnimation<Offset>(Offset.zero);

  late final AnimationController _controller;
  late final CurvedAnimation _curvedAnimation;
  Animation<Offset> _slideInAnimation = _zeroOffsetAnimation;
  Animation<Offset> _slideOutAnimation = _zeroOffsetAnimation;
  int? _previousIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.addStatusListener(_handleAnimationStatus);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _previousIndex != null) {
      setState(() {
        _previousIndex = null;
        _slideInAnimation = _zeroOffsetAnimation;
        _slideOutAnimation = _zeroOffsetAnimation;
      });
    }
  }

  @override
  void didUpdateWidget(covariant SmoothSlideIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.index != widget.index) {
      final bool disableAnimations =
          (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
          widget.duration == Duration.zero;
      if (disableAnimations) {
        _previousIndex = null;
        _slideInAnimation = _zeroOffsetAnimation;
        _slideOutAnimation = _zeroOffsetAnimation;
        _controller.value = 1.0;
      } else {
        final double direction = widget.index > oldWidget.index ? 1.0 : -1.0;
        _previousIndex = oldWidget.index;
        _slideInAnimation = _curvedAnimation.drive(
          Tween<Offset>(begin: Offset(direction, 0.0), end: Offset.zero),
        );
        _slideOutAnimation = _curvedAnimation.drive(
          Tween<Offset>(begin: Offset.zero, end: Offset(-direction, 0.0)),
        );
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatus);
    _curvedAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int? prev = (_previousIndex != null &&
            _previousIndex! >= 0 &&
            _previousIndex! < widget.children.length &&
            _previousIndex != widget.index &&
            _controller.isAnimating)
        ? _previousIndex
        : null;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: List<Widget>.generate(widget.children.length, (i) {
          final bool isCurrent = i == widget.index;
          final bool isPrevious = i == prev;
          final bool isVisible = isCurrent || isPrevious;

          final Animation<Offset> position = isCurrent
              ? (prev == null ? _zeroOffsetAnimation : _slideInAnimation)
              : (isPrevious ? _slideOutAnimation : _zeroOffsetAnimation);

          return Offstage(
            offstage: !isVisible,
            child: TickerMode(
              enabled: isVisible,
              child: IgnorePointer(
                ignoring: !isCurrent,
                child: ExcludeSemantics(
                  excluding: !isCurrent,
                  child: SlideTransition(
                    position: position,
                    child: widget.children[i],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
