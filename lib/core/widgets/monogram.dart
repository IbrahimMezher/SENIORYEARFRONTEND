import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';

/// Avatar monogram — circular, cyan-ring accent, initials or icon fallback.
class Monogram extends StatelessWidget {
  final String name;
  final double size;
  final double fontSize;
  /// When true, draws a cyan glow ring (use for prominent profile positions).
  final bool glow;

  const Monogram({
    super.key,
    required this.name,
    this.size = 40,
    this.fontSize = 16,
    this.glow = false,
  });

  String _initials() {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dark    = AppTheme.isDark(context);
    final initials = _initials();
    final hasName = name.trim().isNotEmpty;

    return Semantics(
      label: name,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppTheme.sienna.withValues(alpha: dark ? 0.28 : 0.18),
              AppTheme.siennaTeal.withValues(alpha: dark ? 0.20 : 0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: glow
                ? AppTheme.sienna.withValues(alpha: 0.55)
                : AppTheme.sienna.withValues(alpha: dark ? 0.25 : 0.18),
            width: glow ? 1.5 : 1.0,
          ),
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: AppTheme.sienna.withValues(alpha: 0.28),
                    blurRadius: 14,
                    spreadRadius: -2,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: hasName
              ? Text(
                  initials,
                  style: AppTextStyle.mono(
                    size: fontSize,
                    weight: FontWeight.w700,
                    color: AppTheme.sienna,
                  ),
                )
              : Icon(
                  Icons.person_outline_rounded,
                  size: (fontSize * 1.25).clamp(16.0, size * 0.5),
                  color: AppTheme.sienna,
                ),
        ),
      ),
    );
  }
}
