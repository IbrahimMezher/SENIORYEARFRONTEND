import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/widgets/ibal_icon.dart';

/// Shared floating nav bar for Customer (light surface) and Broker (dark surface).
///
/// [darkSurface] = true → Broker-style navy-deep background.
/// [centerIndex] = non-null → that slot becomes an elevated circle FAB button.
class IbalNavBar extends StatelessWidget {
  final List<IbalNavDest> destinations;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool darkSurface;
  final int? centerIndex;

  const IbalNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onTap,
    this.darkSurface = false,
    this.centerIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final Color barBg = darkSurface
        ? AppTheme.brand
        : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface);

    final bar = Container(
      height: 52,
      decoration: BoxDecoration(
        color: barBg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: darkSurface ? 0.40 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: darkSurface ? 0.18 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: List.generate(destinations.length, (i) {
          // Leave empty slot for elevated center button
          if (i == centerIndex) return const Expanded(child: SizedBox());

          return Expanded(
            child: _IbalNavItem(
              dest: destinations[i],
              isSelected: selectedIndex == i,
              darkSurface: darkSurface,
              onTap: () => onTap(i),
            ),
          );
        }),
      ),
    );

    // Cap safe-area contribution so the pill never floats too high.
    final safeBottom =
        MediaQuery.viewPaddingOf(context).bottom.clamp(0.0, 20.0);

    // No elevated center — simple pill bar
    if (centerIndex == null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 4 + safeBottom),
        child: bar,
      );
    }

    // With elevated center circle
    final centerDest = destinations[centerIndex!];
    final isCenterSel = selectedIndex == centerIndex;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 4 + safeBottom),
      child: SizedBox(
        height: 66,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(bottom: 0, left: 0, right: 0, child: bar),
            Positioned(
              bottom: 18,
                child: GestureDetector(
                  onTap: () => onTap(centerIndex!),
                  child: _CenterButton(
                    dest: centerDest,
                    isSelected: isCenterSel,
                    darkSurface: darkSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class IbalNavDest {
  final IbalIconType icon;
  final String label;
  const IbalNavDest({required this.icon, required this.label});
}

// ── Elevated center FAB-style button ─────────────────────────────────────────

class _CenterButton extends StatefulWidget {
  final IbalNavDest dest;
  final bool isSelected;
  final bool darkSurface;
  const _CenterButton({
    required this.dest,
    required this.isSelected,
    required this.darkSurface,
  });
  @override
  State<_CenterButton> createState() => _CenterButtonState();
}

class _CenterButtonState extends State<_CenterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _bounce = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.16)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.16, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(_CenterButton old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.isSelected;
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) =>
          Transform.scale(scale: sel ? _bounce.value : 1.0, child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: sel
              ? (widget.darkSurface ? AppTheme.sienna : AppTheme.brand)
              : (widget.darkSurface
                  ? const Color(0xFF243450)
                  : const Color(0xFFEDEADE)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.sienna.withValues(alpha: sel ? 0.45 : 0.12),
              blurRadius: 18,
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: IbalIcon(
            widget.dest.icon,
            size: 24,
            filled: true,
            baseColor: sel
                ? Colors.white
                : (widget.darkSurface
                    ? const Color(0xFFCBD5E1)
                    : AppTheme.brand),
            accentColor: sel
                ? Colors.white.withValues(alpha: 0.75)
                : AppTheme.sienna,
          ),
        ),
      ),
    );
  }
}

// ── Single nav item (icon only, no label) ────────────────────────────────────

class _IbalNavItem extends StatefulWidget {
  final IbalNavDest dest;
  final bool isSelected;
  final bool darkSurface;
  final VoidCallback onTap;

  const _IbalNavItem({
    required this.dest,
    required this.isSelected,
    required this.darkSurface,
    required this.onTap,
  });

  @override
  State<_IbalNavItem> createState() => _IbalNavItemState();
}

class _IbalNavItemState extends State<_IbalNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounce;
  bool _prevSelected = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounce = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.14)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.14, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60),
    ]).animate(_controller);
    _prevSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(_IbalNavItem old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !_prevSelected) {
      _controller.forward(from: 0);
    }
    _prevSelected = widget.isSelected;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final sel = widget.isSelected;

    final Color inactiveColor = widget.darkSurface
        ? Colors.white.withValues(alpha: 0.40)
        : (isDark ? AppTheme.darkMuted : AppTheme.slate);

    final Color pillColor = widget.darkSurface
        ? AppTheme.sienna.withValues(alpha: 0.22)
        : (isDark ? AppTheme.darkSiennaSoft : const Color(0xFFDCEBE3));

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedBuilder(
          animation: _bounce,
          builder: (_, child) => Transform.scale(
            scale: sel ? _bounce.value : 1.0,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: sel ? 44 : 36,
            height: 36,
            decoration: BoxDecoration(
              color: sel ? pillColor : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: IbalIcon(
                widget.dest.icon,
                size: 22,
                filled: sel,
                baseColor: sel
                    ? (widget.darkSurface
                        ? const Color(0xFFCBD5E1)
                        : AppTheme.brand)
                    : inactiveColor,
                accentColor: sel
                    ? (isDark ? AppTheme.greenDarkAccent : AppTheme.sienna)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
