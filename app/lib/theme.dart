import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MindPalColors {
  // ── Light mode ──────────────────────────────────────────────
  static const sand50 = Color(0xFFF8F6F2);
  static const sand100 = Color(0xFFF2EDE6);
  static const sand200 = Color(0xFFE7DDD1);
  static const clay100 = Color(0xFFE7DDD1);
  static const clay200 = Color(0xFFD6C4AF);
  static const clay300 = Color(0xFFBEA489);
  static const clay400 = Color(0xFFA98765);
  static const sage100 = Color(0xFFE2E6DF);
  static const ink700 = Color(0xFF5A5148);
  static const ink800 = Color(0xFF3F372F);
  static const ink900 = Color(0xFF261F19);
  static const inkDeep = Color(0xFF1F1813);
  static const navBg = Color(0xFFF3EFE9);

  static const surface = Color(0xFFFBF9F5);
  static const surfaceLow = Color(0xFFF5F3EF);
  static const surfaceHigh = Color(0xFFE4E2DE);

  static const recommendationGradientStart = Color(0xFFFFFCF6);
  static const recommendationGradientEnd = Color(0xFFF0E8DD);
  static const timerCardBg = Color(0xFFF5EFE4);

  // ── Dark mode — warm espresso palette ───────────────────────
  // Backgrounds (warm dark browns, never cold gray)
  static const darkBg = Color(0xFF1C1714); // deepest — scaffold
  static const darkSurface = Color(0xFF231E1A); // cards, drawer
  static const darkSurfaceMid = Color(0xFF2C2520); // elevated cards
  static const darkSurfaceHigh = Color(0xFF362E28); // pressed / hover
  static const darkNavBg = Color(0xFF1F1B18); // bottom nav

  // Borders in dark mode
  static const darkBorder = Color(0xFF3D3329); // clay-ish border
  static const darkBorderSub = Color(0xFF302820); // subtle dividers

  // Text in dark mode (warm whites, never pure white)
  static const darkTextPrimary = Color(0xFFEDE8E1); // headings
  static const darkTextSecondary = Color(0xFFB8AFA6); // body
  static const darkTextTertiary = Color(0xFF7A7068); // timestamps, hints

  // Accent stays warm clay (same as light, slightly brighter)
  static const darkAccent = Color(0xFFC9A882); // clay300 brightened for dark bg

  // ── Emotion colors (shared) ──────────────────────────────────
  static const emotionJoy = Color(0xFFE2CAB0);
  static const emotionExcitement = Color(0xFFC9958A);
  static const emotionGratitude = Color(0xFFC89A77);
  static const emotionCalm = Color(0xFFB79282);
  static const emotionNeutral = Color(0xFFD8BEA4);
  static const emotionAnxiety = Color(0xFFD6A88C);
  static const emotionSadness = Color(0xFFAD8A7A);
  static const emotionFrustration = Color(0xFFBD8777);
  static const emotionAnger = Color(0xFFBF8476);

  static Color emotionColor(String label) {
    switch (label.trim().toLowerCase()) {
      case 'joy':
        return emotionJoy;
      case 'excitement':
        return emotionExcitement;
      case 'gratitude':
        return emotionGratitude;
      case 'calm':
        return emotionCalm;
      case 'anxiety':
        return emotionAnxiety;
      case 'sadness':
        return emotionSadness;
      case 'frustration':
        return emotionFrustration;
      case 'anger':
        return emotionAnger;
      default:
        return emotionNeutral;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// LIGHT THEME
// ─────────────────────────────────────────────────────────────
ThemeData get mindpalTheme {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MindPalColors.clay300,
      primary: MindPalColors.ink900,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: MindPalColors.surface,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
  );

  return base.copyWith(
    textTheme: _lightTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: MindPalColors.surface.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.newsreader(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: MindPalColors.ink900,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: MindPalColors.clay200.withValues(alpha: 0.7)),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: MindPalColors.navBg,
      selectedItemColor: MindPalColors.ink900,
      unselectedItemColor: MindPalColors.ink700,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: _inputTheme(
      fill: MindPalColors.sand50,
      border: MindPalColors.clay300,
      hint: MindPalColors.ink700,
    ),
    dividerColor: MindPalColors.clay200.withValues(alpha: 0.6),
    dividerTheme: DividerThemeData(
      color: MindPalColors.clay200.withValues(alpha: 0.6),
      thickness: 1,
      space: 1,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return MindPalColors.ink900;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: MindPalColors.clay300, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// DARK THEME — warm espresso, not cold gray
// ─────────────────────────────────────────────────────────────
ThemeData get mindpalDarkTheme {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: MindPalColors.clay300,
      brightness: Brightness.dark,
      primary: MindPalColors.darkTextPrimary,
      onPrimary: MindPalColors.darkSurface,
      surface: MindPalColors.darkSurface,
    ),
    scaffoldBackgroundColor: MindPalColors.darkBg,
    textTheme: _darkTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: MindPalColors.darkBg.withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      titleTextStyle: GoogleFonts.newsreader(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: MindPalColors.darkTextPrimary,
      ),
      iconTheme: const IconThemeData(color: MindPalColors.darkTextSecondary),
    ),
    cardTheme: CardThemeData(
      color: MindPalColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: MindPalColors.darkBorder.withValues(alpha: 0.8),
        ),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: MindPalColors.darkNavBg,
      selectedItemColor: MindPalColors.darkTextPrimary,
      unselectedItemColor: MindPalColors.darkTextTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: _inputTheme(
      fill: MindPalColors.darkSurfaceMid,
      border: MindPalColors.darkBorder,
      hint: MindPalColors.darkTextTertiary,
    ),
    dividerColor: MindPalColors.darkBorderSub,
    dividerTheme: const DividerThemeData(
      color: MindPalColors.darkBorderSub,
      thickness: 1,
      space: 1,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: MindPalColors.darkSurface,
      surfaceTintColor: Colors.transparent,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return MindPalColors.darkAccent;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(MindPalColors.darkBg),
      side: BorderSide(color: MindPalColors.darkBorder, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    // Surfaces used by Material widgets (BottomSheet, Dialog, etc.)
    dialogTheme: const DialogThemeData(
      backgroundColor: MindPalColors.darkSurfaceMid,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: MindPalColors.darkSurfaceMid,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────
TextTheme get _lightTextTheme => TextTheme(
  headlineLarge: GoogleFonts.newsreader(
    fontSize: 44,
    height: 1.05,
    fontWeight: FontWeight.w500,
    color: MindPalColors.ink900,
  ),
  headlineMedium: GoogleFonts.newsreader(
    fontSize: 32,
    height: 1.12,
    fontWeight: FontWeight.w500,
    color: MindPalColors.ink900,
  ),
  titleLarge: GoogleFonts.newsreader(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: MindPalColors.ink900,
  ),
  bodyLarge: GoogleFonts.plusJakartaSans(
    fontSize: 16,
    height: 1.5,
    color: MindPalColors.ink800,
  ),
  bodyMedium: GoogleFonts.plusJakartaSans(
    fontSize: 14,
    height: 1.45,
    color: MindPalColors.ink700,
  ),
  bodySmall: GoogleFonts.plusJakartaSans(
    fontSize: 12,
    height: 1.4,
    color: MindPalColors.ink700,
  ),
  labelSmall: GoogleFonts.plusJakartaSans(
    fontSize: 10,
    letterSpacing: 1.1,
    fontWeight: FontWeight.w700,
    color: MindPalColors.ink700,
  ),
);

TextTheme get _darkTextTheme => TextTheme(
  headlineLarge: GoogleFonts.newsreader(
    fontSize: 44,
    height: 1.05,
    fontWeight: FontWeight.w500,
    color: MindPalColors.darkTextPrimary,
  ),
  headlineMedium: GoogleFonts.newsreader(
    fontSize: 32,
    height: 1.12,
    fontWeight: FontWeight.w500,
    color: MindPalColors.darkTextPrimary,
  ),
  titleLarge: GoogleFonts.newsreader(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: MindPalColors.darkTextPrimary,
  ),
  bodyLarge: GoogleFonts.plusJakartaSans(
    fontSize: 16,
    height: 1.5,
    color: MindPalColors.darkTextSecondary,
  ),
  bodyMedium: GoogleFonts.plusJakartaSans(
    fontSize: 14,
    height: 1.45,
    color: MindPalColors.darkTextSecondary,
  ),
  bodySmall: GoogleFonts.plusJakartaSans(
    fontSize: 12,
    height: 1.4,
    color: MindPalColors.darkTextTertiary,
  ),
  labelSmall: GoogleFonts.plusJakartaSans(
    fontSize: 10,
    letterSpacing: 1.1,
    fontWeight: FontWeight.w700,
    color: MindPalColors.darkTextTertiary,
  ),
);

InputDecorationTheme _inputTheme({
  required Color fill,
  required Color border,
  required Color hint,
}) => InputDecorationTheme(
  filled: true,
  fillColor: fill,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(100),
    borderSide: BorderSide(color: border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(100),
    borderSide: BorderSide(color: border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(100),
    borderSide: BorderSide(color: MindPalColors.clay300, width: 1.5),
  ),
  hintStyle: TextStyle(color: hint),
  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
);

// ─────────────────────────────────────────────────────────────
// Dark mode color extensions — use these in widgets instead of
// hardcoding colors so they adapt correctly to theme mode.
//
// Usage:
//   context.darkSurface   → darkSurfaceMid in dark, white in light
//   context.borderColor   → darkBorder in dark, clay200 in light
// ─────────────────────────────────────────────────────────────
extension MindPalThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get cardColor => isDark ? MindPalColors.darkSurface : Colors.white;

  Color get cardColorElevated =>
      isDark ? MindPalColors.darkSurfaceMid : MindPalColors.sand100;

  Color get borderColor =>
      isDark ? MindPalColors.darkBorder : MindPalColors.clay200;

  Color get drawerBg =>
      isDark ? MindPalColors.darkSurface : const Color(0xFFF3EFE9);

  Color get navBarBg => isDark ? MindPalColors.darkNavBg : MindPalColors.navBg;

  Color get primaryText =>
      isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900;

  Color get secondaryText =>
      isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700;

  Color get hintText =>
      isDark
          ? MindPalColors.darkTextTertiary
          : MindPalColors.ink700.withValues(alpha: 0.5);

  Color get inputFill =>
      isDark ? MindPalColors.darkSurfaceMid : MindPalColors.sand50;

  Color get scaffoldBg => isDark ? MindPalColors.darkBg : MindPalColors.surface;

  // Chat bubbles
  Color get userBubbleBg =>
      isDark ? MindPalColors.darkSurfaceHigh : MindPalColors.clay200;

  Color get aiBubbleBg => isDark ? MindPalColors.darkSurface : Colors.white;

  // Streak card always stays dark (it's a design element)
  Color get streakCardBg => MindPalColors.inkDeep;

  // New reflection button in drawer
  Color get newReflectionBg =>
      isDark ? MindPalColors.darkSurfaceMid : MindPalColors.clay200;
}
