// lib/core/theme/cubit/theme_cubit.dart
import 'package:bloc/bloc.dart';

/// يمثل حالتي الثيم المتاحتين في النظام
enum AppThemeMode { warmPaper, highContrastOled }

class ThemeCubit extends Cubit<AppThemeMode> {
  ThemeCubit() : super(AppThemeMode.warmPaper);

  /// تغيير الثيم بناءً على خيار المستخدم
  void toggleTheme({required bool isHighContrast}) {
    if (isHighContrast) {
      emit(AppThemeMode.highContrastOled);
    } else {
      emit(AppThemeMode.warmPaper);
    }
  }
}