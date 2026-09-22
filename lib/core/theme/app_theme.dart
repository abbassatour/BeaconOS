// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ========================================================
  // 📜 ألوان ثيم "الورق التحريري الهادئ" (Warm Paper)
  // ========================================================
  static const Color warmPaper = Color(0xFFFAF7F2); 
  static const Color cardSurface = Color(0xFFFFFFFF); 
  static const Color carbonInk = Color(0xFF1C1917); 
  static const Color mutedInk = Color(0xFF78716C); 
  static const Color terracotta = Color(0xFFC2410C); 
  static const Color warmAmber = Color(0xFFD97706); 
  static const Color softBorder = Color(0xFFE7E2D8); 
  static const Color subtleFill = Color(0xFFF4EFEA); 
  static const Color errorRed = Color(0xFFDC2626); 

  // ========================================================
  // 🌌 ألوان ثيم "التباين العالي" (Ice-Void OLED) للمكفوفين
  // ========================================================
  static const Color pureBlack = Color(0xFF000000); // توفير طاقة OLED وتباين مطلق
  static const Color voidCardSurface = Color(0xFF111111); // أسود رمادي للبطاقات
  static const Color cyanHighlight = Color(0xFF00E5FF); // لون سماوي صارخ للقراءة
  static const Color yellowHighlight = Color(0xFFFFEA00); // لون أصفر صارخ للتنبيهات
  static const Color highContrastText = Color(0xFFFFFFFF); // أبيض نقي للنصوص
  static const Color highContrastMuted = Color(0xFFAAAAAA); // رمادي فاتح للنصوص الثانوية
  static const Color highContrastBorder = Color(0xFF333333); // حدود البطاقات

  // --------------------------------------------------------
  // 1. الثيم التحريري الورقي الموحد (Warm Paper Theme)
  // --------------------------------------------------------
  static ThemeData get warmPaperTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: warmPaper,
      colorScheme: const ColorScheme.light(
        primary: terracotta,
        secondary: warmAmber,
        surface: cardSurface,
        onSurface: carbonInk,
        error: errorRed,
        outline: softBorder,
        onSurfaceVariant: mutedInk,
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
        displayLarge: TextStyle(color: carbonInk, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: carbonInk, fontSize: 22, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: carbonInk, fontSize: 17, height: 1.5),
        bodyMedium: TextStyle(color: mutedInk, fontSize: 14),
        labelLarge: TextStyle(color: terracotta, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: terracotta,
          foregroundColor: cardSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // 2. ثيم التباين العالي (High-Contrast OLED Theme)
  // --------------------------------------------------------
  static ThemeData get highContrastOledTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: pureBlack,
      colorScheme: const ColorScheme.dark(
        primary: cyanHighlight,
        secondary: yellowHighlight,
        surface: voidCardSurface,
        onSurface: highContrastText,
        error: errorRed,
        outline: highContrastBorder,
        onSurfaceVariant: highContrastMuted,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: pureBlack,
        elevation: 0,
        iconTheme: IconThemeData(color: cyanHighlight),
        titleTextStyle: TextStyle(
          color: highContrastText,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: highContrastText, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: highContrastText, fontSize: 22, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: highContrastText, fontSize: 17, height: 1.5),
        bodyMedium: TextStyle(color: highContrastMuted, fontSize: 14),
        labelLarge: TextStyle(color: cyanHighlight, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyanHighlight,
          foregroundColor: pureBlack,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ========================================================
// ⚡️ اختصار (Extension) للوصول السريع لألوان الثيم 
// ========================================================
extension ThemeColorsX on BuildContext {
  /// اختصار للوصول السريع لألوان الثيم الحالي
  ColorScheme get colors => Theme.of(this).colorScheme;
  
  /// اختصار للوصول السريع لستايل النصوص الحالي
  TextTheme get textStyle => Theme.of(this).textTheme;

  /// لون الخلفية الأساسي للصفحات
  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
}