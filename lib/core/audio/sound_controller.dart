// lib/core/audio/sound_controller.dart
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';

class SoundController {
  SoundController._() {
    _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    // مشغل مخصص لأصوات السحب والملاحة لمنع تقطيع أصوات النظام الأساسية
    _navPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop); 
  }

  static final SoundController instance = SoundController._();
  
  late final AudioPlayer _player;
  late final AudioPlayer _navPlayer;

  // ===========================================================================
  // 🎙️ أصوات واجهة الأوامر الأساسية (Zero-UI Cues)
  // ===========================================================================

  Future<void> playListeningCue() async {
    await _safePlay('audio/wake.mp3', volume: 0.6);
  }

  Future<void> playProcessingCue() async {
    await _safePlay('audio/processing.mp3', volume: 0.5);
  }

  Future<void> playSuccessCue() async {
    await _safePlay('audio/success.mp3', volume: 0.7);
  }

  Future<void> playErrorCue() async {
    await _safePlay('audio/error.mp3', volume: 0.8);
  }

  Future<void> playSosAlarm() async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _safePlay('audio/sos.mp3', volume: 1.0);
    } catch (e) {
      log('SOS Sound bypass: $e');
    }
  }

  // ===========================================================================
  // 🧭 أصوات الملاحة المكانية (Spatial Navigation Sounds)
  // ===========================================================================

  Future<void> playSwipeNorth({bool isSettingsFloor = false}) async {
    await _playNavCue('audio/nav_north.mp3', isSettingsFloor: isSettingsFloor);
  }

  Future<void> playSwipeSouth({bool isSettingsFloor = false}) async {
    await _playNavCue('audio/nav_south.mp3', isSettingsFloor: isSettingsFloor);
  }

  Future<void> playSwipeEast({bool isSettingsFloor = false}) async {
    await _playNavCue('audio/nav_east.mp3', isSettingsFloor: isSettingsFloor);
  }

  Future<void> playSwipeWest({bool isSettingsFloor = false}) async {
    await _playNavCue('audio/nav_west.mp3', isSettingsFloor: isSettingsFloor);
  }

  Future<void> playReturnCenter({bool isSettingsFloor = false}) async {
    await _playNavCue('audio/nav_center.mp3', isSettingsFloor: isSettingsFloor, volume: 0.6);
  }

  // ===========================================================================
  // 🏢 أصوات التنقل الرأسي (Elevator Sounds)
  // ===========================================================================

  Future<void> playElevatorUp() async {
    // صوت الصعود للطابق الثاني (إعدادات)
    await _playNavCue('audio/elevator_up.mp3', volume: 0.8, isSettingsFloor: false);
  }

  Future<void> playElevatorDown() async {
    // صوت النزول للطابق الأرضي (الغرف الأساسية)
    await _playNavCue('audio/elevator_down.mp3', volume: 0.8, isSettingsFloor: false);
  }

  // ===========================================================================
  // ⚙️ المعالجات الداخلية (Internal Handlers)
  // ===========================================================================

  Future<void> _safePlay(String assetPath, {double volume = 1.0}) async {
    try {
      await _player.stop();
      await _player.setVolume(volume);
      await _player.setPlaybackRate(1.0); // الوضع الافتراضي
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      log('Sound cue skipped or missing asset: $assetPath ($e)');
    }
  }

  /// دالة تشغيل أصوات الملاحة مع دعم تعديل الحدة والسرعة (Pitch & Rate Shift)
  Future<void> _playNavCue(String assetPath, {bool isSettingsFloor = false, double volume = 0.5}) async {
    try {
      await _navPlayer.stop();
      await _navPlayer.setVolume(volume);
      
      // السحر هنا: إذا كنا في طابق الإعدادات، نرفع السرعة إلى 1.4
      // هذا يجعل الصوت أقصر وأكثر حدّة ليعطي إحساس "الطابق العلوي" دون الحاجة لملف صوتي مختلف!
      final double rate = isSettingsFloor ? 1.4 : 1.0;
      await _navPlayer.setPlaybackRate(rate);
      
      await _navPlayer.play(AssetSource(assetPath));
    } catch (e) {
      log('Navigation cue skipped or missing asset: $assetPath ($e)');
    }
  }

  Future<void> stop() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.stop();
      await _navPlayer.stop();
    } catch (e) {
      log('Error stopping audio: $e');
    }
  }

  void dispose() {
    _player.dispose();
    _navPlayer.dispose();
  }
}