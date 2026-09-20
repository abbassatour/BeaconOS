// lib/subscription/cubit/subscription_cubit.dart
import 'package:beacon_os/core/services/revenuecat_service.dart';
import 'package:beacon_os/subscription/cubit/subscription_state.dart';
import 'package:bloc/bloc.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit({RevenueCatService? rcService})
      : _rc = rcService ?? RevenueCatService.instance,
        super(const SubscriptionState()) {
    checkSubscriptionStatus();
  }

  final RevenueCatService _rc;

  Future<void> checkSubscriptionStatus() async {
    emit(state.copyWith(status: SubscriptionStatus.loading));
    try {
      final isPro = await _rc.isProUser();
      emit(state.copyWith(
        status: isPro ? SubscriptionStatus.pro : SubscriptionStatus.free,
      ));
    } catch (e) {
      emit(state.copyWith(status: SubscriptionStatus.free));
    }
  }

  Future<bool> purchasePro() async {
    emit(state.copyWith(status: SubscriptionStatus.loading));
    final success = await _rc.purchasePro();
    if (success) {
      emit(state.copyWith(status: SubscriptionStatus.pro));
    } else {
      emit(state.copyWith(
        status: SubscriptionStatus.free,
        errorMessage: 'Purchase was cancelled or could not be completed.',
      ));
    }
    return success;
  }
}