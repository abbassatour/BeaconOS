// lib/onboarding/blind_flow/cubit/blind_onboarding_state.dart
import 'package:equatable/equatable.dart';

/// الخطوات الأربع لمسار الكفيف
enum BlindStep {
  audioTuning,      // 1. ضبط سرعة النطق والنبضات اللمسية
  compassTraining,  // 2. تدريب أذن المستخدم على نغمات البوصلة
  visionTest,       // 3. تجربة عملية للكاميرا الذكية (Gemini Vision)
  sosSetup,         // 4. تفعيل رادار الطوارئ وإيماءة النقر الثلاثي
}

enum BlindFlowStatus { initial, active, testingVision, completing, completed, error }

class BlindOnboardingState extends Equatable {
  const BlindOnboardingState({
    this.status = BlindFlowStatus.initial,
    this.currentStep = BlindStep.audioTuning,
    this.speechRate = 0.65, // سرعة افتراضية مريحة للكفيف (أسرع قليلاً من العادي)
    this.hasMasteredNorthSwipe = false,
    this.hasMasteredSouthSwipe = false,
    this.hasMasteredPinch = false,
    this.visionTestResult = '',
    this.isCameraBusy = false,
    this.errorMessage,
  });

  final BlindFlowStatus status;
  final BlindStep currentStep;
  final double speechRate;

  // مؤشرات إتقان إيماءات البوصلة في الخطوة 2
  final bool hasMasteredNorthSwipe;
  final bool hasMasteredSouthSwipe;
  final bool hasMasteredPinch;

  // نتيجة اختبار الكاميرا في الخطوة 3
  final String visionTestResult;
  final bool isCameraBusy;

  final String? errorMessage;

  bool get isCompassTrainingDone =>
      hasMasteredNorthSwipe && hasMasteredSouthSwipe;

  BlindOnboardingState copyWith({
    BlindFlowStatus? status,
    BlindStep? currentStep,
    double? speechRate,
    bool? hasMasteredNorthSwipe,
    bool? hasMasteredSouthSwipe,
    bool? hasMasteredPinch,
    String? visionTestResult,
    bool? isCameraBusy,
    String? errorMessage,
  }) {
    return BlindOnboardingState(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      speechRate: speechRate ?? this.speechRate,
      hasMasteredNorthSwipe:
          hasMasteredNorthSwipe ?? this.hasMasteredNorthSwipe,
      hasMasteredSouthSwipe:
          hasMasteredSouthSwipe ?? this.hasMasteredSouthSwipe,
      hasMasteredPinch: hasMasteredPinch ?? this.hasMasteredPinch,
      visionTestResult: visionTestResult ?? this.visionTestResult,
      isCameraBusy: isCameraBusy ?? this.isCameraBusy,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentStep,
        speechRate,
        hasMasteredNorthSwipe,
        hasMasteredSouthSwipe,
        hasMasteredPinch,
        visionTestResult,
        isCameraBusy,
        errorMessage,
      ];
}