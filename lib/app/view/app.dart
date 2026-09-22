// lib/app/view/app.dart
import 'package:beacon_os/auth/view/login_page.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/core/theme/cubit/theme_cubit.dart'; // استدعاء الـ Cubit
import 'package:beacon_os/spatial_compass/view/spatial_compass_page.dart';
import 'package:cloud_sync_api/cloud_sync_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class App extends StatelessWidget {
  const App({
    required LauncherRepository launcherRepository,
    super.key,
  }) : _launcherRepository = launcherRepository;

  final LauncherRepository _launcherRepository;

  @override
  Widget build(BuildContext context) {
    final cloudSync = CloudSyncClient();
    final bool isLoggedIn = cloudSync.currentUser != null;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _launcherRepository),
      ],
      // 1. تغليف التطبيق بـ ThemeCubit
      child: BlocProvider(
        create: (_) => ThemeCubit(),
        // 2. الاستماع لتغيرات الثيم
        child: BlocBuilder<ThemeCubit, AppThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              // 3. تحديد الثيم ديناميكياً بناءً على الحالة
              theme: themeMode == AppThemeMode.highContrastOled
                  ? AppTheme.highContrastOledTheme
                  : AppTheme.warmPaperTheme,
              home: isLoggedIn ? const SpatialCompassPage() : const LoginPage(),
            );
          },
        ),
      ),
    );
  }
}