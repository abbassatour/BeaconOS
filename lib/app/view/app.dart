// lib/app/view/app.dart
import 'package:beacon_os/auth/cubit/auth_cubit.dart';
import 'package:beacon_os/core/spatial_kernel/spatial_topology.dart';
import 'package:beacon_os/core/spatial_kernel/voice_command_dispatcher.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/core/theme/cubit/theme_cubit.dart';
import 'package:beacon_os/onboarding/gateway/view/onboarding_gateway_page.dart';
import 'package:beacon_os/spatial_compass/view/spatial_compass_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

/// المفتاح العام للملاحة للوصول للسياق الجذري عند تنفيذ الأوامر الصوتية
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class App extends StatefulWidget {
  const App({
    required LauncherRepository launcherRepository,
    required AppSetting initialSettings,
    super.key,
  })  : _launcherRepository = launcherRepository,
        _initialSettings = initialSettings;

  final LauncherRepository _launcherRepository;
  final AppSetting _initialSettings;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final SpatialTopology _topology;
  late final VoiceCommandDispatcher _voiceDispatcher;

  @override
  void initState() {
    super.initState();

    // 1. بناء شبكة الطوبولوجيا الفضائية المحملة بالموديولات الخمسة
    _topology = SpatialTopology.defaultTopology();

    // 2. تشغيل حافلة الأوامر الصوتية الذكية
    _voiceDispatcher = VoiceCommandDispatcher(
      topology: _topology,
      assistantRepository: widget._launcherRepository.assistant,
      navigatorKey: appNavigatorKey,
    );

    // 3. ربط حافلة الأوامر بالمستودع المركزي لتعمل عبر Zero-UI والتطبيق كاملاً
    widget._launcherRepository.registerVoiceDispatcher(
      (query, {base64Image}) => _voiceDispatcher.dispatch(
        query,
        base64Image: base64Image,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCompletedOnboarding =
        widget._initialSettings.hasCompletedOnboarding;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget._launcherRepository),
        RepositoryProvider<SpatialTopology>.value(value: _topology),
        RepositoryProvider<VoiceCommandDispatcher>.value(
          value: _voiceDispatcher,
        ),
        RepositoryProvider<TaskAgendaRepository>.value(
          value: widget._launcherRepository.tasks,
        ),
        RepositoryProvider<FocusAlarmsRepository>.value(
          value: widget._launcherRepository.focusAlarms,
        ),
        RepositoryProvider<CommsRepository>.value(
          value: widget._launcherRepository.comms,
        ),
        RepositoryProvider<SystemHardwareRepository>.value(
          value: widget._launcherRepository.hardware,
        ),
        RepositoryProvider<SettingsRepository>.value(
          value: widget._launcherRepository.settings,
        ),
        RepositoryProvider<AssistantRepository>.value(
          value: widget._launcherRepository.assistant,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ThemeCubit(
              isHighContrast: widget._initialSettings.isHighContrast,
            ),
          ),
          BlocProvider(
            create: (context) => AuthCubit(
              repository: widget._launcherRepository,
            ),
          ),
        ],
        child: BlocBuilder<ThemeCubit, AppThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              navigatorKey: appNavigatorKey,
              debugShowCheckedModeBanner: false,
              theme: themeMode == AppThemeMode.highContrastOled
                  ? AppTheme.highContrastOledTheme
                  : AppTheme.warmPaperTheme,
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