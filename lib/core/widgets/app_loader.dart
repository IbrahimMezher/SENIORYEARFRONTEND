import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';

/// Branded loading indicator — always uses the app's green accent color.
///
/// Use [AppLoader.page] for full-screen loading states.
/// Use [AppLoader.inline] for small loaders inside buttons / list rows.
class AppLoader extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const AppLoader({
    super.key,
    this.size = 44,
    this.strokeWidth = 3.0,
    this.color,
  });

  /// Tiny 18 × 18 variant for inside buttons or list items.
  const AppLoader.inline({
    super.key,
    this.size = 18,
    this.strokeWidth = 2.0,
    this.color,
  });

  /// Full-page centered loading state.
  static Widget page({Color? bg}) {
    return Builder(
      builder: (context) => Scaffold(
        backgroundColor: bg ?? AppTheme.bg(context),
        body: const Center(child: AppLoader()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? AppTheme.sienna,
        strokeCap: StrokeCap.round,
      ),
    );
  }
}
