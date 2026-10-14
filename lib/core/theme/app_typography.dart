import 'package:flutter/material.dart';

class AppTypography {
  static const String primaryFontFamily = 'Plus Jakarta Sans';

  static const List<String> fallbackFonts = [
    'Plus Jakarta Sans',
    'Inter',
    'SF Pro Display',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  static TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: primaryFontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
