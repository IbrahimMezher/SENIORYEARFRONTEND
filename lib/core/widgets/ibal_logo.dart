import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// IBAL brand wordmark — shared across login, profile, and any other pages.
///
/// Shows assets/images/ibal_logo.png when the file is present.
/// Falls back to a layered text wordmark if the PNG is missing.
class IbalLogo extends StatelessWidget {
  final double width;
  const IbalLogo({super.key, this.width = 160});

  static const String _asset = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    return Image.asset(
      _asset,
      width: width,
      errorBuilder: (_, __, ___) => _IbalFallback(dark: dark, width: width),
    );
  }
}

/// Two-layer overlapping wordmark shown when the PNG isn't placed yet.
class _IbalFallback extends StatelessWidget {
  final bool dark;
  final double width;
  const _IbalFallback({required this.dark, required this.width});

  @override
  Widget build(BuildContext context) {
    final indigo = dark ? const Color(0xFF9B9AE0) : const Color(0xFF2D1B8B);
    final sage   = dark ? const Color(0xFFA8C496) : const Color(0xFF8FB870);
    final size   = width * 0.48; // font size scales with requested width

    TextStyle layerStyle(Color c) => GoogleFonts.cormorantGaramond(
          fontSize: size,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          height: 1.0,
          letterSpacing: -3.0,
          color: c,
        );

    return SizedBox(
      width: width,
      height: size * 1.05,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(size * 0.055, size * 0.033),
            child: Opacity(
              opacity: 0.82,
              child: Text('IBAL', style: layerStyle(sage)),
            ),
          ),
          Text('IBAL', style: layerStyle(indigo)),
        ],
      ),
    );
  }
}
