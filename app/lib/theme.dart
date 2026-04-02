import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MindPalColors {
  // ── Light mode ──────────────────────────────────────────────
  static const sand50 = Color(0xFFF8F6F2);
  static const sand100 = Color(0xFFF2EDE6);
  static const sand200 = Color(0xFFE7DDD1);
  static const sand300 = Color(0xFFD5C6B4);
  static const sand400 = Color(0xFFC3AE96);
  static const clay50 = Color(0xFFF2EDE7);
  static const clay100 = Color(0xFFE7DDD1);
  static const clay200 = Color(0xFFD6C4AF);
  static const clay300 = Color(0xFFBEA489);
  static const clay400 = Color(0xFFA98765);
  static const sage100 = Color(0xFFE2E6DF);
  static const sage200 = Color(0xFFC6D0C1);
  static const sage300 = Color(0xFF9DAF9F);
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

  // ── Dark mode — warm cocoa palette ──────────────────────────
  // A rich, warm dark theme inspired by coffee and chocolate tones
  // that harmonizes with the light theme's sand/clay warmth
  
  // Backgrounds (warm chocolate browns with subtle red undertones)
  static const darkBg = Color(0xFF1A1512);           // deepest — scaffold (espresso)
  static const darkSurface = Color(0xFF241E1A);       // cards, drawer (dark mocha)
  static const darkSurfaceMid = Color(0xFF2E2621);    // elevated cards (coffee)
  static const darkSurfaceHigh = Color(0xFF3A302A);   // pressed / hover (cocoa)
  static const darkNavBg = Color(0xFF1E1915);         // bottom nav
  
  // New: Clay-tinted surfaces for special elements
  static const darkClay = Color(0xFF3D3228);          // warm clay overlay
  static const darkClayMuted = Color(0xFF332A22);     // subtle clay surface
  static const darkSand = Color(0xFF2A2420);          // warm sand overlay
  
  // Borders (warm, clay-tinted, visible but not harsh)
  static const darkBorder = Color(0xFF4A3D32);        // main border (clay-brown)
  static const darkBorderSub = Color(0xFF362D25);     // subtle dividers
  static const darkBorderAccent = Color(0xFF5C4A3A);  // emphasized borders
  
  // Text (cream/ivory tones, never pure white)
  static const darkTextPrimary = Color(0xFFF2EBE3);   // headings (warm ivory)
  static const darkTextSecondary = Color(0xFFCBC2B8); // body text (warm gray)
  static const darkTextTertiary = Color(0xFF8C8078);  // hints, timestamps
  static const darkTextMuted = Color(0xFF6B615A);     // disabled, placeholders
  
  // Accents (clay family adapted for dark mode)
  static const darkAccent = Color(0xFFD4B896);        // primary accent (warm clay)
  static const darkAccentMuted = Color(0xFFB09A7C);   // secondary accent
  static const darkAccentSubtle = Color(0xFF8A7560);  // subtle accent
  
  // Sage tints for dark mode (muted green-browns)
  static const darkSage = Color(0xFF5A6658);          // sage accent
  static const darkSageMuted = Color(0xFF4A544A);     // subtle sage

  // ── Emotion colors (light mode) ───────────────────────────────
  static const emotionJoy = Color(0xFFE2CAB0);
  static const emotionExcitement = Color(0xFFC9958A);
  static const emotionGratitude = Color(0xFFC89A77);
  static const emotionCalm = Color(0xFFB79282);
  static const emotionNeutral = Color(0xFFD8BEA4);
  static const emotionAnxiety = Color(0xFFD6A88C);
  static const emotionFear = Color(0xFFD4B189);
  static const emotionSadness = Color(0xFFAD8A7A);
  static const emotionFrustration = Color(0xFFBD8777);
  static const emotionAnger = Color(0xFFBF8476);
  static const emotionStress = Color(0xFFCDA080);

  // ── Emotion colors (dark mode — more vibrant for dark bg) ────
  static const darkEmotionJoy = Color(0xFFE8D4BE);
  static const darkEmotionExcitement = Color(0xFFD4A89E);
  static const darkEmotionGratitude = Color(0xFFD4A88A);
  static const darkEmotionCalm = Color(0xFFC4A396);
  static const darkEmotionNeutral = Color(0xFFDCC8B2);
  static const darkEmotionAnxiety = Color(0xFFDEB6A0);
  static const darkEmotionFear = Color(0xFFDCBE9A);
  static const darkEmotionSadness = Color(0xFFBC9C8E);
  static const darkEmotionFrustration = Color(0xFFCA998C);
  static const darkEmotionAnger = Color(0xFFCC968A);
  static const darkEmotionStress = Color(0xFFD8B094);

  static Color emotionColor(String label, {bool isDark = false}) {
    switch (label.trim().toLowerCase()) {
      case 'joy':
        return isDark ? darkEmotionJoy : emotionJoy;
      case 'excitement':
        return isDark ? darkEmotionExcitement : emotionExcitement;
      case 'gratitude':
        return isDark ? darkEmotionGratitude : emotionGratitude;
      case 'calm':
        return isDark ? darkEmotionCalm : emotionCalm;
      case 'anxiety':
        return isDark ? darkEmotionAnxiety : emotionAnxiety;
      case 'fear':
        return isDark ? darkEmotionFear : emotionFear;
      case 'sadness':
        return isDark ? darkEmotionSadness : emotionSadness;
      case 'frustration':
        return isDark ? darkEmotionFrustration : emotionFrustration;
      case 'anger':
        return isDark ? darkEmotionAnger : emotionAnger;
      case 'stress':
        return isDark ? darkEmotionStress : emotionStress;
      default:
        return isDark ? darkEmotionNeutral : emotionNeutral;
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
// DARK THEME — warm cocoa, harmonized with light theme
// ─────────────────────────────────────────────────────────────
ThemeData get mindpalDarkTheme {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: MindPalColors.clay300,
      brightness: Brightness.dark,
      primary: MindPalColors.darkAccent,
      onPrimary: MindPalColors.darkBg,
      secondary: MindPalColors.darkAccentMuted,
      onSecondary: MindPalColors.darkTextPrimary,
      surface: MindPalColors.darkSurface,
      onSurface: MindPalColors.darkTextPrimary,
      outline: MindPalColors.darkBorder,
    ),
    scaffoldBackgroundColor: MindPalColors.darkBg,
    textTheme: _darkTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: MindPalColors.darkBg.withValues(alpha: 0.97),
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
          color: MindPalColors.darkBorder.withValues(alpha: 0.6),
        ),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: MindPalColors.darkNavBg,
      selectedItemColor: MindPalColors.darkAccent,
      unselectedItemColor: MindPalColors.darkTextTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: MindPalColors.darkNavBg,
      indicatorColor: MindPalColors.darkClayMuted,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: MindPalColors.darkAccent,
          );
        }
        return GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: MindPalColors.darkTextTertiary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: MindPalColors.darkAccent);
        }
        return const IconThemeData(color: MindPalColors.darkTextTertiary);
      }),
    ),
    inputDecorationTheme: _inputTheme(
      fill: MindPalColors.darkSurfaceMid,
      border: MindPalColors.darkBorder,
      hint: MindPalColors.darkTextMuted,
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
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return MindPalColors.darkAccent;
        }
        return MindPalColors.darkTextTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return MindPalColors.darkAccentSubtle;
        }
        return MindPalColors.darkSurfaceHigh;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: MindPalColors.darkAccent,
      inactiveTrackColor: MindPalColors.darkSurfaceHigh,
      thumbColor: MindPalColors.darkAccent,
      overlayColor: MindPalColors.darkAccent.withValues(alpha: 0.2),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: MindPalColors.darkAccent,
      linearTrackColor: MindPalColors.darkSurfaceHigh,
      circularTrackColor: MindPalColors.darkSurfaceHigh,
    ),
    // Surfaces used by Material widgets (BottomSheet, Dialog, etc.)
    dialogTheme: DialogThemeData(
      backgroundColor: MindPalColors.darkSurfaceMid,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.newsreader(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: MindPalColors.darkTextPrimary,
      ),
      contentTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 1.5,
        color: MindPalColors.darkTextSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: MindPalColors.darkBorder.withValues(alpha: 0.5)),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: MindPalColors.darkSurfaceMid,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: MindPalColors.darkSurfaceMid,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: MindPalColors.darkBorder.withValues(alpha: 0.5)),
      ),
      textStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: MindPalColors.darkTextPrimary,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: MindPalColors.darkSurfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MindPalColors.darkBorder.withValues(alpha: 0.5)),
      ),
      textStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: MindPalColors.darkTextPrimary,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: MindPalColors.darkSurfaceHigh,
      contentTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: MindPalColors.darkTextPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: MindPalColors.darkAccent,
      foregroundColor: MindPalColors.darkBg,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MindPalColors.darkAccent,
        foregroundColor: MindPalColors.darkBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MindPalColors.darkAccent,
        foregroundColor: MindPalColors.darkBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MindPalColors.darkAccent,
        side: const BorderSide(color: MindPalColors.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MindPalColors.darkAccent,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: MindPalColors.darkTextSecondary,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: MindPalColors.darkSurfaceMid,
      selectedColor: MindPalColors.darkClayMuted,
      disabledColor: MindPalColors.darkSurface,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: MindPalColors.darkTextPrimary,
      ),
      secondaryLabelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: MindPalColors.darkTextSecondary,
      ),
      side: BorderSide(color: MindPalColors.darkBorder.withValues(alpha: 0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    listTileTheme: ListTileThemeData(
      textColor: MindPalColors.darkTextPrimary,
      iconColor: MindPalColors.darkTextSecondary,
      selectedColor: MindPalColors.darkAccent,
      selectedTileColor: MindPalColors.darkClayMuted.withValues(alpha: 0.5),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: MindPalColors.darkTextPrimary,
      unselectedLabelColor: MindPalColors.darkTextTertiary,
      indicatorColor: MindPalColors.darkAccent,
      dividerColor: MindPalColors.darkBorderSub,
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

  // Surface colors
  Color get cardColor => isDark ? MindPalColors.darkSurface : Colors.white;
  Color get cardColorElevated =>
      isDark ? MindPalColors.darkSurfaceMid : MindPalColors.sand100;
  Color get cardColorHigh =>
      isDark ? MindPalColors.darkSurfaceHigh : MindPalColors.sand200;
  Color get scaffoldBg => isDark ? MindPalColors.darkBg : MindPalColors.surface;
  Color get drawerBg =>
      isDark ? MindPalColors.darkSurface : const Color(0xFFF3EFE9);
  Color get navBarBg => isDark ? MindPalColors.darkNavBg : MindPalColors.navBg;

  // Borders
  Color get borderColor =>
      isDark ? MindPalColors.darkBorder : MindPalColors.clay200;
  Color get borderColorSubtle =>
      isDark ? MindPalColors.darkBorderSub : MindPalColors.clay100;
  Color get borderColorAccent =>
      isDark ? MindPalColors.darkBorderAccent : MindPalColors.clay300;

  // Text colors
  Color get primaryText =>
      isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900;
  Color get secondaryText =>
      isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700;
  Color get tertiaryText =>
      isDark ? MindPalColors.darkTextTertiary : MindPalColors.ink700.withValues(alpha: 0.7);
  Color get hintText =>
      isDark ? MindPalColors.darkTextMuted : MindPalColors.ink700.withValues(alpha: 0.5);
  Color get mutedText =>
      isDark ? MindPalColors.darkTextMuted : MindPalColors.ink700.withValues(alpha: 0.4);

  // Accent colors
  Color get accentColor =>
      isDark ? MindPalColors.darkAccent : MindPalColors.clay400;
  Color get accentColorMuted =>
      isDark ? MindPalColors.darkAccentMuted : MindPalColors.clay300;
  Color get accentColorSubtle =>
      isDark ? MindPalColors.darkAccentSubtle : MindPalColors.clay200;

  // Input fields
  Color get inputFill =>
      isDark ? MindPalColors.darkSurfaceMid : MindPalColors.sand50;

  // Chat bubbles
  Color get userBubbleBg =>
      isDark ? MindPalColors.darkClay : MindPalColors.clay200;
  Color get aiBubbleBg => isDark ? MindPalColors.darkSurface : Colors.white;

  // Interactive elements
  Color get hoverBg =>
      isDark ? MindPalColors.darkSurfaceHigh : MindPalColors.sand100;
  Color get pressedBg =>
      isDark ? MindPalColors.darkClayMuted : MindPalColors.clay100;
  Color get selectedBg =>
      isDark ? MindPalColors.darkClayMuted : MindPalColors.clay100;

  // Special cards
  Color get streakCardBg => MindPalColors.inkDeep;
  Color get newReflectionBg =>
      isDark ? MindPalColors.darkClayMuted : MindPalColors.clay200;
  Color get pillBg =>
      isDark ? MindPalColors.darkSurfaceMid : MindPalColors.sand100;
  Color get pillBgActive =>
      isDark ? MindPalColors.darkClayMuted : MindPalColors.clay200;

  // Chart colors
  Color get chartLine =>
      isDark ? MindPalColors.darkAccent : MindPalColors.clay400;
  Color get chartGrid =>
      isDark ? MindPalColors.darkBorderSub : MindPalColors.clay100;
  Color get chartTooltipBg =>
      isDark ? MindPalColors.darkSurfaceHigh : MindPalColors.clay200;

  // Helper for emotion colors that respects dark mode
  Color emotionColor(String label) =>
      MindPalColors.emotionColor(label, isDark: isDark);
}
