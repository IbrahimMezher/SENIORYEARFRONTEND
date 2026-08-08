import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// IbAl typography system.
///
/// Primary: Inter (enterprise SaaS standard — weight-based hierarchy)
/// Numerical: JetBrains Mono (tabular figures for financial data)
/// Arabic fallback: Noto Kufi Arabic / Noto Naskh Arabic
class AppTextStyle {
  AppTextStyle._();

  static bool get _isArabic => Get.locale?.languageCode == 'ar';

  // ── INTERNAL FONT BUILDERS ─────────────────────────────────────────────────

  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    double? letterSpacing,
    double? height,
    Color? color,
  }) {
    if (_isArabic) {
      return GoogleFonts.notoKufiArabic(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 0,
        height: height,
        color: color,
      );
    }
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing ?? 0,
      height: height,
      color: color,
    );
  }

  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) {
    if (_isArabic) {
      return GoogleFonts.notoNaskhArabic(
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
    }
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // ── TYPE SCALE ─────────────────────────────────────────────────────────────

  /// Display — hero numbers, splash (36sp/700)
  static TextStyle display({Color? color}) => _inter(
        size: 36, weight: FontWeight.w700,
        letterSpacing: -0.5, height: 1.05, color: color);

  /// H1 — page titles (24sp/600)
  static TextStyle h1({Color? color}) => _inter(
        size: 24, weight: FontWeight.w600,
        letterSpacing: -0.2, height: 1.2, color: color);

  /// H2 — section headings (18sp/600)
  static TextStyle h2({Color? color}) => _inter(
        size: 18, weight: FontWeight.w600,
        letterSpacing: -0.1, height: 1.3, color: color);

  /// H3 — card headings, sub-sections (15sp/600)
  static TextStyle h3({Color? color}) => _inter(
        size: 15, weight: FontWeight.w600,
        height: 1.4, color: color);

  /// Body — default body text (14sp/400)
  static TextStyle bodyLarge({Color? color}) => _inter(
        size: 16, weight: FontWeight.w400, height: 1.5, color: color);

  /// Body medium — standard body (14sp/400)
  static TextStyle bodyMedium({Color? color}) => _inter(
        size: 14, weight: FontWeight.w400, height: 1.5, color: color);

  /// Body emphasis — labels, nav items (14sp/500)
  static TextStyle bodyEmphasis({Color? color}) => _inter(
        size: 14, weight: FontWeight.w500, height: 1.5, color: color);

  /// Body small — metadata, secondary text (12sp/400)
  static TextStyle bodySmall({Color? color}) => _inter(
        size: 12, weight: FontWeight.w400, height: 1.4, color: color);

  /// Caption — timestamps, footnotes (12sp/400)
  static TextStyle caption({Color? color}) => _inter(
        size: 12, weight: FontWeight.w400, height: 1.4, color: color);

  /// Overline — category labels, section markers (11sp/500, tracked)
  static TextStyle eyebrow({Color? color}) => _inter(
        size: 11, weight: FontWeight.w500,
        letterSpacing: 0.8, height: 1.2, color: color);

  /// Button label (14sp/600)
  static TextStyle button({Color? color}) => _inter(
        size: 14, weight: FontWeight.w600,
        letterSpacing: 0, color: color);

  /// Mono Display — hero financial figures (large, 28–40sp)
  static TextStyle monoDisplay({double size = 32, Color? color}) => mono(
        size: size, weight: FontWeight.w700, color: color);

  // ── LEGACY ALIASES (keep callers compiling) ────────────────────────────────
  static TextStyle get heading    => h2();
  static TextStyle get subheading => _inter(size: 14, weight: FontWeight.w600);
  static TextStyle get body       => bodyMedium();
  static TextStyle get label      => eyebrow();

  // Alias for old code using AppTextStyle.caption as a getter (not method)
  static TextStyle captionStyle({Color? color}) => caption(color: color);
}
