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

  static const Map<String, String> _knownAppPackages = {
    'whatsapp': 'com.whatsapp',
    'youtube': 'com.google.android.youtube',
    'chrome': 'com.android.chrome',
    'browser': 'com.android.chrome',
    'settings': 'com.android.settings',
    'camera': 'com.google.android.GoogleCamera',
    'spotify': 'com.spotify.music',
    'telegram': 'org.telegram.messenger',
    'gmail': 'com.google.android.gm',
    'maps': 'com.google.android.apps.maps',
    'phone': 'com.google.android.dialer',
  };

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

    // 1. فحص محلي فوري للمنبه
    if (cleanQuery.contains('alarm')) {
      final match = RegExp(r'(\d{1,2})(?::(\d{2}))?').firstMatch(cleanQuery);
      if (match != null) {
        var hour = int.tryParse(match.group(1) ?? '8') ?? 8;
        final minute = int.tryParse(match.group(2) ?? '0') ?? 0;

        if (cleanQuery.contains('pm') && hour < 12) hour += 12;
        if (cleanQuery.contains('am') && hour == 12) hour = 0;

        await _hardware.setSystemAlarm(hour: hour, minute: minute, label: 'Beacon Alarm');
        final timeDisplay = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        return LauncherCommandResult(
          intent: 'SET_ALARM',
          spokenResponse: 'Alarm has been set for $timeDisplay.',
        );
      }
    }

    // 2. فحص محلي للكشاف
    if (cleanQuery.contains('flashlight') || cleanQuery.contains('torch')) {
      final enable = !cleanQuery.contains('off');
      final success = await _hardware.toggleFlashlight(enable: enable);
      return LauncherCommandResult(
        intent: 'FLASHLIGHT',
        spokenResponse: success
            ? (enable ? 'Flashlight turned on.' : 'Flashlight turned off.')
            : 'Unable to toggle flashlight right now.',
      );
    }

    // 3. قفل الشاشة
    if (cleanQuery.contains('lock screen') || cleanQuery.contains('turn off screen') || cleanQuery == 'sleep' || cleanQuery == 'lock') {
      await _hardware.lockScreen();
      return const LauncherCommandResult(
        intent: 'LOCK_SCREEN',
        spokenResponse: 'Locking screen.',
      );
    }

    // 4. فتح التطبيقات
    if (cleanQuery.startsWith('open ') || cleanQuery.startsWith('launch ')) {
      final targetApp = cleanQuery.replaceFirst(RegExp(r'^(open|launch)\s+'), '').trim();
      final package = _knownAppPackages[targetApp] ?? targetApp;
      final launched = await _hardware.openApp(package);
      return LauncherCommandResult(
        intent: 'OPEN_APP',
        spokenResponse: launched ? 'Opening $targetApp.' : 'Could not find or launch $targetApp.',
      );
    }

    // 5. الاتصال الهاتفي
    if (cleanQuery.startsWith('call ') || cleanQuery.startsWith('dial ')) {
      final target = cleanQuery.replaceFirst(RegExp(r'^(call|dial)\s+'), '').trim();
      final called = await _hardware.callPhoneNumber(target);
      return LauncherCommandResult(
        intent: 'CALL_PHONE',
        spokenResponse: called ? 'Calling $target.' : 'Unable to place a call to $target.',
      );
    }

    // 6. الوقت
    if (cleanQuery.contains('time') || cleanQuery.contains('clock') || cleanQuery == 'date') {
      final now = DateTime.now();
      final timeStr = DateFormat('h:mm a, EEEE').format(now);
      return LauncherCommandResult(
        intent: 'TIME',
        spokenResponse: 'The time is $timeStr.',
      );
    }

    // 7. البطارية
    if (cleanQuery.contains('battery') || cleanQuery.contains('charge')) {
      final batteryStatus = await _hardware.getBatteryStatus();
      return LauncherCommandResult(
        intent: 'BATTERY',
        spokenResponse: batteryStatus,
      );
    }

    // 8. قراءة المهام
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

    // 9. حفظ المهام
    if (cleanQuery.startsWith('remind me to') || cleanQuery.startsWith('task:')) {
      final title = userQuery.replaceFirst(RegExp(r'^(remind me to|task:)\s*', caseSensitive: false), '').trim();
      await _db.insertTask(TasksCompanion.insert(title: title));
      _cloud.backupTask(title: title);
      return LauncherCommandResult(
        intent: 'SAVE_TASK',
        spokenResponse: 'Task saved: $title.',
      );
    }

    // 10. إرسال الأوامر المعقدة لـ Gemini Flash
    final aiResult = await _llm.processCommand(
      userCommand: userQuery,
      base64Image: base64Image,
    );

    final intent = aiResult['intent'] as String? ?? 'GENERAL_CHAT';
    final spokenResponse = aiResult['spoken_response'] as String? ?? 'Command processed.';

    final dynamic rawParams = aiResult['parameters'];
    final Map<String, dynamic> params = rawParams is Map
        ? Map<String, dynamic>.from(rawParams)
        : <String, dynamic>{};

    switch (intent) {
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

      case 'FLASHLIGHT':
        final enable = params['enable'] as bool? ?? true;
        await _hardware.toggleFlashlight(enable: enable);
        break;

      case 'OPEN_APP':
        final app = params['app_name'] as String? ?? '';
        final package = _knownAppPackages[app.toLowerCase()] ?? app;
        await _hardware.openApp(package);
        break;
    }

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