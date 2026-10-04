// packages/voice_ai_api/lib/src/tts_engine.dart
import 'package:flutter_tts/flutter_tts.dart';

class TtsEngine {
  final FlutterTts _flutterTts = FlutterTts();
  double _currentRate = 0.5;

  double get currentRate => _currentRate;

  Future<void> initialize() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(_currentRate);
    await _flutterTts.setPitch(1.0);
    // انتظار انتهاء الصوت قبل تنفيذ الكود التالي لمنع التداخل
    await _flutterTts.awaitSpeakCompletion(true);
  }

  /// ⚡️ ضبط سرعة النطق الحقيقية فورياً
  Future<void> setSpeechRate(double rate) async {
    _currentRate = rate.clamp(0.2, 1.0);
    await _flutterTts.setSpeechRate(_currentRate);
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await stop();

    // تنظيف النص من علامات Markdown ليكون النطق طبيعياً
    final cleanText = _sanitizeForSpeech(text);
    await _flutterTts.speak(cleanText);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  String _sanitizeForSpeech(String raw) {
    return raw
        .replaceAll(RegExp(r'\*\*|\*|__|_|`|#+'), '') // إزالة النجمات والشرطات
        .replaceAll(
          RegExp(r'https?:\/\/\S+'),
          'link',
        ) // استبدال الروابط بكلمة link
        .trim();
  }
}