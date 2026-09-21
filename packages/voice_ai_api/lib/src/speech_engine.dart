// packages/voice_ai_api/lib/src/speech_engine.dart
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechEngine {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speechToText.initialize(
      onError: (error) => print('Speech Error: ${error.errorMsg}'),
      debugLogging: false,
    );
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(double level)? onSoundLevel,
  }) async {
    if (!_isInitialized) await initialize();

    // إيقاف أي استماع سابق
    if (_speechToText.isListening) await _speechToText.stop();

    await _speechToText.listen(
      onResult: (result) =>
          onResult(result.recognizedWords, result.finalResult),
      onSoundLevelChange: onSoundLevel,
      listenMode: ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
      pauseFor: const Duration(
        seconds: 4,
      ), // انتظار 4 ثواني من الصمت لإنهاء الكلام
    );
  }

  Future<String> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return _speechToText.lastRecognizedWords;
  }

  bool get isListening => _speechToText.isListening;
}
