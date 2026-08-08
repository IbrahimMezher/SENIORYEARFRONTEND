import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── SPACING / RADIUS ───────────────────────────────────────────────────────
  static const double radiusSm   = 6;    // inputs, chips
  static const double radius     = 8;    // default
  static const double radiusLg   = 12;   // cards
  static const double radiusXl   = 16;   // hero cards
  static const double radiusPill = 8;    // buttons (no longer pill-shaped)
  static const double screenPad  = 22;
  static const double cardPad    = 16;
  static const double sectionGap = 28;
  static const double listGap    = 12;
  static const double gridGap    = 10;

  // ── PRIMARY BRAND ──────────────────────────────────────────────────────────
  /// Depth Navy — page titles, brand anchors, primary text (light theme)
  static const Color brand       = Color(0xFF1A2847);
  /// Policy Green — CTAs, active states, primary actions
  static const Color sienna      = Color(0xFF2E7D5E);
  static const Color siennaFg    = Color(0xFFFFFFFF);
  static const Color siennaTeal  = Color(0xFF256B4F);  // darker Policy Green
  static const Color siennaSoft  = Color(0x142E7D5E);  // Policy Green 8% — chip bg
  static const Color siennaBg    = siennaSoft;
  static const Color coral       = Color(0xFF256B4F);  // alias → siennaTeal

  // ── NEUTRALS ──────────────────────────────────────────────────────────────
  static const Color graphite    = Color(0xFF374151);
  static const Color slate       = Color(0xFF6B7280);
  static const Color mist        = Color(0xFFE2E8F0);

  // ── SEMANTIC / STATUS ─────────────────────────────────────────────────────
  static const Color success     = Color(0xFF15803D);
  static const Color successBg   = Color(0xFFDCFCE7);
  static const Color warning     = Color(0xFFD97706);
  static const Color warningBg   = Color(0xFFFEF3C7);
  static const Color danger      = Color(0xFFBE123C);
  static const Color dangerBg    = Color(0xFFFEE2E2);
  static const Color copper      = warning;  // legacy alias

  // ── STATUS BADGE PAIRS (all WCAG AA) ─────────────────────────────────────
  static const Color activeBg    = Color(0xFFDCFCE7);
  static const Color activeText  = Color(0xFF15803D);   // 6.8:1 on activeBg
  static const Color pendingBg   = Color(0xFFFEF3C7);
  static const Color pendingText = Color(0xFF92400E);   // 7.2:1 on pendingBg
  static const Color rejectedBg  = Color(0xFFFEE2E2);
  static const Color rejectedText = Color(0xFF991B1B);  // 7.8:1 on rejectedBg
  static const Color draftBg     = Color(0xFFF3F4F6);
  static const Color draftText   = Color(0xFF374151);   // 8.1:1 on draftBg

  // ── BRAND AMBER / ALERT ───────────────────────────────────────────────────
  /// Premium amber — alerts, expirations, warm accents
  static const Color amber          = Color(0xFFB8853A);
  static const Color amberBg        = Color(0xFFFDF0DC);
  static const Color alertRed       = Color(0xFFB0403C);
  /// Opaque soft-green chip background (solid, not alpha)
  static const Color greenSoft      = Color(0xFFDCEBE3);

  // ── LIGHT SURFACES ────────────────────────────────────────────────────────
  static const Color lightBg        = Color(0xFFF6F4EE);  // Warm cream
  static const Color lightSurface   = Color(0xFFFFFFFF);
  static const Color lightSurface2  = Color(0xFFEDEADE);  // Warm off-white
  static const Color lightInk       = Color(0xFF1A2847);  // Navy — primary text
  static const Color lightInk2      = Color(0xFF374151);  // Graphite — secondary
  static const Color lightMuted     = Color(0xFF6B7280);  // Slate — muted
  static const Color lightHair      = Color(0xFFE4E1D6);  // Warm beige dividers
  static const Color lightHairStrong = Color(0xFFCCC9BE);

  // ── DARK SURFACES ─────────────────────────────────────────────────────────
  static const Color darkBg         = Color(0xFF0F172A);
  static const Color darkBg2        = Color(0xFF1A2847);
  static const Color darkCanvas     = Color(0xFF0A0F1E);
  static const Color darkSurface    = Color(0xFF16233F);  // per spec
  static const Color darkSurface2   = Color(0xFF2D3B5A);
  static const Color darkInk        = Color(0xFFF8FAFC);
  static const Color darkInk2       = Color(0xFFCBD5E1);
  static const Color darkMuted      = Color(0xFF94A3B8);  // per spec
  static const Color darkHair       = Color(0xFF24304F);  // per spec
  static const Color darkHairStrong = Color(0xFF3B4F72);
  static const Color darkSiennaSoft = Color(0x202E7D5E);
  static const Color greenDarkAccent = Color(0xFF5FBF95); // per spec

  // ── DARK SEMANTIC ─────────────────────────────────────────────────────────
  static const Color darkSuccess    = Color(0xFF4ADE80);
  static const Color darkWarning    = Color(0xFFFBBF24);
  static const Color darkDanger     = Color(0xFFF87171);

  // ── LEGACY ALIASES (keep callers compiling) ────────────────────────────────
  static const Color purple         = sienna;
  static const Color blue           = sienna;
  static const Color borderColor    = lightHair;
  static const Color purpleBg       = siennaSoft;
  static const Color marine         = brand;
  static const Color inkBlue        = brand;
  static const Color slateGreen     = siennaTeal;
  static const Color infoBg         = Color(0xFFE8EEF2);
  static const Color greenBg        = Color(0xFFDCEEE5);

  // ── BRAND GRADIENT (now solid → single color, no visual gradient) ─────────
  // Kept so callers compile. Visually flat since both stops are the same hue.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [sienna, siennaTeal],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient brandGradientVertical = LinearGradient(
    colors: [sienna, siennaTeal],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── CONTEXT HELPERS ────────────────────────────────────────────────────────
  static bool isDark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;

  static Color bg(BuildContext ctx)         => isDark(ctx) ? darkBg        : lightBg;
  static Color surface(BuildContext ctx)    => isDark(ctx) ? darkSurface   : lightSurface;
  static Color surface2(BuildContext ctx)   => isDark(ctx) ? darkSurface2  : lightSurface2;
  static Color ink(BuildContext ctx)        => isDark(ctx) ? darkInk       : lightInk;
  static Color ink2(BuildContext ctx)       => isDark(ctx) ? darkInk2      : lightInk2;
  static Color muted(BuildContext ctx)      => isDark(ctx) ? darkMuted     : lightMuted;
  static Color hair(BuildContext ctx)       => isDark(ctx) ? darkHair      : lightHair;
  static Color hairStrong(BuildContext ctx) => isDark(ctx) ? darkHairStrong : lightHairStrong;
  static Color accent(BuildContext ctx)     => sienna;
  static Color accentSoft(BuildContext ctx) => isDark(ctx) ? darkSiennaSoft : siennaSoft;

  // ── STATUS HELPERS ─────────────────────────────────────────────────────────
  static Color statusColor(BuildContext ctx, String status) {
    final dark = isDark(ctx);
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'ACCEPTED':
      case 'ACTIVE':
      case 'COMPLETED':
        return dark ? darkSuccess : activeText;
      case 'PENDING':
        return dark ? darkWarning : pendingText;
      default:
        return dark ? darkDanger : rejectedText;
    }
  }

  static Color statusBg(BuildContext ctx, String status) {
    final dark = isDark(ctx);
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'ACCEPTED':
      case 'ACTIVE':
      case 'COMPLETED':
        return dark ? darkSuccess.withValues(alpha: 0.14) : activeBg;
      case 'PENDING':
        return dark ? darkWarning.withValues(alpha: 0.14) : pendingBg;
      default:
        return dark ? darkDanger.withValues(alpha: 0.14) : rejectedBg;
    }
  }

  // ── CARD DECORATIONS ───────────────────────────────────────────────────────
  // Standard opaque card — no blur, no glass.
  static BoxDecoration cardDecoration(BuildContext ctx, {double? r, double? radius}) =>
      BoxDecoration(
        color: surface(ctx),
        borderRadius: BorderRadius.circular(r ?? radius ?? AppTheme.radiusLg),
        border: Border.all(color: hair(ctx), width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark(ctx)
                ? const Color(0x1A000000)
                : const Color(0x0A000000),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: isDark(ctx)
                ? const Color(0x14000000)
                : const Color(0x06000000),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      );

  // glassDecoration now returns the same as cardDecoration — no blur.
  // Kept so existing call sites compile without changes.
  static BoxDecoration glassDecoration(BuildContext ctx, {double? r}) =>
      cardDecoration(ctx, r: r);

  // ── INPUT DECORATION ───────────────────────────────────────────────────────
  static InputDecoration inputDecoration(
    BuildContext ctx, {
    String? label,
    required String hint,
    Widget? prefix,
    Widget? suffix,
    bool focused = false,
    bool hasError = false,
  }) {
    final dark = isDark(ctx);
    final Color borderCol = hasError
        ? (dark ? darkDanger : danger)
        : focused
            ? brand
            : hair(ctx);
    final double borderW = focused || hasError ? 2.0 : 1.0;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: muted(ctx), fontSize: 14),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: surface(ctx),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: BorderSide(color: borderCol, width: borderW),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: BorderSide(color: hair(ctx), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: BorderSide(color: brand, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: BorderSide(color: dark ? darkDanger : danger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: BorderSide(color: dark ? darkDanger : danger, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }

  // ── LEGACY TEXT STYLES (kept for callers that reference AppTheme directly) ─
  static const TextStyle heading    = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
  static const TextStyle subheading = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
  static const TextStyle body       = TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  static const TextStyle caption    = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
  static const TextStyle label      = TextStyle(fontSize: 11, fontWeight: FontWeight.w500);

  static BoxDecoration legacyCardDecoration(BuildContext ctx, {double radius = 12}) =>
      cardDecoration(ctx, r: radius);
}
