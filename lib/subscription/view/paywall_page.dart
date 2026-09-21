// lib/subscription/view/paywall_page.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/subscription/cubit/subscription_cubit.dart';
import 'package:beacon_os/subscription/cubit/subscription_state.dart';
import 'package:beacon_os/subscription/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const PaywallPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubscriptionCubit(),
      child: const _PaywallView(),
    );
  }
}

class _PaywallView extends StatelessWidget {
  const _PaywallView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmPaper,
      appBar: AppBar(
        backgroundColor: AppTheme.warmPaper,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.carbonInk),
      ),
      body: BlocConsumer<SubscriptionCubit, SubscriptionState>(
        listener: (context, state) {
          if (state.status == SubscriptionStatus.pro) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'BeaconOS Pro Unlocked! Thank you for your support.',
                ),
                backgroundColor: AppTheme.terracotta,
              ),
            );
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          if (state.status == SubscriptionStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.terracotta),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LIMITLESS\nVISION',
                  style: TextStyle(
                    color: AppTheme.carbonInk,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unlock unlimited real-time AI spatial guidance, fast-lane processing, and offline priority.',
                  style: TextStyle(
                    color: AppTheme.mutedInk,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                HighContrastPlanCard(
                  title: 'BeaconOS Pro',
                  price: '\$9.99 / mo',
                  description:
                      'Unlimited Gemini multimodal vision, zero-latency execution, and 24/7 radar.',
                  onTap: () => context.read<SubscriptionCubit>().purchasePro(),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    '— OR —',
                    style: TextStyle(
                      color: AppTheme.mutedInk,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SponsorBlindTile(
                  onTap: () => context.read<SubscriptionCubit>().purchasePro(),
                ),
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    'Secured by RevenueCat Sandbox. Test without real charges.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.mutedInk, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}