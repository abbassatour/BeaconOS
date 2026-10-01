// lib/onboarding/minimalist_flow/view/minimalist_onboarding_page.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/onboarding/minimalist_flow/cubit/minimalist_onboarding_cubit.dart';
import 'package:beacon_os/onboarding/minimalist_flow/cubit/minimalist_onboarding_state.dart';
import 'package:beacon_os/onboarding/minimalist_flow/view/steps/1_minimalist_manifesto_step.dart';
import 'package:beacon_os/onboarding/minimalist_flow/view/steps/2_minimalist_focus_step.dart';
import 'package:beacon_os/onboarding/minimalist_flow/view/steps/3_minimalist_cockpit_step.dart';
import 'package:beacon_os/onboarding/minimalist_flow/view/steps/4_minimalist_launcher_step.dart';
import 'package:beacon_os/spatial_compass/view/spatial_compass_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class MinimalistOnboardingPage extends StatelessWidget {
  const MinimalistOnboardingPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const MinimalistOnboardingPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MinimalistOnboardingCubit(
        repository: context.read<LauncherRepository>(),
      ),
      child: const _MinimalistScaffold(),
    );
  }
}

class _MinimalistScaffold extends StatelessWidget {
  const _MinimalistScaffold();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MinimalistOnboardingCubit, MinimalistOnboardingState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == MinimalistStatus.completed) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const SpatialCompassPage(),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppTheme.warmPaper,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, state),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _buildStep(state.currentStep),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, MinimalistOnboardingState state) {
    final cubit = context.read<MinimalistOnboardingCubit>();
    final stepNum = state.currentStep.index + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'BEACON OS • INTENTIONALITY $stepNum/4',
            style: const TextStyle(
              color: AppTheme.terracotta,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          TextButton(
            onPressed: cubit.finishMinimalistOnboarding,
            child: const Text(
              'Skip to Cockpit',
              style: TextStyle(
                color: AppTheme.mutedInk,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(MinimalistStep step) {
    switch (step) {
      case MinimalistStep.manifesto:
        return const MinimalistManifestoStep(key: ValueKey('manifesto'));
      case MinimalistStep.focusTuning:
        return const MinimalistFocusStep(key: ValueKey('focus'));
      case MinimalistStep.voiceCockpit:
        return const MinimalistCockpitStep(key: ValueKey('cockpit'));
      case MinimalistStep.launcherSetup:
        return const MinimalistLauncherStep(key: ValueKey('launcher'));
    }
  }
}