import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';

/// IBAL button system — pill shape, spring press, hover glow.
enum AppButtonVariant { primary, secondary, destructive, ghost }

class SiennaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Future<void> Function()? onTapAsync;
  final bool loading;
  final double height;
  final double? width;
  final IconData? icon;
  final bool ghost;
  final AppButtonVariant variant;

  const SiennaButton({
    super.key,
    required this.label,
    this.onTap,
    this.onTapAsync,
    this.loading = false,
    this.height = 54,
    this.width,
    this.icon,
    this.ghost = false,
    this.variant = AppButtonVariant.primary,
  });

  @override
  State<SiennaButton> createState() => _SiennaButtonState();
}

class _SiennaButtonState extends State<SiennaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _busy = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    // Press → spring back past 1.0
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.93)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.93, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleAsync() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onTapAsync!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward(from: 0);
  void _onTapUp(TapUpDetails _) {
    _ctrl.forward();
    if (widget.onTapAsync != null) {
      _handleAsync();
    } else {
      widget.onTap?.call();
    }
  }

  void _onTapCancel() => _ctrl.reverse();

  AppButtonVariant get _effectiveVariant =>
      widget.ghost ? AppButtonVariant.ghost : widget.variant;

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.loading || _busy;
    final hasAction = widget.onTap != null || widget.onTapAsync != null;
    final disabled = !hasAction || isLoading;
    final dark = AppTheme.isDark(context);
    final variant = _effectiveVariant;

    Color bgColor;
    Color fgColor;
    Border? border;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = disabled
            ? (dark ? AppTheme.darkHair : AppTheme.mist)
            : _hovered
                ? AppTheme.sienna.withValues(alpha: 0.88)
                : AppTheme.sienna;
        fgColor = disabled ? AppTheme.slate : Colors.white;
        border = null;
      case AppButtonVariant.secondary:
        bgColor = _hovered
            ? (dark ? AppTheme.darkSurface2 : AppTheme.lightSurface2)
            : (dark ? AppTheme.darkSurface : AppTheme.lightSurface);
        fgColor = dark ? AppTheme.darkInk : AppTheme.graphite;
        border = Border.all(
          color: dark ? AppTheme.darkHair : AppTheme.mist,
          width: 1,
        );
      case AppButtonVariant.destructive:
        bgColor = disabled
            ? (dark ? AppTheme.darkHair : AppTheme.mist)
            : _hovered
                ? AppTheme.danger.withValues(alpha: 0.85)
                : AppTheme.danger;
        fgColor = disabled ? AppTheme.slate : Colors.white;
        border = null;
      case AppButtonVariant.ghost:
        bgColor = _hovered
            ? AppTheme.sienna.withValues(alpha: 0.08)
            : Colors.transparent;
        fgColor = disabled ? AppTheme.slate : AppTheme.sienna;
        border = null;
    }

    // Hover glow — only for primary/destructive
    final List<BoxShadow> shadow = (!disabled &&
            _hovered &&
            (variant == AppButtonVariant.primary ||
                variant == AppButtonVariant.destructive))
        ? [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.45),
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ]
        : [];

    return MouseRegion(
      onEnter: disabled
          ? null
          : (_) {
              if (!_hovered) setState(() => _hovered = true);
            },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: GestureDetector(
        onTapDown: disabled ? null : _onTapDown,
        onTapUp: disabled ? null : _onTapUp,
        onTapCancel: disabled ? null : _onTapCancel,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) => Transform.scale(
            scale: _scale.value,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: widget.height,
            width: widget.width ?? double.infinity,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(28),
              border: border,
              boxShadow: shadow,
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: fgColor),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 17, color: fgColor),
                          const SizedBox(width: 8),
                        ],
                        Text(widget.label,
                            style: AppTextStyle.button(color: fgColor)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// Backward-compat alias
typedef GradientButton = SiennaButton;
