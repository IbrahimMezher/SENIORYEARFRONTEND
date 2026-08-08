import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/widgets/monogram.dart';

/// Circular role illustration avatar with a green ring and optional glow.
/// Falls back to [Monogram] if the image cannot be loaded.
class RoleAvatar extends StatelessWidget {
  final String imagePath;
  final String fallback;
  final double size;
  final bool glow;

  const RoleAvatar({
    super.key,
    required this.imagePath,
    required this.fallback,
    this.size = 76,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.sienna.withValues(alpha: 0.55),
          width: 2.5,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppTheme.sienna.withValues(alpha: 0.38),
                  blurRadius: 22,
                  spreadRadius: -2,
                ),
              ]
            : [],
      ),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Monogram(
            name: fallback,
            size: size - 5,
            fontSize: (size * 0.32).roundToDouble(),
          ),
        ),
      ),
    );
  }
}
