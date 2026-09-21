// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ========================================================
  // 📜 باليت "الورق التحريري الهادئ" (Warm Paper & Carbon Ink)
  // الهوية البصرية الرسمية الموحدة لجميع شاشات النظام
  // ========================================================
  static const Color warmPaper = Color(0xFFFAF7F2); // سكري عاجي دافئ للخلفية
  static const Color cardSurface = Color(0xFFFFFFFF); // أبيض نقي للبطاقات والحقول
  static const Color carbonInk = Color(0xFF1C1917); // حبر كربوني فاحم للقراءة
  static const Color mutedInk = Color(0xFF78716C); // رمادي دافئ للنصوص الثانوية
  static const Color terracotta = Color(0xFFC2410C); // لون ترابي فخاري للإجراءات الأساسية
  static const Color warmAmber = Color(0xFFD97706); // كهرماني دافئ للنشاط والمؤقتات
  static const Color softBorder = Color(0xFFE7E2D8); // فواصل ورقية ناعمة
  static const Color subtleFill = Color(0xFFF4EFEA); // حشو خفيف للحقول والرقاقات
  static const Color errorRed = Color(0xFFDC2626); // أحمر الطوارئ والأخطاء

  // ألوان إضافية مساعدة
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // --------------------------------------------------------
  // الثيم التحريري الورقي الموحد (Warm Paper Theme)
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
      appBarTheme: const AppBarTheme(
        backgroundColor: warmPaper,
        elevation: 0,
        iconTheme: IconThemeData(color: carbonInk),
        titleTextStyle: TextStyle(
          color: carbonInk,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
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
        labelLarge: TextStyle(
          color: terracotta,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: terracotta,
          foregroundColor: cardSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}