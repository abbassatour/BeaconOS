// lib/bootstrap.dart
import 'dart:async';
import 'dart:developer';

import 'package:beacon_os/app/app.dart';
import 'package:beacon_os/core/constants/api_constants.dart';
import 'package:beacon_os/core/services/onesignal_service.dart';
import 'package:beacon_os/core/services/revenuecat_service.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voice_ai_api/voice_ai_api.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap() async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تهيئة Supabase بشكل آمن
  if (ApiConstants.supabaseUrl.isNotEmpty && ApiConstants.supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: ApiConstants.supabaseUrl,
        anonKey: ApiConstants.supabaseAnonKey,
      );
      log('Supabase: Initialized successfully.');
    } catch (e) {
      log('Supabase init error: $e');
    }
  } else {
    log('Supabase: Skipped initialization (Keys are empty).');
  }

  // 2. تهيئة خدمات الهاكاثون السحابية
  await RevenueCatService.initialize();
  await OneSignalService.initialize();

  // 3. تزويد وكيل الذكاء الاصطناعي بمفتاح OpenRouter
  final llmAgent = LlmAgent(openRouterApiKey: ApiConstants.openRouterApiKey);

  // 4. تهيئة مستودع النظام
  final launcherRepository = LauncherRepository(
    llmAgent: llmAgent,
  );

  runApp(App(launcherRepository: launcherRepository));
}