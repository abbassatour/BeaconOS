// lib/app/view/app.dart
import 'package:beacon_os/auth/view/login_page.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
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

    return RepositoryProvider.value(
      value: _launcherRepository,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.warmPaperTheme,
        // يدخل مباشرة لبوصلة النظام الفضائية
        home: isLoggedIn ? const SpatialCompassPage() : const LoginPage(),
      ),
    );
  }
}