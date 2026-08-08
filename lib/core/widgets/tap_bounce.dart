import 'package:flutter/material.dart';

/// Wraps any widget with:
/// - Press: scales down to [pressScale] (default 0.95) with spring-back
/// - Hover (desktop/web): scales up to [hoverScale] (default 1.03)
///
/// Does NOT provide tap routing — pass [onTap] for that.
class TapBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;
  final double hoverScale;
  final bool enableHover;

  const TapBounce({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.95,
    this.hoverScale = 1.03,
    this.enableHover = true,
  });

  @override
  State<TapBounce> createState() => _TapBounceState();
}

class _TapBounceState extends State<TapBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _spring;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    // Spring back: press → release bounces slightly past 1.0 then settles
    _spring = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: widget.pressScale)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.pressScale, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward(from: 0);
  void _onTapUp(TapUpDetails _) {
    _ctrl.forward();
    widget.onTap?.call();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.enableHover
          ? (_) {
              if (!_hovered) setState(() => _hovered = true);
            }
          : null,
      onExit: widget.enableHover
          ? (_) {
              if (_hovered) setState(() => _hovered = false);
            }
          : null,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _spring,
          builder: (_, child) => Transform.scale(
            scale: _hovered && !_ctrl.isAnimating
                ? widget.hoverScale
                : _spring.value,
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
