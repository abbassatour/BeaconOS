// lib/auth/cubit/auth_cubit.dart
import 'package:beacon_os/auth/cubit/auth_state.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_sync_api/cloud_sync_api.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({CloudSyncClient? cloudSyncClient})
      : _cloud = cloudSyncClient ?? CloudSyncClient(),
        super(const AuthState()) {
    checkCurrentAuth();
  }

  final CloudSyncClient _cloud;

  void checkCurrentAuth() {
    final user = _cloud.currentUser;
    if (user != null) {
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final res = await _cloud.signInWithEmail(email: email, password: password);
      emit(state.copyWith(status: AuthStatus.authenticated, user: res?.user));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid credentials or connection error.',
      ));
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final res = await _cloud.signUpWithEmail(email: email, password: password);
      emit(state.copyWith(status: AuthStatus.authenticated, user: res?.user));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Could not create account. Please check your details.',
      ));
    }
  }

  /// تجاوز الدخول فورياً للبدء واستخدام الهاتف بدون حساب سحابي
  Future<void> continueAsGuest() async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final res = await _cloud.signInAnonymously();
      emit(state.copyWith(status: AuthStatus.authenticated, user: res?.user));
    } catch (e) {
      // حتى لو فشل الاتصال، نسمح له بالدخول للوضع المحلي (Offline Mode)
      emit(state.copyWith(status: AuthStatus.authenticated));
    }
  }

  Future<void> signOut() async {
    await _cloud.signOut();
    emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
  }
}