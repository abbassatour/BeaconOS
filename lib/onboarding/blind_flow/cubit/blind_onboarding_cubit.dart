// lib/onboarding/blind_flow/cubit/blind_onboarding_cubit.dart
import 'dart:developer';
import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:beacon_os/core/services/camera_service.dart';
import 'package:beacon_os/onboarding/blind_flow/cubit/blind_onboarding_state.dart';
import 'package:beacon_os/spatial_compass/models/spatial_gestures.dart';
import 'package:bloc/bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class BlindOnboardingCubit extends Cubit<BlindOnboardingState> {
  BlindOnboardingCubit({
    required AssistantRepository assistantRepository,
    required SettingsRepository settingsRepository,
    CameraService? cameraService,
    HapticManager? hapticManager,
    SoundController? soundController,
  })  : _assistant = assistantRepository,
        _settings = settingsRepository,
        _camera = cameraService ?? CameraService.instance,
        _haptics = hapticManager ?? HapticManager.instance,
        _sound = soundController ?? SoundController.instance,
        super(const BlindOnboardingState()) {
    announceCurrentStep(BlindStep.audioTuning);
  }

  final AssistantRepository _assistant;
  final SettingsRepository _settings;
  final CameraService _camera;
  final HapticManager _haptics;
  final SoundController _sound;

  // ===========================================================================
  // 🔊 1. منطق الخطوة الأولى: معايرة سرعة الصوت
  // ===========================================================================

  Future<void> increaseSpeechRate() async {
    final nextRate = (state.speechRate + 0.05).clamp(0.4, 1.0);
    emit(state.copyWith(speechRate: nextRate));
    await _haptics.successNotification();
    await _assistant.setSpeechRate(nextRate);
    await _speakTestPhrase(nextRate);
  }

  Future<void> decreaseSpeechRate() async {
    final nextRate = (state.speechRate - 0.05).clamp(0.4, 1.0);
    emit(state.copyWith(speechRate: nextRate));
    await _haptics.successNotification();
    await _assistant.setSpeechRate(nextRate);
    await _speakTestPhrase(nextRate);
  }

  Future<void> _speakTestPhrase(double rate) async {
    final speedMultiplier = (rate * 2).toStringAsFixed(1);
    await _assistant.speak('Speech speed: $speedMultiplier times.');
  }

  // ===========================================================================
  // 🧭 2. منطق الخطوة الثانية: تدريب أذن المستخدم على نغمات البوصلة
  // ===========================================================================

  Future<void> handleTrainingSwipeUp() async {
    await _sound.play(SoundCue.navNorth);
    await _haptics.successNotification();
    emit(state.copyWith(hasMasteredNorthSwipe: true));
    await _assistant.speak(
      'Excellent. That is the North Focus & Alarms chime. Now, swipe down to discover Communications.',
    );
  }

  Future<void> handleTrainingSwipeDown() async {
    await _sound.play(SoundCue.navSouth);
    await _haptics.successNotification();
    emit(state.copyWith(hasMasteredSouthSwipe: true));
    await _assistant.speak(
      'Great job! That is the South Communications chime. '
      'Now pinch your fingers together to test the elevator, or tap continue to proceed.',
    );
  }

  Future<void> handleTrainingPinch() async {
    await _sound.play(SoundCue.elevatorUp);
    await _haptics.emergencyAlarmPulse();
    emit(state.copyWith(hasMasteredPinch: true));
    await _assistant.speak(SpatialGesture.ascendToSettings.spokenPrompt);
  }

  // ===========================================================================
  // 👁️ 3. منطق الخطوة الثالثة: تجربة الكاميرا الذكية
  // ===========================================================================

  Future<void> captureAndTestVision() async {
    if (state.isCameraBusy) return;

    try {
      emit(state.copyWith(isCameraBusy: true, status: BlindFlowStatus.testingVision));

      // 🛡️ 1. فحص مسبق للإذن للتوجيه الصوتي
      final permState = await _camera.getPermissionState();
      if (permState == CameraPermissionState.permanentlyDenied) {
        emit(state.copyWith(isCameraBusy: false, status: BlindFlowStatus.active));
        await _sound.play(SoundCue.error);
        await _haptics.errorAlert();
        await _assistant.speak(
          'Camera permission is permanently denied. Please enable camera in device settings.',
        );
        return;
      }

      // إذا لم يمنح الإذن بعد، ننبه الكفيف صوتياً ليستعد للضغط على نافذة النظام
      if (permState == CameraPermissionState.denied) {
        await _assistant.speak('Please allow camera access on your screen.');
      } else {
        await _sound.play(SoundCue.processing);
        await _haptics.successNotification();
        await _assistant.speak('Inspecting scene with Gemini...');
      }

      final base64 = await _camera.captureAsBase64();
      if (base64 == null || base64.isEmpty) {
        emit(state.copyWith(isCameraBusy: false, status: BlindFlowStatus.active));
        await _sound.play(SoundCue.error);
        await _haptics.errorAlert();
        await _assistant.speak('Camera capture failed or permission was denied. Tap again to retry.');
        return;
      }

      final result = await _assistant.analyzeVisionFrame(
        base64Image: base64,
        prompt:
            'You are the eyes for a blind user. In 1 short sentence, describe what is directly in front of this phone camera.',
      );

      emit(
        state.copyWith(
          isCameraBusy: false,
          visionTestResult: result,
          status: BlindFlowStatus.active,
        ),
      );

      await _sound.play(SoundCue.success);
      await _assistant.speak(result);

      await Future<void>.delayed(const Duration(seconds: 2));
      await _assistant.speak(
        'AI vision is verified. Double tap anywhere to move to the final Safety step.',
      );
    } catch (e, st) {
      log('BlindOnboarding: Vision test error: $e', stackTrace: st);
      emit(state.copyWith(isCameraBusy: false, status: BlindFlowStatus.active));
      await _sound.play(SoundCue.error);
      await _assistant.speak('Could not complete visual inspection. Tap again to retry.');
    }
  }

  // ===========================================================================
  // 🔄 4. التنقل بين الخطوات
  // ===========================================================================

  void nextStep() {
    switch (state.currentStep) {
      case BlindStep.audioTuning:
        goToStep(BlindStep.compassTraining);
        break;
      case BlindStep.compassTraining:
        goToStep(BlindStep.visionTest);
        break;
      case BlindStep.visionTest:
        goToStep(BlindStep.sosSetup);
        break;
      case BlindStep.sosSetup:
        finishBlindOnboarding();
        break;
    }
  }

  void goToStep(BlindStep step) {
    emit(state.copyWith(currentStep: step));
    announceCurrentStep(step);
  }

  Future<void> announceCurrentStep(BlindStep step) async {
    await _sound.stopAll();
    await _assistant.stopSpeaking();

    switch (step) {
      case BlindStep.audioTuning:
        await _assistant.speak(
          'Step 1: Audio Tuning. Tap the top half of the screen to increase reading speed. '
          'Tap the bottom half to decrease. Double tap anywhere with two fingers to confirm.',
        );
        break;

      case BlindStep.compassTraining:
        await _assistant.speak(
          'Step 2: Spatial Navigation Training. '
          'Swipe up now to hear the North Focus chime.',
        );
        break;

      case BlindStep.visionTest:
        await _assistant.speak(
          'Step 3: AI Digital Eyes. Point your phone in front of you and tap anywhere on the screen to perform a test scan.',
        );
        break;

      case BlindStep.sosSetup:
        await _assistant.speak(
          'Final Step: Emergency SOS. Remember: three rapid taps anywhere on screen will trigger your loud emergency radar. '
          'Double tap now with two fingers to enter your spatial cockpit.',
        );
        break;
    }
  }

  // ===========================================================================
  // 🏁 5. إنهاء الإعداد واعتماد الهوية
  // ===========================================================================

  Future<void> finishBlindOnboarding() async {
    emit(state.copyWith(status: BlindFlowStatus.completing));
    try {
      await _settings.completeOnboarding(
        persona: 'blind_accessible',
        isHighContrast: true,
        speechRate: state.speechRate,
      );

      await _sound.play(SoundCue.success);
      await _haptics.emergencyAlarmPulse();
      await _assistant.speak(
        'Beacon OS is fully configured. Welcome home to your Cockpit.',
      );

      emit(state.copyWith(status: BlindFlowStatus.completed));
    } catch (e) {
      emit(
        state.copyWith(
          status: BlindFlowStatus.error,
          errorMessage: 'Failed to complete setup: $e',
        ),
      );
    }
  }
}