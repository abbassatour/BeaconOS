// lib/zero_ui/cubit/zero_ui_cubit.dart
import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:beacon_os/core/services/camera_service.dart';
import 'package:beacon_os/zero_ui/cubit/zero_ui_state.dart';
import 'package:bloc/bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class ZeroUiCubit extends Cubit<ZeroUiState> {
  ZeroUiCubit({
    required LauncherRepository repository,
    HapticManager? hapticManager,
    SoundController? soundController,
    CameraService? cameraService,
  }) : _repository = repository,
       _haptics = hapticManager ?? HapticManager.instance,
       _sound = soundController ?? SoundController.instance,
       _camera = cameraService ?? CameraService.instance,
       super(const ZeroUiState()) {
    _initEngines();
  }

  final LauncherRepository _repository;
  final HapticManager _haptics;
  final SoundController _sound;
  final CameraService _camera;

  Future<void> _initEngines() async {
    await _repository.initializeEngines();
  }

  Future<void> onTouchStarted() async {
    await _sound.stopAll();
    await _repository.stopSpeaking();

    _haptics.startListeningPulse();
    await _sound.play(SoundCue.wake);

    emit(
      state.copyWith(
        status: ZeroUiStatus.listening,
        recognizedText: '',
        soundLevel: 0,
      ),
    );

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

  Future<void> onTouchReleased() async {
    _haptics.stopListeningPulse();

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final finalWords = await _repository.stopListening();
    final query = finalWords.isNotEmpty
        ? finalWords
        : state.recognizedText.trim();

    if (query.isEmpty) {
      await submitQuery("What is in front of me?");
      return;
    }

    await submitQuery(query);
  }

  bool _isVisualQuery(String query) {
    final text = query.toLowerCase();
    return text.contains('look') ||
        text.contains('see') ||
        text.contains('front of me') ||
        text.contains('read') ||
        text.contains('what is this') ||
        text.contains('describe') ||
        text.contains('color');
  }

  Future<void> submitQuery(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    await _sound.stopAll();
    await _repository.stopSpeaking();

    emit(
      state.copyWith(
        status: ZeroUiStatus.processing,
        recognizedText: clean,
      ),
    );
    await _sound.play(SoundCue.processing);

    String? base64Image;
    if (_isVisualQuery(clean)) {
      base64Image = await _camera.captureAsBase64();
    }

    final result = await _repository.dispatchVoiceCommand(
      clean,
      base64Image: base64Image,
    );

    await _haptics.successNotification();
    await _sound.play(SoundCue.success);

    emit(
      state.copyWith(
        status: ZeroUiStatus.speaking,
        responseText: result.spokenResponse,
      ),
    );

    await _repository.speak(result.spokenResponse);
    emit(state.copyWith(status: ZeroUiStatus.idle));
  }

  Future<void> replayLastResponse() async {
    if (state.responseText.isNotEmpty) {
      await _haptics.successNotification();
      emit(state.copyWith(status: ZeroUiStatus.speaking));
      await _repository.speak(state.responseText);
      emit(state.copyWith(status: ZeroUiStatus.idle));
    }
  }

  void toggleDisplayMode() {
    final nextMode = state.displayMode == DisplayMode.eyesFree
        ? DisplayMode.visualHud
        : DisplayMode.eyesFree;
    _haptics.successNotification();
    emit(state.copyWith(displayMode: nextMode));
  }

  Future<void> triggerEmergencySos() async {
    emit(state.copyWith(status: ZeroUiStatus.sosTriggered));
    await _haptics.emergencyAlarmPulse();
    await _sound.play(SoundCue.sosAlarm);
    await _repository.speak('Emergency SOS broadcasted.');
    await _repository.triggerEmergencySos(latitude: 0.0, longitude: 0.0);
  }

  @override
  Future<void> close() {
    _haptics.dispose();
    _sound.stopAll(); // 🛡️ إيقاف الأصوات فقط دون تدمير الـ Singleton
    _camera.dispose();
    return super.close();
  }
}