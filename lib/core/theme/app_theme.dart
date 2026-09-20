// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ألوان التوليفة الجليدية الرسمية (Opal & Raycast Style)
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color iceBlue = Color(0xFF38BDF8); // أزرق جليدي متوهج وأنيق
  static const Color deepSlate = Color(0xFF0F172A); // خلفيات البطاقات الداكنة
  static const Color subtleGray = Color(0xFF1E293B);
  static const Color errorRed = Color(0xFFFF334B);

  static ThemeData get highContrastDark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: pureBlack,
      colorScheme: const ColorScheme.dark(
        primary: iceBlue,
        onPrimary: pureBlack,
        surface: pureBlack,
        onSurface: pureWhite,
        error: errorRed,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: iceBlue,
          fontSize: 34,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: pureWhite,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: pureWhite,
          fontSize: 18,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          color: iceBlue,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}