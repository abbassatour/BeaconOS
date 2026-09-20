// lib/zero_ui/cubit/zero_ui_cubit.dart
import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:beacon_os/zero_ui/cubit/zero_ui_state.dart';
import 'package:bloc/bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class ZeroUiCubit extends Cubit<ZeroUiState> {
  ZeroUiCubit({
    required LauncherRepository repository,
    HapticManager? hapticManager,
    SoundController? soundController,
  })  : _repository = repository,
        _haptics = hapticManager ?? HapticManager.instance,
        _sound = soundController ?? SoundController.instance,
        super(const ZeroUiState()) {
    _initEngines();
  }

  final LauncherRepository _repository;
  final HapticManager _haptics;
  final SoundController _sound;

  Future<void> _initEngines() async {
    await _repository.initializeEngines();
  }

  /// يبدأ عند وضع المستخدم إصبعه في أي مكان على الشاشة
  Future<void> onTouchStarted() async {
    await _sound.stop();
    await _repository.stopSpeaking();

    _haptics.startListeningPulse();
    await _sound.playListeningCue();

    emit(state.copyWith(
      status: ZeroUiStatus.listening,
      recognizedText: '',
      soundLevel: 0,
    ));

    await _repository.startListening(
      onResult: (words, isFinal) {
        emit(state.copyWith(recognizedText: words));
      },
      onSoundLevel: (level) {
        if ((level - state.soundLevel).abs() > 0.2) {
          emit(state.copyWith(soundLevel: level));
        }
      },
    );
  }

  /// ينطلق عند رفع الإصبع لإرسال الأمر ومعالجته
  Future<void> onTouchReleased() async {
    _haptics.stopListeningPulse();

    final finalWords = await _repository.stopListening();
    final query = finalWords.isNotEmpty ? finalWords : state.recognizedText.trim();

    if (query.isEmpty) {
      await _sound.playErrorCue();
      await _haptics.errorAlert();
      emit(state.copyWith(status: ZeroUiStatus.idle));
      return;
    }

    emit(state.copyWith(
      status: ZeroUiStatus.processing,
      recognizedText: query,
    ));
    await _sound.playProcessingCue();

    // إرسال الأمر للمستودع المركزي للتنفيذ
    final result = await _repository.dispatchVoiceCommand(query);

    await _haptics.successNotification();
    await _sound.playSuccessCue();

    emit(state.copyWith(
      status: ZeroUiStatus.speaking,
      responseText: result.spokenResponse,
    ));

    await _repository.speak(result.spokenResponse);
    emit(state.copyWith(status: ZeroUiStatus.idle));
  }

  /// إعادة نطق آخر إجابة
  Future<void> replayLastResponse() async {
    if (state.responseText.isNotEmpty) {
      await _haptics.successNotification();
      emit(state.copyWith(status: ZeroUiStatus.speaking));
      await _repository.speak(state.responseText);
      emit(state.copyWith(status: ZeroUiStatus.idle));
    }
  }

  /// التبديل بين الوضع المعتم التام (Eyes-Free) والوضع المرئي (Visual HUD)
  void toggleDisplayMode() {
    final nextMode = state.displayMode == DisplayMode.eyesFree
        ? DisplayMode.visualHud
        : DisplayMode.eyesFree;
    _haptics.successNotification();
    emit(state.copyWith(displayMode: nextMode));
  }

  /// تفعيل إشارة الاستغاثة الطارئة SOS
  Future<void> triggerEmergencySos() async {
    emit(state.copyWith(status: ZeroUiStatus.sosTriggered));
    await _haptics.emergencyAlarmPulse();
    await _sound.playSosAlarm();
    await _repository.speak('Emergency SOS broadcasted.');
    
    // إحداثيات افتراضية سيتم تحديثها بموقع الـ GPS لاحقاً
    await _repository.triggerEmergencySos(latitude: 0.0, longitude: 0.0);
  }

  @override
  Future<void> close() {
    _haptics.dispose();
    _sound.dispose();
    return super.close();
  }
}