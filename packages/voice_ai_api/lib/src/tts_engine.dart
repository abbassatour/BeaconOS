// packages/voice_ai_api/lib/src/tts_engine.dart
import 'package:flutter_tts/flutter_tts.dart';

class TtsEngine {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> initialize() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5); // سرعة مناسبة للمكفوفين (يمكن تسريعها لاحقاً)
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true); // انتظار انتهاء الصوت قبل تنفيذ الكود التالي
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
        .replaceAll(RegExp(r'https?:\/\/\S+'), 'link') // استبدال الروابط بكلمة link
        .trim();
  }
}