// packages/launcher_repository/lib/src/launcher_repository.dart
import 'dart:developer';
import 'package:cloud_sync_api/cloud_sync_api.dart';
import 'package:local_vault_api/local_vault_api.dart';
import 'package:system_hardware_api/system_hardware_api.dart';
import 'package:voice_ai_api/voice_ai_api.dart';

import 'domains/assistant_repository.dart';
import 'domains/comms_repository.dart';
import 'domains/focus_alarms_repository.dart';
import 'domains/settings_repository.dart';
import 'domains/system_hardware_repository.dart';
import 'domains/task_agenda_repository.dart';

export 'domains/assistant_repository.dart';
export 'domains/comms_repository.dart';
export 'domains/focus_alarms_repository.dart';
export 'domains/settings_repository.dart';
export 'domains/system_hardware_repository.dart';
export 'domains/task_agenda_repository.dart';

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

/// واجهة النظام المنسقة (Spatial OS Facade / Kernel)
class LauncherRepository {
  LauncherRepository({
    AppDatabase? database,
    CloudSyncClient? cloudSyncClient,
    HardwareClient? hardwareClient,
    SpeechEngine? speechEngine,
    TtsEngine? ttsEngine,
    LlmAgent? llmAgent,
    SettingsRepository? settingsRepository,
    TaskAgendaRepository? taskAgendaRepository,
    FocusAlarmsRepository? focusAlarmsRepository,
    SystemHardwareRepository? hardwareRepository,
    CommsRepository? commsRepository,
    AssistantRepository? assistantRepository,
  }) {
    final db = database ?? AppDatabase();
    final cloud = cloudSyncClient ?? CloudSyncClient();
    final hw = hardwareClient ?? HardwareClient();

    settings = settingsRepository ?? SettingsRepositoryImpl(database: db, cloudSync: cloud);
    tasks = taskAgendaRepository ?? TaskAgendaRepositoryImpl(database: db, cloudSync: cloud);
    focusAlarms = focusAlarmsRepository ?? FocusAlarmsRepositoryImpl(database: db, cloudSync: cloud, hardware: hw);
    hardware = hardwareRepository ?? SystemHardwareRepositoryImpl(hardwareClient: hw);
    comms = commsRepository ?? CommsRepositoryImpl(database: db, cloudSync: cloud, hardware: hw);
    assistant = assistantRepository ?? AssistantRepositoryImpl(speechEngine: speechEngine, ttsEngine: ttsEngine, llmAgent: llmAgent);
  }

  // --- الوصول المباشر للمستودعات الستة ---
  late final SettingsRepository settings;
  late final TaskAgendaRepository tasks;
  late final FocusAlarmsRepository focusAlarms;
  late final SystemHardwareRepository hardware;
  late final CommsRepository comms;
  late final AssistantRepository assistant;

  // 🔗 مأخذ توجيه الأوامر الصوتية الذكية (Pluggable Dispatcher Hook)
  Future<LauncherCommandResult> Function(String userQuery, {String? base64Image})? _customVoiceDispatcher;

  void registerVoiceDispatcher(
    Future<LauncherCommandResult> Function(String userQuery, {String? base64Image}) dispatcher,
  ) {
    _customVoiceDispatcher = dispatcher;
    log('LauncherRepository: Custom VoiceCommandDispatcher registered successfully.');
  }

  // ===========================================================================
  // 🔄 العمليات السيادية المنسقة بين عدة نطاقات (Cross-Domain Operations)
  // ===========================================================================

  Future<void> restoreVaultFromCloud() async {
    log('BeaconKernel: Restoring full vault from cloud...');
    await settings.restoreSettingsFromCloud();
    await comms.restoreCommsFromCloud();
    await tasks.restoreTasksAndMemosFromCloud();
    log('BeaconKernel: Full vault restoration finished.');
  }

  Future<void> syncPendingOfflineChanges() async {
    log('BeaconKernel: Syncing pending changes...');
    await settings.syncPendingSettings();
    await tasks.syncPendingTasksAndMemos();
    await focusAlarms.syncPendingAlarms();
    await comms.syncPendingComms();
    log('BeaconKernel: Offline sync cycle finished.');
  }

