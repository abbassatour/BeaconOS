// lib/onboarding/minimalist_flow/cubit/minimalist_onboarding_state.dart
import 'package:equatable/equatable.dart';

enum MinimalistStep {
  manifesto,     // 1. ميثاق الهدوء والتحرر من إدمان الشاشة
  focusTuning,   // 2. معايرة فترات التركيز والمذاكرة (Pomodoro)
  voiceCockpit,  // 3. تجربة التدوين الصوتي السريع بدون تطبيقات
  launcherSetup, // 4. تعيين BeaconOS كمشغل نظام افتراضي
}

enum MinimalistStatus { initial, active, testingCommand, completing, completed, error }

class MinimalistOnboardingState extends Equatable {
  const MinimalistOnboardingState({
    this.status = MinimalistStatus.initial,
    this.currentStep = MinimalistStep.manifesto,
    this.selectedFocusDurationMinutes = 25, // 25 دقيقة الافتراضية للتركيز
    this.autoArchiveCompletedTasks = true,
    this.testedVoiceResponse = '',
    this.isTestingVoice = false,
    this.errorMessage,
  });

  final MinimalistStatus status;
  final MinimalistStep currentStep;
  final int selectedFocusDurationMinutes;
  final bool autoArchiveCompletedTasks;
  final String testedVoiceResponse;
  final bool isTestingVoice;
  final String? errorMessage;

  MinimalistOnboardingState copyWith({
    MinimalistStatus? status,
    MinimalistStep? currentStep,
    int? selectedFocusDurationMinutes,
    bool? autoArchiveCompletedTasks,
    String? testedVoiceResponse,
    bool? isTestingVoice,
    String? errorMessage,
  }) {
    return MinimalistOnboardingState(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      selectedFocusDurationMinutes:
          selectedFocusDurationMinutes ?? this.selectedFocusDurationMinutes,
      autoArchiveCompletedTasks:
          autoArchiveCompletedTasks ?? this.autoArchiveCompletedTasks,
      testedVoiceResponse: testedVoiceResponse ?? this.testedVoiceResponse,
      isTestingVoice: isTestingVoice ?? this.isTestingVoice,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentStep,
        selectedFocusDurationMinutes,
        autoArchiveCompletedTasks,
        testedVoiceResponse,
        isTestingVoice,
        errorMessage,
      ];
}