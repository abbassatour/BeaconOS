// lib/onboarding/blind_flow/view/blind_onboarding_page.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/onboarding/blind_flow/cubit/blind_onboarding_cubit.dart';
import 'package:beacon_os/onboarding/blind_flow/cubit/blind_onboarding_state.dart';
import 'package:beacon_os/onboarding/blind_flow/view/steps/blind_audio_step.dart';
import 'package:beacon_os/onboarding/blind_flow/view/steps/blind_compass_step.dart';
import 'package:beacon_os/onboarding/blind_flow/view/steps/blind_sos_step.dart';
import 'package:beacon_os/onboarding/blind_flow/view/steps/blind_vision_step.dart';
import 'package:beacon_os/spatial_compass/view/spatial_compass_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class BlindOnboardingPage extends StatelessWidget {
  const BlindOnboardingPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const BlindOnboardingPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BlindOnboardingCubit(
        assistantRepository: context.read<AssistantRepository>(),
        settingsRepository: context.read<SettingsRepository>(),
      ),
      child: const _BlindOnboardingScaffold(),
    );
  }
}

class _BlindOnboardingScaffold extends StatelessWidget {
  const _BlindOnboardingScaffold();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BlindOnboardingCubit, BlindOnboardingState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == BlindFlowStatus.completed) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const SpatialCompassPage(),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppTheme.pureBlack,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeaderBar(context, state),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _buildCurrentStep(state.currentStep),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderBar(BuildContext context, BlindOnboardingState state) {
    final stepIndex = state.currentStep.index + 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.highContrastBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'ACCESSIBILITY SETUP • STEP $stepIndex OF 4',
                style: const TextStyle(
                  color: AppTheme.cyanHighlight,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () =>
                context.read<BlindOnboardingCubit>().finishBlindOnboarding(),
            child: const Text(
              'Skip to Cockpit',
              style: TextStyle(
                color: AppTheme.highContrastMuted,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(BlindStep step) {
    switch (step) {
      case BlindStep.audioTuning:
        return const BlindAudioStep(key: ValueKey('audio_step'));
      case BlindStep.compassTraining:
        return const BlindCompassStep(key: ValueKey('compass_step'));
      case BlindStep.visionTest:
        return const BlindVisionStep(key: ValueKey('vision_step'));
      case BlindStep.sosSetup:
        return const BlindSosStep(key: ValueKey('sos_step'));
    }
  }
}