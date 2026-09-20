// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ========================================================
  // 📜 1. باليت "الورق التحريري الهادئ" (Warm Paper) - الثيم الافتراضي
  // ========================================================
  static const Color warmPaper = Color(0xFFFAF7F2);      // سكري عاجي دافئ للخلفية
  static const Color cardSurface = Color(0xFFFFFFFF);    // أبيض نقي للبطاقات والحقول
  static const Color carbonInk = Color(0xFF1C1917);      // حبر كربوني فاحم وناعم للقراءة
  static const Color mutedInk = Color(0xFF78716C);       // رمادي دافئ للنصوص الفرعية
  static const Color terracotta = Color(0xFFC2410C);     // لون ترابي فخاري أنيق للتفاعل
  static const Color warmAmber = Color(0xFFD97706);      // كهرماني دافئ للنشاط
  static const Color softBorder = Color(0xFFE7E2D8);     // فواصل ورقية ناعمة

  // ========================================================
  // 🌌 2. باليت "التباين العالي الليلي" (Ice-Void) - للمكفوفين والـ OLED
  // ========================================================
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color iceBlue = Color(0xFF38BDF8);
  static const Color deepSlate = Color(0xFF0F172A);
  static const Color subtleGray = Color(0xFF1E293B);

  // ألوان مشتركة
  static const Color errorRed = Color(0xFFDC2626);

  // --------------------------------------------------------
  // الثيم السكري الافتراضي (Warm Paper Theme)
  // --------------------------------------------------------
  static ThemeData get warmPaperTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: warmPaper,
      colorScheme: const ColorScheme.light(
        primary: terracotta,
        onPrimary: cardSurface,
        surface: cardSurface,
        onSurface: carbonInk,
        error: errorRed,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: carbonInk,
          fontSize: 34,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: carbonInk,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: carbonInk,
          fontSize: 17,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: mutedInk,
          fontSize: 14,
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // الثيم الليلي عالي التباين (High-Contrast Dark Theme)
  // --------------------------------------------------------
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