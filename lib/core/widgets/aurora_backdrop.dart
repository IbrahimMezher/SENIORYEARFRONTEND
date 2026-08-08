import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';

/// IbAl page background — clean, opaque, no animated orbs.
///
/// Replaces the old glassmorphism AuroraBackdrop.
/// Renders the correct theme background and wraps [child].
/// [orbAlignment] and [secondaryOrbAlignment] are accepted but ignored,
/// keeping all existing call sites compiling without modification.
class AuroraBackdrop extends StatelessWidget {
  final Widget child;
  // Legacy params — kept for call-site compat, not used.
  final Alignment orbAlignment;
  final Alignment secondaryOrbAlignment;

  const AuroraBackdrop({
    super.key,
    required this.child,
    this.orbAlignment          = const Alignment(0.75, -0.55),
    this.secondaryOrbAlignment = const Alignment(-0.80, 0.75),
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.bg(context),
      child: child,
    );
  }
}
