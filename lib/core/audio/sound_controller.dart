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

  /// تشغيل أي نغمة من الكتالوج المركزي مع ضبط التردد ومستوى الصوت تلقائياً
  Future<void> play(
    SoundCue cue, {
    bool isSettingsFloor = false,
    double? volumeOverride,
  }) async {
    final isNav = cue.allowFloorPitchShift || cue.name.startsWith('nav') || cue.name.startsWith('elevator');
    final player = isNav ? _navPlayer : _primaryPlayer;

    try {
      await player.stop();

      // ضبط وضع التكرار
      await player.setReleaseMode(cue.isLooping ? ReleaseMode.loop : ReleaseMode.stop);

      // ضبط الصوت
      await player.setVolume(volumeOverride ?? cue.volume);

      // ضبط التردد للطابق الثاني
      final playbackRate = (cue.allowFloorPitchShift && isSettingsFloor) ? 1.4 : 1.0;
      await player.setPlaybackRate(playbackRate);

      await player.play(AssetSource(cue.path));
    } catch (e) {
      log('SoundController: Failed to play [${cue.name}] from path "${cue.path}": $e');
    }
  }

  /// إيقاف جميع المشغلات
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

/// ⚡️ Extension سريع مثل `context.l10n` تماماً
extension SoundContextX on BuildContext {
  SoundController get sounds => SoundController.instance;

  void playSound(SoundCue cue, {bool isSettingsFloor = false}) {
    SoundController.instance.play(cue, isSettingsFloor: isSettingsFloor);
  }
}