// packages/launcher_repository/lib/src/launcher_repository.dart
import 'dart:developer';
import 'package:cloud_sync_api/cloud_sync_api.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:local_vault_api/local_vault_api.dart';
import 'package:system_hardware_api/system_hardware_api.dart';
import 'package:voice_ai_api/voice_ai_api.dart';

class LauncherCommandResult {
  const LauncherCommandResult({
    required this.intent,
    required this.spokenResponse,
    this.actionPayload,
  });

  final String intent;
  final String spokenResponse;
  final dynamic actionPayload;
}

class LauncherRepository {
  LauncherRepository({
    AppDatabase? database,
    SpeechEngine? speechEngine,
    TtsEngine? ttsEngine,
    LlmAgent? llmAgent,
    HardwareClient? hardwareClient,
    CloudSyncClient? cloudSyncClient,
  })  : _db = database ?? AppDatabase(),
        _speech = speechEngine ?? SpeechEngine(),
        _tts = ttsEngine ?? TtsEngine(),
        _llm = llmAgent ?? LlmAgent(openRouterApiKey: ''),
        _hardware = hardwareClient ?? HardwareClient(),
        _cloud = cloudSyncClient ?? CloudSyncClient();

  final AppDatabase _db;
  final SpeechEngine _speech;
  final TtsEngine _tts;
  final LlmAgent _llm;
  final HardwareClient _hardware;
  final CloudSyncClient _cloud;

  Future<void> initializeEngines() async {
    await _speech.initialize();
    await _tts.initialize();
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(double level)? onSoundLevel,
  }) async {
    await _tts.stop();
    await _speech.startListening(onResult: onResult, onSoundLevel: onSoundLevel);
  }

  Future<String> stopListening() async {
    return _speech.stopListening();
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  /// معالجة الأوامر الصوتية: تبدأ بالفحص المحلي السريع (Zero-Latency)، ثم الذكاء الاصطناعي
  Future<LauncherCommandResult> dispatchVoiceCommand(
    String userQuery, {
    String? base64Image,
  }) async {
    final cleanQuery = userQuery.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return const LauncherCommandResult(
        intent: 'EMPTY',
        spokenResponse: 'I am listening. Please speak your command.',
      );
    }

    // 1. فحص محلي فوري للوقت (يعمل بدون إنترنت)
    if (cleanQuery.contains('time') || cleanQuery.contains('clock') || cleanQuery == 'date') {
      final now = DateTime.now();
      final timeStr = DateFormat('h:mm a, EEEE').format(now);
      return LauncherCommandResult(
        intent: 'TIME',
        spokenResponse: 'The time is $timeStr.',
      );
    }

    // 2. فحص محلي فوري للبطارية
    if (cleanQuery.contains('battery') || cleanQuery.contains('charge')) {
      final batteryStatus = await _hardware.getBatteryStatus();
      return LauncherCommandResult(
        intent: 'BATTERY',
        spokenResponse: batteryStatus,
      );
    }

    // 3. فحص محلي لقراءة المهام المسجلة اليوم
    if (cleanQuery.contains('my tasks') || cleanQuery.contains('what are my tasks') || cleanQuery.contains('read tasks')) {
      final pending = await _db.getPendingTasks();
      if (pending.isEmpty) {
        return const LauncherCommandResult(
          intent: 'READ_TASKS',
          spokenResponse: 'You have no pending tasks. Your day is completely clear.',
        );
      }
      final buffer = StringBuffer('You have ${pending.length} pending task${pending.length > 1 ? 's' : ''}: ');
      for (var i = 0; i < pending.length; i++) {
        buffer.write('Task ${i + 1}: ${pending[i].title}. ');
      }
      return LauncherCommandResult(
        intent: 'READ_TASKS',
        spokenResponse: buffer.toString().trim(),
      );
    }

    // 4. حفظ سريع للمهام (محلياً)
    if (cleanQuery.startsWith('remind me to') || cleanQuery.startsWith('task:')) {
      final title = userQuery.replaceFirst(RegExp(r'^(remind me to|task:)\s*', caseSensitive: false), '').trim();
      await _db.insertTask(TasksCompanion.insert(title: title));
      _cloud.backupTask(title: title);
      return LauncherCommandResult(
        intent: 'SAVE_TASK',
        spokenResponse: 'Task saved to your local vault: $title.',
      );
    }

    // 5. حفظ سريع للملاحظات الصوتية (محلياً)
    if (cleanQuery.startsWith('note:') || cleanQuery.startsWith('save note')) {
      final content = userQuery.replaceFirst(RegExp(r'^(note:|save note)\s*', caseSensitive: false), '').trim();
      await _db.insertMemo(VoiceMemosCompanion.insert(
        title: content.length > 20 ? '${content.substring(0, 20)}...' : content,
        content: content,
      ));
      _cloud.backupMemo(title: 'Quick Memo', content: content);
      return LauncherCommandResult(
        intent: 'SAVE_MEMO',
        spokenResponse: 'Voice memo securely stored offline.',
      );
    }

    // 6. التحويل للذكاء الاصطناعي السحابي (Gemini Flash) للأوامر المعقدة
    final aiResult = await _llm.processCommand(
      userCommand: userQuery,
      base64Image: base64Image,
    );

    final intent = aiResult['intent'] as String? ?? 'GENERAL_CHAT';
    final spokenResponse = aiResult['spoken_response'] as String? ?? 'Command processed.';
    final params = (aiResult['parameters'] as Map<String, dynamic>?) ?? {};

    return LauncherCommandResult(
      intent: intent,
      spokenResponse: spokenResponse,
      actionPayload: params,
    );
  }

  Future<void> triggerEmergencySos({
    required double latitude,
    required double longitude,
  }) async {
    await _cloud.broadcastEmergencySos(
      latitude: latitude,
      longitude: longitude,
    );
  }
}