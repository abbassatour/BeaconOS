// lib/spatial_vision/cubit/spatial_vision_cubit.dart
import 'dart:developer';
import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:beacon_os/core/services/camera_service.dart';
import 'package:beacon_os/spatial_vision/cubit/spatial_vision_state.dart';
import 'package:bloc/bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class SpatialVisionCubit extends Cubit<SpatialVisionState> {
  SpatialVisionCubit({
    required LauncherRepository repository,
    CameraService? cameraService,
    HapticManager? hapticManager,
    SoundController? soundController,
  })  : _repository = repository,
        _camera = cameraService ?? CameraService.instance,
        _haptics = hapticManager ?? HapticManager.instance,
        _sound = soundController ?? SoundController.instance,
        super(const SpatialVisionState());

  final LauncherRepository _repository;
  final CameraService _camera;
  final HapticManager _haptics;
  final SoundController _sound;

  /// تبديل وضع الفحص
  void setMode(VisionMode mode) {
    emit(state.copyWith(activeMode: mode));
    String announcement;
    switch (mode) {
      case VisionMode.surroundings:
        announcement = 'Surroundings mode.';
        break;
      case VisionMode.textReader:
        announcement = 'Document and Text reader.';
        break;
      case VisionMode.currency:
        announcement = 'Currency identifier.';
        break;
      case VisionMode.productExpiry:
        announcement = 'Product and Expiry inspector.';
        break;
    }
    _repository.speak(announcement);
  }

  /// تبديل كشاف الهاتف للإضاءة في الأماكن المظلمة
  Future<void> toggleTorch() async {
    final next = !state.isTorchOn;
    await _repository.dispatchVoiceCommand(next ? 'turn on flashlight' : 'turn off flashlight');
    emit(state.copyWith(isTorchOn: next));
    _repository.speak(next ? 'Flashlight on.' : 'Flashlight off.');
  }

  /// الالتقاط الفوري والتحليل الذكي بالمحيط
  Future<void> captureAndAnalyze() async {
    if (state.isBusy) return;

    try {
      await _sound.stop();
      await _repository.stopSpeaking();

      // 1. بدء الالتقاط بنبضة تكتيكية وصوت المعالجة
      emit(state.copyWith(status: VisionStatus.capturing));
      await _haptics.successNotification();
      await _sound.playProcessingCue();

      final base64Image = await _camera.captureAsBase64();
      if (base64Image == null || base64Image.isEmpty) {
        emit(state.copyWith(
          status: VisionStatus.error,
          errorMessage: 'Unable to capture frame from camera.',
        ));
        await _repository.speak('Camera capture failed. Please try again.');
        return;
      }

      // 2. إرسال الإطار إلى Gemini 2.0 Flash حسب الوضع المختار
      emit(state.copyWith(status: VisionStatus.analyzing));
      final prompt = _buildPromptForMode(state.activeMode);

      final spokenResult = await _repository.analyzeVisionFrame(
        base64Image: base64Image,
        prompt: prompt,
      );

      // 3. تأكيد النجاح ونطق الإجابة فوراً للكفيف
      await _haptics.successNotification();
      await _sound.playSuccessCue();

      emit(state.copyWith(
        status: VisionStatus.speaking,
        lastSpokenResult: spokenResult,
      ));

      await _repository.speak(spokenResult);
      emit(state.copyWith(status: VisionStatus.idle));
    } catch (e, st) {
      log('SpatialVisionCubit: Error analyzing scene: $e', stackTrace: st);
      emit(state.copyWith(
        status: VisionStatus.error,
        errorMessage: 'Analysis failed. Please try again.',
      ));
      await _haptics.errorAlert();
      await _repository.speak('Visual analysis error. Please try again.');
    }
  }

  /// إعادة نطق آخر وصف
  Future<void> replayDescription() async {
    if (state.lastSpokenResult.isNotEmpty) {
      await _haptics.successNotification();
      await _repository.speak(state.lastSpokenResult);
    }
  }

  /// حفظ النتيجة البصرية كملاحظة دائمة في بنك الذاكرة
  Future<void> saveScanResultAsNote() async {
    if (state.lastSpokenResult.isEmpty) return;

    final title = 'Vision Scan: ${_modeName(state.activeMode)}';
    await _repository.saveVisionScanAsMemo(
      title: title,
      description: state.lastSpokenResult,
    );
    await _haptics.successNotification();
    await _repository.speak('Vision scan saved to notes vault.');
  }

  String _buildPromptForMode(VisionMode mode) {
    switch (mode) {
      case VisionMode.surroundings:
        return 'You are the digital eyes for a blind person. In 1 to 2 clear, concise sentences, describe what is directly in front of them and highlight any immediate obstacles or people.';
      case VisionMode.textReader:
        return 'Read all visible text, document headings, or signs clearly and concisely.';
      case VisionMode.currency:
        return 'Identify the banknotes or coins visible in this image. State the currency name and exact denominations clearly.';
      case VisionMode.productExpiry:
        return 'Identify this product brand and name, and specifically locate any expiration date, best-before date, or ingredients warning.';
    }
  }

  String _modeName(VisionMode mode) {
    switch (mode) {
      case VisionMode.surroundings:
        return 'Surroundings';
      case VisionMode.textReader:
        return 'Document';
      case VisionMode.currency:
        return 'Currency';
      case VisionMode.productExpiry:
        return 'Product';
    }
  }
}