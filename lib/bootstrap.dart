// lib/bootstrap.dart
import 'dart:async';
import 'dart:developer';

import 'package:beacon_os/app/app.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:launcher_repository/launcher_repository.dart';

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

  // تهيئة مستودع النظام المركزي
  final launcherRepository = LauncherRepository();

  runApp(App(launcherRepository: launcherRepository));
}