  // ===========================================================================
  // ⚡ التوافق التام مع الشاشات الحالية دون كسر أي شاشة (Backward-Compatible Forwarding)
  // ===========================================================================
  Future<void> initializeEngines() => assistant.initializeEngines();
  Future<void> speak(String text) => assistant.speak(text);
  Future<void> stopSpeaking() => assistant.stopSpeaking();
  Future<void> setSpeechRate(double rate) => assistant.setSpeechRate(rate);
  Future<void> startListening({required Function(String text, bool isFinal) onResult, Function(double level)? onSoundLevel}) =>
      assistant.startListening(onResult: onResult, onSoundLevel: onSoundLevel);
  Future<String> stopListening() => assistant.stopListening();
  Future<String> analyzeVisionFrame({required String base64Image, required String prompt}) =>
      assistant.analyzeVisionFrame(base64Image: base64Image, prompt: prompt);

  Stream<AppSetting> watchSettings() => settings.watchSettings();
  Future<AppSetting> getSettings() => settings.getSettings();
  Future<void> updateSettings(AppSettingsCompanion updated) => settings.updateSettings(updated);
  Future<void> completeOnboarding({required String persona, required bool isHighContrast, required double speechRate}) =>
      settings.completeOnboarding(persona: persona, isHighContrast: isHighContrast, speechRate: speechRate);

  Stream<List<Task>> watchTasks() => tasks.watchTasks();
  Future<String> createTask({required String title, DateTime? dueDate, String priority = 'medium'}) =>
      tasks.createTask(title: title, dueDate: dueDate, priority: priority);
  Future<void> toggleTask(Task task) => tasks.toggleTask(task);
  Future<void> deleteTask(dynamic taskOrId) => tasks.deleteTask(taskOrId);

  Stream<List<VoiceMemo>> watchMemos() => tasks.watchMemos();
  Future<String> createMemo({required String title, required String content}) =>
      tasks.createMemo(title: title, content: content);
  Future<void> deleteMemo(dynamic memoOrId) => tasks.deleteMemo(memoOrId);

  Stream<List<Alarm>> watchAlarms() => focusAlarms.watchAlarms();
  Future<String> createAlarm({required int hour, required int minute, String label = 'Beacon Alarm'}) =>
      focusAlarms.createAlarm(hour: hour, minute: minute, label: label);
  Future<void> toggleAlarm(Alarm alarm) => focusAlarms.toggleAlarm(alarm);
  Future<void> deleteAlarm(dynamic alarmOrId) => focusAlarms.deleteAlarm(alarmOrId);
  Stream<List<FocusSession>> watchTodayFocusSessions() => focusAlarms.watchTodayFocusSessions();
  Future<void> recordCompletedFocusSession(int minutes) => focusAlarms.recordCompletedFocusSession(minutes);

  Stream<List<Contact>> watchContacts() => comms.watchContacts();
  Future<List<Contact>> getEmergencyContacts() => comms.getEmergencyContacts();
  Future<Contact?> findContact(String query) => comms.findContact(query);
  Future<String> saveContact({required String name, required String phoneNumber, String? relationship, bool isEmergency = false}) =>
      comms.saveContact(name: name, phoneNumber: phoneNumber, relationship: relationship, isEmergency: isEmergency);
  Future<void> deleteContact(dynamic contactOrId) => comms.deleteContact(contactOrId);
  Future<List<MessagesVaultData>> getUnreadMessages() => comms.getUnreadMessages();
  Future<void> markMessagesAsRead(String contactIdentifier) => comms.markMessagesAsRead(contactIdentifier);

  Future<void> triggerEmergencySos({required double latitude, required double longitude, int? batteryLevel}) async {
    await comms.triggerEmergencySos(latitude: latitude, longitude: longitude, batteryLevel: batteryLevel);
  }

  Future<void> saveVisionScanAsMemo({required String title, required String description, String mode = 'surroundings'}) async {
    await tasks.createMemo(title: title, content: description);
  }

  // موزع الأوامر: يوجه إلى الحافلة الذكية إن وُجدت، أو يسلك المسار الاحتياطي
  Future<LauncherCommandResult> dispatchVoiceCommand(String userQuery, {String? base64Image}) async {
    if (_customVoiceDispatcher != null) {
      return _customVoiceDispatcher!(userQuery, base64Image: base64Image);
    }

    final result = await assistant.processLlmCommand(userCommand: userQuery, base64Image: base64Image);
    final response = result['spoken_response'] as String? ?? 'Done.';
    return LauncherCommandResult(intent: result['intent'] as String? ?? 'GENERAL', spokenResponse: response);
  }
}