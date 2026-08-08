import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/widgets/tap_bounce.dart';

/// IBAL card — opaque surface, 1px border, tap-bounce + hover lift when tappable.
class PremiumCard extends StatefulWidget {
  final Widget child;
  final double? radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  @Deprecated('Glassmorphism removed. PremiumCard is always opaque.')
  final bool glass;
  final Color? accent;

  const PremiumCard({
    super.key,
    required this.child,
    this.radius,
    this.padding,
    this.margin,
    this.onTap,
    // ignore: deprecated_member_use_from_same_package
    this.glass = false,
    this.accent,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.radius ?? AppTheme.radiusLg;
    final tappable = widget.onTap != null;

    Widget card = MouseRegion(
      onEnter: tappable ? (_) { if (!_hovered) setState(() => _hovered = true); } : null,
      onExit:  tappable ? (_) { if (_hovered) setState(() => _hovered = false); } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: widget.padding ?? const EdgeInsets.all(AppTheme.cardPad),
        decoration: AppTheme.cardDecoration(context, r: r).copyWith(
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                        alpha: AppTheme.isDark(context) ? 0.28 : 0.10),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppTheme.cardDecoration(context, r: r).boxShadow,
        ),
        child: widget.accent != null
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: widget.accent,
                        borderRadius: BorderRadius.only(
                          topLeft:    Radius.circular(r),
                          bottomLeft: Radius.circular(r),
                        ),
                      ),
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              )
            : widget.child,
      ),
    );

    if (tappable) {
      card = TapBounce(
        onTap: widget.onTap,
        pressScale: 0.96,
        hoverScale: 1.0, // hover is handled by the shadow above
        enableHover: false,
        child: card,
      );
    }

    return widget.margin != null
        ? Padding(padding: widget.margin!, child: card)
        : card;
  }
}
