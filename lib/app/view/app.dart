// lib/app/view/app.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/core/theme/cubit/theme_cubit.dart';
import 'package:beacon_os/onboarding/gateway/view/onboarding_gateway_page.dart'; // ✅ الاستدعاء الجديد النظيف
import 'package:beacon_os/spatial_compass/view/spatial_compass_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

class App extends StatelessWidget {
  const App({
    required LauncherRepository launcherRepository,
    required AppSetting initialSettings,
    super.key,
  })  : _launcherRepository = launcherRepository,
        _initialSettings = initialSettings;

  final LauncherRepository _launcherRepository;
  final AppSetting _initialSettings;

  @override
  Widget build(BuildContext context) {
    final bool hasCompletedOnboarding = _initialSettings.hasCompletedOnboarding;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _launcherRepository),
      ],
      child: BlocProvider(
        create: (_) => ThemeCubit(
          isHighContrast: _initialSettings.isHighContrast,
        ),
        child: BlocBuilder<ThemeCubit, AppThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: themeMode == AppThemeMode.highContrastOled
                  ? AppTheme.highContrastOledTheme
                  : AppTheme.warmPaperTheme,
              // 🚪 البوابة المشتركة هي المدخل الوحيد للوافد الجديد
              home: hasCompletedOnboarding
                  ? const SpatialCompassPage()
                  : const OnboardingGatewayPage(),
            );
          },
        ),
      ),
    );
  }
}