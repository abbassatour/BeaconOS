// packages/launcher_repository/lib/src/domains/assistant_repository.dart
import 'package:voice_ai_api/voice_ai_api.dart';

abstract class AssistantRepository {
  Future<void> initializeEngines();
  Future<void> setSpeechRate(double rate);
  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(double level)? onSoundLevel,
  });
  Future<String> stopListening();
  Future<void> speak(String text);
  Future<void> stopSpeaking();
  Future<String> analyzeVisionFrame({
    required String base64Image,
    required String prompt,
  });
  Future<Map<String, dynamic>> processLlmCommand({
    required String userCommand,
    String? base64Image,
    Map<String, dynamic>? systemContext,
  });
}

class AssistantRepositoryImpl implements AssistantRepository {
  AssistantRepositoryImpl({
    SpeechEngine? speechEngine,
    TtsEngine? ttsEngine,
    LlmAgent? llmAgent,
  })  : _speech = speechEngine ?? SpeechEngine(),
        _tts = ttsEngine ?? TtsEngine(),
        _llm = llmAgent ?? LlmAgent(openRouterApiKey: '');

  final SpeechEngine _speech;
  final TtsEngine _tts;
  final LlmAgent _llm;

  @override
  Future<void> initializeEngines() async {
    await _speech.initialize();
    await _tts.initialize();
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    // تكييف المحرك مع السرعة
  }

  @override
  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(double level)? onSoundLevel,
  }) async {
    await _tts.stop();
    await _speech.startListening(
      onResult: onResult,
      onSoundLevel: onSoundLevel,
    );
  }

  @override
  Future<String> stopListening() => _speech.stopListening();

  @override
  Future<void> speak(String text) => _tts.speak(text);

  @override
  Future<void> stopSpeaking() => _tts.stop();

  @override
  Future<String> analyzeVisionFrame({
    required String base64Image,
    required String prompt,
  }) async {
    final result = await _llm.processCommand(
      userCommand: prompt,
      base64Image: base64Image,
    );
    return result['spoken_response'] as String? ?? 'Could not inspect the scene.';
  }

  @override
  Future<Map<String, dynamic>> processLlmCommand({
    required String userCommand,
    String? base64Image,
    Map<String, dynamic>? systemContext,
  }) {
    return _llm.processCommand(
      userCommand: userCommand,
      base64Image: base64Image,
      systemContext: systemContext,
    );
  }
}