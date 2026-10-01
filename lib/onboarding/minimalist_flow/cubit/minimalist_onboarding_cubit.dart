// lib/onboarding/minimalist_flow/cubit/minimalist_onboarding_cubit.dart
import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:beacon_os/onboarding/minimalist_flow/cubit/minimalist_onboarding_state.dart';
import 'package:bloc/bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class MinimalistOnboardingCubit extends Cubit<MinimalistOnboardingState> {
  MinimalistOnboardingCubit({
    required LauncherRepository repository,
    HapticManager? hapticManager,
    SoundController? soundController,
  })  : _repository = repository,
        _haptics = hapticManager ?? HapticManager.instance,
        _sound = soundController ?? SoundController.instance,
        super(const MinimalistOnboardingState());

  final LauncherRepository _repository;
  final HapticManager _haptics;
  final SoundController _sound;

  void selectFocusDuration(int minutes) {
    emit(state.copyWith(selectedFocusDurationMinutes: minutes));
    _haptics.successNotification();
    _sound.play(SoundCue.navCenter);
  }

  void toggleAutoArchive(bool enabled) {
    emit(state.copyWith(autoArchiveCompletedTasks: enabled));
    _haptics.successNotification();
  }

  /// تجربة أمر صوتي سريع ليرى المستخدم كيف تُسجل المهام فوراً
  Future<void> testSampleCommand(String command) async {
    emit(state.copyWith(isTestingVoice: true));
    await _sound.play(SoundCue.processing);

    final result = await _repository.dispatchVoiceCommand(command);

    await _sound.play(SoundCue.success);
    await _haptics.successNotification();

    emit(
      state.copyWith(
        isTestingVoice: false,
        testedVoiceResponse: result.spokenResponse,
      ),
    );
  }

  void goToStep(MinimalistStep step) {
    emit(state.copyWith(currentStep: step));
    _sound.play(SoundCue.navCenter);
  }

  void nextStep() {
    switch (state.currentStep) {
      case MinimalistStep.manifesto:
        goToStep(MinimalistStep.focusTuning);
        break;
      case MinimalistStep.focusTuning:
        goToStep(MinimalistStep.voiceCockpit);
        break;
      case MinimalistStep.voiceCockpit:
        goToStep(MinimalistStep.launcherSetup);
        break;
      case MinimalistStep.launcherSetup:
        finishMinimalistOnboarding();
        break;
    }
  }

  void previousStep() {
    switch (state.currentStep) {
      case MinimalistStep.manifesto:
        break;
      case MinimalistStep.focusTuning:
        goToStep(MinimalistStep.manifesto);
        break;
      case MinimalistStep.voiceCockpit:
        goToStep(MinimalistStep.focusTuning);
        break;
      case MinimalistStep.launcherSetup:
        goToStep(MinimalistStep.voiceCockpit);
        break;
    }
  }

  /// إنهاء الإعداد وتعيين هوية المينيماليست في قاعدة البيانات
  Future<void> finishMinimalistOnboarding() async {
    emit(state.copyWith(status: MinimalistStatus.completing));
    try {
      await _repository.completeOnboarding(
        persona: 'digital_minimalist',
        isHighContrast: false, // ثيم الورق التحريري الهادئ
        speechRate: 0.5,
      );

      await _sound.play(SoundCue.success);
      await _haptics.successNotification();

      emit(state.copyWith(status: MinimalistStatus.completed));
    } catch (e) {
      emit(
        state.copyWith(
          status: MinimalistStatus.error,
          errorMessage: 'Failed to complete setup: $e',
        ),
      );
    }
  }
}