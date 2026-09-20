// lib/subscription/cubit/subscription_state.dart
import 'package:equatable/equatable.dart';

enum SubscriptionStatus { initial, loading, free, pro, error }

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.status = SubscriptionStatus.initial,
    this.freeQueriesRemaining = 5,
    this.errorMessage,
  });

  final SubscriptionStatus status;
  final int freeQueriesRemaining;
  final String? errorMessage;

  bool get isPro => status == SubscriptionStatus.pro;
  bool get canUseVision => isPro || freeQueriesRemaining > 0;

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    int? freeQueriesRemaining,
    String? errorMessage,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      freeQueriesRemaining: freeQueriesRemaining ?? this.freeQueriesRemaining,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, freeQueriesRemaining, errorMessage];
}