// lib/core/audio/sound_controller.dart
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';

class SoundController {
  SoundController._() {
    _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  }

  static final SoundController instance = SoundController._();
  late final AudioPlayer _player;

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

  Future<void> stop() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.stop();
    } catch (e) {
      log('Error stopping audio: $e');
    }
  }

  Future<void> _safePlay(String assetPath, {double volume = 1.0}) async {
    try {
      await _player.stop();
      await _player.setVolume(volume);
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      log('Sound cue skipped or missing asset: $assetPath ($e)');
    }
  }

  void dispose() {
    _player.dispose();
  }
}