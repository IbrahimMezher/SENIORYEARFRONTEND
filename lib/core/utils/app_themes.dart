import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertest/core/theme/app_theme.dart';

class AppThemes {
  // ── TEXT THEME (Inter throughout) ─────────────────────────────────────────
  static TextTheme _textTheme(Brightness brightness) {
    final ink = brightness == Brightness.light
        ? AppTheme.lightInk
        : AppTheme.darkInk;
    final muted = AppTheme.slate;
    return TextTheme(
      displayLarge:  GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.5),
      displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.3),
      displaySmall:  GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.2),
      headlineLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: ink, letterSpacing: -0.2),
      headlineMedium:GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: ink),
      headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: ink),
      titleLarge:    GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: ink),
      titleMedium:   GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: ink),
      titleSmall:    GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: ink),
      bodyLarge:     GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: ink, height: 1.5),
      bodyMedium:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: ink, height: 1.5),
      bodySmall:     GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: muted, height: 1.4),
      labelLarge:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: ink),
      labelMedium:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: muted),
      labelSmall:    GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.8),
    );
  }

  // ── LIGHT THEME ────────────────────────────────────────────────────────────
  static final light = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: AppTheme.lightBg,
    cardColor: AppTheme.lightSurface,
    textTheme: _textTheme(Brightness.light),

    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary:   AppTheme.sienna,     // Policy Green — CTAs, active indicators
      onPrimary: AppTheme.siennaFg,
      secondary: AppTheme.brand,      // Navy — secondary brand elements
      onSecondary: Colors.white,
      surface:   AppTheme.lightSurface,
      onSurface: AppTheme.lightInk,
      error:     AppTheme.danger,
      onError:   Colors.white,
      outline:   AppTheme.lightHair,
      outlineVariant: AppTheme.lightHairStrong,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppTheme.lightSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: AppTheme.lightHair,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: AppTheme.lightInk, size: 22),
      titleTextStyle: GoogleFonts.inter(
        color: AppTheme.lightInk,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: AppTheme.sienna,
      unselectedItemColor: AppTheme.slate,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),

    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppTheme.lightSurface,
      selectedIconTheme: const IconThemeData(color: AppTheme.sienna, size: 22),
      unselectedIconTheme: const IconThemeData(color: AppTheme.slate, size: 22),
      selectedLabelTextStyle: GoogleFonts.inter(
        color: AppTheme.sienna,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: GoogleFonts.inter(
        color: AppTheme.slate,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      indicatorColor: AppTheme.siennaSoft,
    ),

    cardTheme: CardThemeData(
      color: AppTheme.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: const BorderSide(color: AppTheme.lightHair, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    dividerTheme: const DividerThemeData(
      color: AppTheme.lightHair,
      thickness: 1,
      space: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppTheme.brand,
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
      elevation: 4,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppTheme.lightSurface,
      elevation: 8,
      shadowColor: const Color(0x20000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppTheme.lightHair, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppTheme.lightHair, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppTheme.brand, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppTheme.danger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppTheme.danger, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.slate),
      labelStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.slate),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppTheme.sienna : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppTheme.sienna : null),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppTheme.siennaSoft : null),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.sienna,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
        minimumSize: const Size.fromHeight(48),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.graphite,
        side: const BorderSide(color: AppTheme.mist, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
        minimumSize: const Size.fromHeight(48),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppTheme.lightSurface2,
      labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      side: const BorderSide(color: AppTheme.lightHair),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
  );

  // ── DARK THEME ─────────────────────────────────────────────────────────────
  static final dark = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppTheme.darkBg,
    cardColor: AppTheme.darkSurface,
    textTheme: _textTheme(Brightness.dark),

    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary:   AppTheme.sienna,
      onPrimary: AppTheme.siennaFg,
      secondary: AppTheme.darkBg2,
      onSecondary: Colors.white,
      surface:   AppTheme.darkSurface,
      onSurface: AppTheme.darkInk,
      error:     AppTheme.darkDanger,
      onError:   Colors.black,
      outline:   AppTheme.darkHair,
      outlineVariant: AppTheme.darkHairStrong,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppTheme.darkSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: AppTheme.darkHair,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: AppTheme.darkInk, size: 22),
      titleTextStyle: GoogleFonts.inter(
        color: AppTheme.darkInk,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: AppTheme.sienna,
      unselectedItemColor: AppTheme.darkMuted,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),

    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppTheme.darkSurface,
      selectedIconTheme: const IconThemeData(color: AppTheme.sienna, size: 22),
      unselectedIconTheme: const IconThemeData(color: AppTheme.darkMuted, size: 22),
      selectedLabelTextStyle: GoogleFonts.inter(
        color: AppTheme.sienna,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: GoogleFonts.inter(
        color: AppTheme.darkMuted,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      indicatorColor: AppTheme.darkSiennaSoft,
    ),

    cardTheme: CardThemeData(
      color: AppTheme.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: const BorderSide(color: AppTheme.darkHair, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    dividerTheme: const DividerThemeData(
      color: AppTheme.darkHair,
      thickness: 1,
      space: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppTheme.darkSurface2,
      contentTextStyle: GoogleFonts.inter(color: AppTheme.darkInk, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppTheme.darkSurface,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppTheme.darkHair, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppTheme.darkHair, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppTheme.sienna, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppTheme.darkDanger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppTheme.darkDanger, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.darkMuted),
      labelStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.darkMuted),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppTheme.sienna : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppTheme.sienna : null),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppTheme.darkSiennaSoft : null),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.sienna,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
        minimumSize: const Size.fromHeight(48),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.darkInk,
        side: const BorderSide(color: AppTheme.darkHair, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
        minimumSize: const Size.fromHeight(48),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppTheme.darkSurface2,
      labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      side: const BorderSide(color: AppTheme.darkHair),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
  );
}
