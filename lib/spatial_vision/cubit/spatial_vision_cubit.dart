// lib/spatial_vision/cubit/spatial_vision_cubit.dart
import 'dart:developer';
import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:beacon_os/core/services/camera_service.dart';
import 'package:beacon_os/spatial_vision/cubit/spatial_vision_state.dart';
import 'package:bloc/bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

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

  /// تبديل وضع الفحص مع إشعار صوتي فوري
  Future<void> setMode(VisionMode mode) async {
    if (state.activeMode == mode) return;

    await _sound.stopAll();
    await _repository.stopSpeaking();
    await _haptics.successNotification();
    await _sound.play(SoundCue.navCenter);

    emit(state.copyWith(activeMode: mode));

    String announcement;
    switch (mode) {
      case VisionMode.surroundings:
        announcement = 'Surroundings mode active. Tap anywhere to inspect obstacles.';
        break;
      case VisionMode.textReader:
        announcement = 'Document reader active. Point at paper or sign and tap.';
        break;
      case VisionMode.currency:
        announcement = 'Currency identifier active. Show banknotes or coins.';
        break;
      case VisionMode.productExpiry:
        announcement = 'Product and expiration inspector active.';
        break;
    }
    await _repository.speak(announcement);
  }

  /// تبديل كشاف الهاتف للإضاءة
  Future<void> toggleTorch() async {
    final next = !state.isTorchOn;
    await _haptics.successNotification();
    await _repository.dispatchVoiceCommand(
      next ? 'turn on flashlight' : 'turn off flashlight',
    );
    emit(state.copyWith(isTorchOn: next));
    await _repository.speak(next ? 'Flashlight on.' : 'Flashlight off.');
  }

  /// إيقاف النطق الصوتي فوراً عند نقر الشاشة أثناء القراءة
  Future<void> stopSpeaking() async {
    await _sound.stopAll();
    await _repository.stopSpeaking();
    emit(state.copyWith(status: VisionStatus.idle));
  }

  /// الالتقاط الفوري والتحليل الذكي المتوافق مع إعدادات الطابق الثاني
  Future<void> captureAndAnalyze() async {
    if (state.isBusy) return;

    // إذا كان النظام يتحدث بالفعل، فالنقر يوقفه
    if (state.isSpeaking) {
      await stopSpeaking();
      return;
    }

    try {
      await _sound.stopAll();
      await _repository.stopSpeaking();

      // 1. بدء الالتقاط بنبضة تكتيكية وصوت المعالجة
      emit(state.copyWith(status: VisionStatus.capturing));
      await _haptics.successNotification();
      await _sound.play(SoundCue.processing);

      // قراءة إعدادات الطابق الثاني لتخصيص الذكاء الاصطناعي
      AppSetting? settings;
      try {
        settings = await _repository.getSettings();
      } catch (_) {}

      // تشغيل الكشاف تلقائياً إذا كان الخيار مفعلاً
      final shouldAutoTorch = (settings?.autoFlashlightInDark ?? false) && !state.isTorchOn;
      if (shouldAutoTorch) {
        await _repository.dispatchVoiceCommand('turn on flashlight');
      }

      final base64Image = await _camera.captureAsBase64();

      if (shouldAutoTorch) {
        await _repository.dispatchVoiceCommand('turn off flashlight');
      }

      if (base64Image == null || base64Image.isEmpty) {
        emit(
          state.copyWith(
            status: VisionStatus.error,
            errorMessage: 'Unable to capture frame from camera.',
          ),
        );
        await _sound.play(SoundCue.error);
        await _haptics.errorAlert();
        await _repository.speak('Camera capture failed. Please tap again to retry.');
        return;
      }

      // 2. إرسال الإطار إلى Gemini مع حقن التفضيلات
      emit(state.copyWith(status: VisionStatus.analyzing));
      final prompt = _buildPromptForMode(state.activeMode, settings);

      final spokenResult = await _repository.analyzeVisionFrame(
        base64Image: base64Image,
        prompt: prompt,
      );

      // 3. تأكيد النجاح ونطق الإجابة فوراً للكفيف
      await _haptics.successNotification();
      await _sound.play(SoundCue.success);

      emit(
        state.copyWith(
          status: VisionStatus.speaking,
          lastSpokenResult: spokenResult,
        ),
      );

      await _repository.speak(spokenResult);
      emit(state.copyWith(status: VisionStatus.idle));
    } catch (e, st) {
      log('SpatialVisionCubit: Error analyzing scene: $e', stackTrace: st);
      emit(
        state.copyWith(
          status: VisionStatus.error,
          errorMessage: 'Analysis failed. Please try again.',
        ),
      );
      await _haptics.errorAlert();
      await _sound.play(SoundCue.error);
      await _repository.speak('Visual inspection error. Tap screen to retry.');
    }
  }

  /// إعادة نطق آخر وصف صوتي
  Future<void> replayDescription() async {
    if (state.lastSpokenResult.isNotEmpty) {
      await _haptics.successNotification();
      emit(state.copyWith(status: VisionStatus.speaking));
      await _repository.speak(state.lastSpokenResult);
      emit(state.copyWith(status: VisionStatus.idle));
    }
  }

  /// حفظ النتيجة البصرية كملاحظة دائمة في بنك الذاكرة
  Future<void> saveScanResultAsNote() async {
    if (state.lastSpokenResult.isEmpty || state.isSavingNote) return;

    try {
      emit(state.copyWith(isSavingNote: true));
      final title = 'Vision Scan: ${_modeName(state.activeMode)}';
      await _repository.saveVisionScanAsMemo(
        title: title,
        description: state.lastSpokenResult,
        mode: state.activeMode.name,
      );

      await _haptics.successNotification();
      await _sound.play(SoundCue.success);
      await _repository.speak('Scan result saved to notes vault.');
    } catch (e) {
      await _haptics.errorAlert();
    } finally {
      emit(state.copyWith(isSavingNote: false));
    }
  }

  String _buildPromptForMode(VisionMode mode, AppSetting? settings) {
    final isDetailed = settings?.visionInspectionDetail == 'detailed';
    final currencyPref = settings?.preferredCurrency ?? 'USD / Local';

    switch (mode) {
      case VisionMode.surroundings:
        if (isDetailed) {
          return 'You are the digital eyes for a blind person. Provide a thorough, structured description of the entire scene in front of them: room layout, people, spatial distance to key objects, and any immediate ground hazards.';
        }
        return 'You are the digital eyes for a blind person. In 1 to 2 clear, concise sentences, describe what is directly in front of them and highlight any immediate obstacles or walking hazards.';

      case VisionMode.textReader:
        return 'Read all visible text, document headings, signs, or labels in this image clearly and concisely.';

      case VisionMode.currency:
        return 'Identify the banknotes or coins visible in this image. Pay special attention to $currencyPref. State the exact currency name and total denomination value clearly.';

      case VisionMode.productExpiry:
        return 'Identify this product brand and name, and specifically inspect for any expiration date, best-before date, or ingredients warning.';
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
        return 'Product Expiry';
    }
  }

  @override
  Future<void> close() {
    _sound.stopAll();
    return super.close();
  }
}