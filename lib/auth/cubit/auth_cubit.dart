// lib/auth/cubit/auth_cubit.dart
import 'dart:async';

import 'package:beacon_os/auth/cubit/auth_state.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_sync_api/cloud_sync_api.dart';
import 'package:launcher_repository/launcher_repository.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required LauncherRepository repository,
    CloudSyncClient? cloudSyncClient,
  })  : _repository = repository,
        _cloud = cloudSyncClient ?? CloudSyncClient(),
        super(const AuthState()) {
    checkCurrentAuth();
    _listenToAuthChanges();
  }

  final LauncherRepository _repository;
  final CloudSyncClient _cloud;
  StreamSubscription<dynamic>? _authSubscription;

  void _listenToAuthChanges() {
    _authSubscription = _cloud.authStateChanges?.listen((_) {
      checkCurrentAuth();
    });
  }

  void checkCurrentAuth() {
    final user = _cloud.currentUser;
    if (user != null) {
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));

      // تشغيل المزامنة بالاتجاهين في الخلفية بسلاسة
      Future.microtask(() async {
        await _repository.restoreVaultFromCloud();
        await _repository.syncPendingOfflineChanges();
      });
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final res = await _cloud.signInWithEmail(
        email: email,
        password: password,
      );
      await _repository.restoreVaultFromCloud();
      emit(state.copyWith(status: AuthStatus.authenticated, user: res?.user));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Invalid credentials or connection error.',
        ),
      );
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final res = await _cloud.signUpWithEmail(
        email: email,
        password: password,
      );
      emit(state.copyWith(status: AuthStatus.authenticated, user: res?.user));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Could not create account. Please check your details.',
        ),
      );
    }
  }

  Future<void> continueAsGuest() async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final res = await _cloud.signInAnonymously();
      emit(state.copyWith(status: AuthStatus.authenticated, user: res?.user));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.authenticated));
    }
  }

  Future<void> signOut() async {
    await _cloud.signOut();
    emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}