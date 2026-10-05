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
  static const Color errorRed = Color(0xFFDC2626);

  // ===========================================================================
  // 🌌 2. ألوان ثيم "التباين العالي" (Ice-Void OLED)
  // ===========================================================================
  static const Color pureBlack = Color(0xFF000000); 
  static const Color voidCardSurface = Color(0xFF121212); 
  static const Color cyanHighlight = Color(0xFF00E5FF); 
  static const Color yellowHighlight = Color(0xFFFFEA00); 
  static const Color highContrastText = Color(0xFFFFFFFF); 
  static const Color highContrastMuted = Color(0xFFB5B5B5); 
  static const Color highContrastBorder = Color(0xFF5A5A5A); 
  static const Color highContrastError = Color(0xFFFF453A); 

  // ===========================================================================
  // 📜 3. بناء الثيم التحريري الورقي (Warm Paper Theme)
  // ===========================================================================
  static ThemeData get warmPaperTheme {
    final colorScheme = const ColorScheme.light(
      primary: terracotta,
      secondary: warmAmber,
      surface: cardSurface,
      onSurface: carbonInk,
      error: errorRed,
      outline: softBorder,
      onSurfaceVariant: mutedInk,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: warmPaper,
      colorScheme: colorScheme,
      // 🌟 التوحيد الجذري للخطوط يمنع فشل الـ Interpolation
      typography: Typography.material2021(colorScheme: colorScheme),
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
          minimumSize: const Size(64, 52),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: terracotta,
          minimumSize: const Size(64, 52),
          side: const BorderSide(color: softBorder, width: 1.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: softBorder, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: softBorder, thickness: 1.5, space: 24),
    );
  }

  // ===========================================================================
  // 🌌 4. بناء ثيم التباين العالي (Ice-Void OLED Theme)
  // ===========================================================================
  static ThemeData get highContrastOledTheme {
    final colorScheme = const ColorScheme.dark(
      primary: cyanHighlight,
      secondary: yellowHighlight,
      surface: voidCardSurface,
      onSurface: highContrastText,
      error: highContrastError,
      outline: highContrastBorder,
      onSurfaceVariant: highContrastMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: pureBlack,
      colorScheme: colorScheme,
      // 🌟 التوحيد الجذري للخطوط يمنع فشل الـ Interpolation
      typography: Typography.material2021(colorScheme: colorScheme),
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
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: highContrastText, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        headlineMedium: TextStyle(color: highContrastText, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        bodyLarge: TextStyle(color: highContrastText, fontSize: 17, fontWeight: FontWeight.w700, height: 1.55, letterSpacing: 0.3),
        bodyMedium: TextStyle(color: highContrastMuted, fontSize: 14, fontWeight: FontWeight.w600, height: 1.45),
        labelLarge: TextStyle(color: cyanHighlight, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyanHighlight,
          foregroundColor: pureBlack,
          elevation: 0,
          minimumSize: const Size(64, 54),
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
          minimumSize: const Size(64, 54),
          side: const BorderSide(color: cyanHighlight, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
      cardTheme: CardThemeData(
        color: voidCardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: highContrastBorder, width: 1.8),
        ),
      ),
      dividerTheme: const DividerThemeData(color: highContrastBorder, thickness: 1.5, space: 24),
    );
  }
}

extension ThemeColorsX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyle => Theme.of(this).textTheme;
  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
}