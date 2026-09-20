// packages/launcher_repository/lib/src/launcher_repository.dart
import 'dart:developer';
import 'package:cloud_sync_api/cloud_sync_api.dart';
import 'package:drift/drift.dart';
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

  // -- تهيئة المحركات --
  Future<void> initializeEngines() async {
    await _speech.initialize();
    await _tts.initialize();
  }

  // -- عمليات الصوت المباشرة --
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

  // -- معالجة الأوامر الصوتية وتحويلها إلى أفعال نظام --
  Future<LauncherCommandResult> dispatchVoiceCommand(
    String userQuery, {
    String? base64Image,
  }) async {
    final cleanQuery = userQuery.trim();
    if (cleanQuery.isEmpty) {
      return const LauncherCommandResult(
        intent: 'EMPTY',
        spokenResponse: 'I did not catch that. Please speak again.',
      );
    }

    // 1. إرسال الصوت للذكاء الاصطناعي لفهم النية عبر JSON
    final aiResult = await _llm.processCommand(
      userCommand: cleanQuery,
      base64Image: base64Image,
    );

    final intent = aiResult['intent'] as String? ?? 'GENERAL_CHAT';
    final spokenResponse = aiResult['spoken_response'] as String? ?? 'Command processed.';
    final params = (aiResult['parameters'] as Map<String, dynamic>?) ?? {};

    log('LauncherRepository: Intent identified: $intent with params: $params');

    // 2. تنفيذ الأمر على النظام بحسب نوع النية
    switch (intent) {
      case 'SAVE_TASK':
        final title = params['task_title'] as String? ?? cleanQuery;
        DateTime? due;
        if (params['due_date'] != null) {
          due = DateTime.tryParse(params['due_date'].toString());
        }
        await _db.insertTask(TasksCompanion.insert(
          title: title,
          dueDate: Value(due),
        ));
        _cloud.backupTask(title: title, dueDate: due);
        break;

      case 'SAVE_MEMO':
        final title = params['memo_title'] as String? ?? 'Quick Memo';
        final content = params['memo_content'] as String? ?? cleanQuery;
        await _db.insertMemo(VoiceMemosCompanion.insert(
          title: title,
          content: content,
        ));
        _cloud.backupMemo(title: title, content: content);
        break;

      case 'SET_ALARM':
        final timeStr = params['time'] as String?;
        if (timeStr != null && timeStr.contains(':')) {
          final parts = timeStr.split(':');
          final hour = int.tryParse(parts[0]) ?? 8;
          final minute = int.tryParse(parts[1]) ?? 0;
          await _hardware.setSystemAlarm(hour: hour, minute: minute);
        }
        break;

      case 'CALL_CONTACT':
        final target = params['contact_name'] as String? ?? '';
        await _hardware.callPhoneNumber(target);
        break;

      case 'LOCK_SCREEN':
        await _hardware.lockScreen();
        break;

      case 'READ_NOTIFICATIONS':
        final unread = await _db.getUnreadNotifications();
        if (unread.isEmpty) {
          return const LauncherCommandResult(
            intent: 'READ_NOTIFICATIONS',
            spokenResponse: 'You have no new notifications. Your day is clear and quiet.',
          );
        }
        await _db.markAllNotificationsAsRead();
        final summary = unread.map((n) => '${n.appName}: ${n.content}').join('. ');
        return LauncherCommandResult(
          intent: 'READ_NOTIFICATIONS',
          spokenResponse: 'Here is your notification digest: $summary',
        );

      case 'VISUAL_QUERY':
      case 'GENERAL_CHAT':
      default:
        break;
    }

    return LauncherCommandResult(
      intent: intent,
      spokenResponse: spokenResponse,
      actionPayload: params,
    );
  }

  // -- نظام الطوارئ SOS الفوري --
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