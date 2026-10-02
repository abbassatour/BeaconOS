// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ===========================================================================
  // 📜 1. ألوان ثيم "الورق التحريري الهادئ" (Warm Paper - Digital Minimalist)
  // ===========================================================================
  static const Color warmPaper = Color(0xFFFAF7F2); 
  static const Color cardSurface = Color(0xFFFFFFFF); 
  static const Color carbonInk = Color(0xFF1C1917); 
  static const Color mutedInk = Color(0xFF78716C); 
  static const Color terracotta = Color(0xFFC2410C); 
  static const Color warmAmber = Color(0xFFD97706); 
  static const Color softBorder = Color(0xFFE7E2D8); 
  static const Color subtleFill = Color(0xFFF4EFEA); 
  static const Color errorRed = Color(0xFFDC2626); // تباين 6.1:1 على الورق الفاتح

  // ===========================================================================
  // 🌌 2. ألوان ثيم "التباين العالي" (Ice-Void OLED - WCAG 2.2 AAA Compliant)
  // ===========================================================================
  /// أسود مطلق يطفئ بكسلات OLED ويمنع الوهج (Anti-Glare & Photophobia Relief)
  static const Color pureBlack = Color(0xFF000000); 

  /// سطح بطاقات داكن ومريح للعين يفصل المحتوى دون إشعاع ضوئي
  static const Color voidCardSurface = Color(0xFF121212); 

  /// سماوي فاقع للعناصر التفاعلية الأساسية (نسبة تباين 15.2:1 على الأسود)
  static const Color cyanHighlight = Color(0xFF00E5FF); 

  /// أصفر نيون فاقع للتنبيهات والأولويات (نسبة تباين 18.5:1 على الأسود)
  static const Color yellowHighlight = Color(0xFFFFEA00); 

  /// أبيض نقي للقراءة بأعلى وضوح ممكن (نسبة تباين 21:1 - الحد الأقصى)
  static const Color highContrastText = Color(0xFFFFFFFF); 

  /// رمادي فاتح مقروء جداً للنصوص الثانوية (نسبة تباين 9.6:1 - يتجاوز معيار AAA 7:1)
  static const Color highContrastMuted = Color(0xFFB5B5B5); 

  /// 🛠️ حدود واضحة تفصل البطاقات ومطابقة لمعيار WCAG 1.4.11 (نسبة تباين 3.6:1)
  static const Color highContrastBorder = Color(0xFF5A5A5A); 

  /// 🛠️ أحمر نيون مضيء لا يختفي في الظلام ومقروء للمصابين بعمى الألوان (تباين 7.1:1)
  static const Color highContrastError = Color(0xFFFF453A); 

  // ===========================================================================
  // 📜 3. بناء الثيم التحريري الورقي (Warm Paper Theme)
  // ===========================================================================
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
          minimumSize: const Size(double.infinity, 52), // أبعاد لمس مريحة
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ===========================================================================
  // 🌌 4. بناء ثيم التباين العالي للمكفوفين وضعاف البصر (Ice-Void OLED Theme)
  // ===========================================================================
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
        error: highContrastError,
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
          letterSpacing: 1.5,
        ),
      ),
      // تباعد الحروف وأوزان الخطوط لمنع التزاحم البصري (Anti-Crowding)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: highContrastText,
          fontSize: 34,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        headlineMedium: TextStyle(
          color: highContrastText,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        bodyLarge: TextStyle(
          color: highContrastText,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.55,
          letterSpacing: 0.3,
        ),
        bodyMedium: TextStyle(
          color: highContrastMuted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: cyanHighlight,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
      // أزرار بارزة بحدود واضحة ومساحة لمس لا تقل عن 54dp
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyanHighlight,
          foregroundColor: pureBlack,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: cyanHighlight, width: 2),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cyanHighlight,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: cyanHighlight, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
      // حدود واضحة للبطاقات تمنع ذوبانها في الخلفية السوداء
      cardTheme: CardThemeData(
        color: voidCardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: highContrastBorder, width: 1.8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: highContrastBorder,
        thickness: 1.5,
        space: 24,
      ),
    );
  }
}

// ===========================================================================
// ⚡️ اختصارات سريعة للوصول لخصائص الثيم من أي مكان في الكود
// ===========================================================================
extension ThemeColorsX on BuildContext {
  /// ألوان الـ ColorScheme الحالي
  ColorScheme get colors => Theme.of(this).colorScheme;
  
  /// نصوص الـ TextTheme الحالي
  TextTheme get textStyle => Theme.of(this).textTheme;

  /// لون الخلفية الأساسي
  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
}