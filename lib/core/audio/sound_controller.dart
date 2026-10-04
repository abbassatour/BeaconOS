// lib/core/audio/sound_controller.dart
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:flutter/widgets.dart';

class SoundController {
  SoundController._() {
    _primaryPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    _navPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  }

  static final SoundController instance = SoundController._();

  late final AudioPlayer _primaryPlayer;
  late final AudioPlayer _navPlayer;

  /// تشغيل أي نغمة مع حساب التردد الرأسي متعدد الطوابق
  Future<void> play(
    SoundCue cue, {
    int floorLevel = 0,
    bool isSettingsFloor = false, // للتوافق العكسي
    double? volumeOverride,
  }) async {
    final isNav = cue.allowFloorPitchShift ||
        cue.name.startsWith('nav') ||
        cue.name.startsWith('elevator');
    final player = isNav ? _navPlayer : _primaryPlayer;

    try {
      await player.stop();
      await player.setReleaseMode(
        cue.isLooping ? ReleaseMode.loop : ReleaseMode.stop,
      );
      await player.setVolume(volumeOverride ?? cue.volume);

      // 🌟 حساب النبرة الصوتية بمعادلة رياضية متصلة للأبعاد المتعددة
      final effectiveFloor = isSettingsFloor ? 1 : floorLevel;
      final playbackRate = cue.allowFloorPitchShift
          ? (1.0 + (effectiveFloor * 0.2)).clamp(0.5, 2.0)
          : 1.0;

      await player.setPlaybackRate(playbackRate);
      await player.play(AssetSource(cue.path));
    } catch (e) {
      log('SoundController: Failed to play [${cue.name}]: $e');
    }
  }

  Future<void> stopAll() async {
    try {
      await _primaryPlayer.stop();
      await _navPlayer.stop();
    } catch (e) {
      log('SoundController: Error stopping audio: $e');
    }
  }

  void dispose() {
    _primaryPlayer.dispose();
    _navPlayer.dispose();
  }
}

extension SoundContextX on BuildContext {
  SoundController get sounds => SoundController.instance;

  void playSound(
    SoundCue cue, {
    int floorLevel = 0,
    bool isSettingsFloor = false,
  }) {
    SoundController.instance.play(
      cue,
      floorLevel: floorLevel,
      isSettingsFloor: isSettingsFloor,
    );
  }
}