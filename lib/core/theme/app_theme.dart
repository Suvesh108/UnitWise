import 'package:flutter/material.dart';
import 'app_typography.dart';

class AppTheme {
  // Luminous Minimalist Palette
  static const Color backgroundLight = Color(0xFFF8FAFC); // Clean airy canvas
  static const Color surfaceCard = Color(0xFFFFFFFF);     // Pure white cards
  static const Color borderSubtle = Color(0xFFE2E8F0);    // Whisper border
  static const Color borderHighlight = Color(0xFFCBD5E1);
  static const Color surfaceMuted = Color(0xFFF1F5F9);

  // Modern Accent Colors
  static const Color emeraldPrimary = Color(0xFF0F766E);  // Deep Nordic Teal/Emerald
  static const Color primaryGreen = emeraldPrimary;       // Alias for compatibility
  static const Color emeraldLight = Color(0xFF14B8A6);    // Crisp Mint/Teal
  static const Color textDark = Color(0xFF0F172A);        // Slate 900
  static const Color textMuted = Color(0xFF64748B);       // Slate 500
  static const Color textSubtle = Color(0xFF94A3B8);      // Slate 400

  // Feature Accents
  static const Color solarGold = Color(0xFFD97706);       // Warm Amber
  static const Color warmAmber = solarGold;               // Warm Amber alias
  static const Color solarGoldLight = Color(0xFFFEF3C7);  // Soft Amber Glow
  static const Color electricCyan = Color(0xFF0284C7);    // Modern Blue/Cyan
  static const Color alertCoral = Color(0xFFE11D48);      // Rose/Coral

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: AppTypography.primaryFontFamily,
    fontFamilyFallback: AppTypography.fallbackFonts,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: emeraldPrimary,
      onPrimary: Colors.white,
      secondary: electricCyan,
      tertiary: solarGold,
      surface: surfaceCard,
      onSurface: textDark,
      surfaceContainerHighest: Color(0xFFF1F5F9),
      outline: borderSubtle,
      outlineVariant: Color(0xFFF1F5F9),
    ),
    textTheme: TextTheme(
      headlineLarge: AppTypography.style(fontSize: 34, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -1.0),
      headlineMedium: AppTypography.style(fontSize: 24, fontWeight: FontWeight.w700, color: textDark, letterSpacing: -0.6),
      titleLarge: AppTypography.style(fontSize: 18, fontWeight: FontWeight.w700, color: textDark, letterSpacing: -0.3),
      titleMedium: AppTypography.style(fontSize: 15, fontWeight: FontWeight.w600, color: textDark, letterSpacing: -0.2),
      bodyLarge: AppTypography.style(fontSize: 14, fontWeight: FontWeight.w500, color: textDark, height: 1.5),
      bodyMedium: AppTypography.style(fontSize: 13, fontWeight: FontWeight.w400, color: textMuted, height: 1.45),
      labelLarge: AppTypography.style(fontSize: 12, fontWeight: FontWeight.w700, color: textDark, letterSpacing: 0.2),
      labelSmall: AppTypography.style(fontSize: 10.5, fontWeight: FontWeight.w700, color: textMuted, letterSpacing: 0.8),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundLight,
      foregroundColor: textDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.style(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: textDark,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: borderSubtle, width: 1.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderSubtle, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderSubtle, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: emeraldPrimary, width: 1.8),
      ),
      labelStyle: const TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500),
      hintStyle: const TextStyle(color: textSubtle, fontSize: 13),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceCard,
      selectedColor: emeraldPrimary.withValues(alpha: 0.12),
      side: const BorderSide(color: borderSubtle, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDark),
      secondaryLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: emeraldPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: emeraldPrimary,
      inactiveTrackColor: const Color(0xFFE2E8F0),
      thumbColor: Colors.white,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 3),
      overlayColor: emeraldPrimary.withValues(alpha: 0.15),
      trackHeight: 5,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return emeraldPrimary;
          }
          return const Color(0xFFF1F5F9);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return textDark;
        }),
        side: const WidgetStatePropertyAll(BorderSide.none),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        textStyle: WidgetStatePropertyAll(
          AppTypography.style(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: emeraldPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: AppTypography.style(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textDark,
        side: const BorderSide(color: borderSubtle, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: AppTypography.style(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFF1F5F9),
      thickness: 1,
      space: 1,
    ),
  );

  static ThemeData darkTheme = lightTheme;
}
