// packages/launcher_repository/lib/src/launcher_repository.dart
import 'dart:developer';
import 'package:cloud_sync_api/cloud_sync_api.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:local_vault_api/local_vault_api.dart';
import 'package:system_hardware_api/system_hardware_api.dart';
import 'package:voice_ai_api/voice_ai_api.dart';

/// نتيجة تنفيذ أي أمر تنفيذي أو صوتي داخل نظام BeaconOS
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

/// المايسترو والمنسق المركزي لعمليات النظام (Launcher Repository)
/// يربط بين: عتاد أندرويد + بنك الذاكرة Drift + سحابة Supabase + الذكاء الاصطناعي
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

  // ===========================================================================
  // ☁️ 0. استعادة الخزنة السحابية (Vault Restoration & Sync Down)
  // ===========================================================================

  /// تقوم هذه الدالة بجلب كل بيانات المستخدم من Supabase وحفظها محلياً في Drift
  /// تُستدعى عند تسجيل الدخول أو عند فتح التطبيق والتأكد من وجود إنترنت
  Future<void> restoreVaultFromCloud() async {
    if (!_cloud.isAuthenticated) return;

    try {
      log('LauncherRepository: Starting Vault Restoration from Cloud...');

      // 1. استعادة الإعدادات (Settings)
      final cloudSettings = await _cloud.fetchCloudSettings();
      if (cloudSettings != null) {
        await _db.updateSettings(
          AppSettingsCompanion(
            speechRate: Value(cloudSettings['speech_rate'] as double? ?? 0.5),
            hapticsEnabled: Value(cloudSettings['haptics_enabled'] as bool? ?? true),
            soundCuesEnabled: Value(cloudSettings['sound_cues_enabled'] as bool? ?? true),
            isHighContrast: Value(cloudSettings['is_high_contrast'] as bool? ?? false),
            defaultPriority: Value(cloudSettings['default_priority'] as String? ?? 'medium'),
            autoArchiveCompleted: Value(cloudSettings['auto_archive_completed'] as bool? ?? true),
            speakDueDatesAloud: Value(cloudSettings['speak_due_dates_aloud'] as bool? ?? true),
            autoDialEmergency: Value(cloudSettings['auto_dial_emergency'] as bool? ?? true),
            shareGpsOnSos: Value(cloudSettings['share_gps_on_sos'] as bool? ?? true),
            speakIncomingSms: Value(cloudSettings['speak_incoming_sms'] as bool? ?? true),
            voiceChimeHalfway: Value(cloudSettings['voice_chime_halfway'] as bool? ?? true),
            vibrateOnSessionFinish: Value(cloudSettings['vibrate_on_session_finish'] as bool? ?? true),
            syncAlarmsWithAndroidClock: Value(cloudSettings['sync_alarms_with_android_clock'] as bool? ?? true),
            visionInspectionDetail: Value(cloudSettings['vision_inspection_detail'] as String? ?? 'concise'),
            autoFlashlightInDark: Value(cloudSettings['auto_flashlight_in_dark'] as bool? ?? true),
            preferredCurrency: Value(cloudSettings['preferred_currency'] as String? ?? 'USD / Local'),
            isSynced: const Value(true), // قادمة من السحابة فهي متزامنة
          ),
        );
      }

      // 2. استعادة جهات الاتصال (Contacts)
      final cloudContacts = await _cloud.fetchContacts();
      for (var c in cloudContacts) {
        await _db.into(_db.contacts).insert(
          ContactsCompanion.insert(
            id: c['id'],
            name: c['name'],
            phoneNumber: c['phone_number'],
            relationship: Value(c['relationship']),
            isEmergency: Value(c['is_emergency'] ?? false),
            isSynced: const Value(true),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }

      // 3. استعادة المهام (Tasks)
      final cloudTasks = await _cloud.fetchTasks();
      for (var t in cloudTasks) {
        DateTime? due;
        if (t['due_date'] != null) due = DateTime.tryParse(t['due_date']);
        await _db.into(_db.tasks).insert(
          TasksCompanion.insert(
            id: t['id'],
            title: t['title'],
            dueDate: Value(due),
            priority: Value(t['priority'] ?? 'medium'),
            isCompleted: Value(t['is_completed'] ?? false),
            isSynced: const Value(true),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }

      log('LauncherRepository: Vault Restoration Complete. Device is now in sync.');
    } catch (e, st) {
      log('LauncherRepository: Vault Sync Failed: $e', stackTrace: st);
    }
  }


  // ===========================================================================
  // 🔄 0.1 محرك التعافي والمزامنة بالخلفية (Offline Recovery & Pending Sync)
  // ===========================================================================

  /// تُستدعى هذه الدالة لاكتشاف التغييرات المحلية التي تمت بدون إنترنت ورفعها للسحابة
  Future<void> syncPendingOfflineChanges() async {
    if (!_cloud.isAuthenticated) return;

    try {
      log('LauncherRepository: Starting Background Sync for offline changes...');

      // 1. مزامنة المهام المعلقة (Tasks)
      final pendingTasks = await (_db.select(_db.tasks)..where((t) => t.isSynced.equals(false))).get();
      for (var t in pendingTasks) {
        if (t.deletedAt != null) {
          await _cloud.softDeleteTaskInCloud(t.id);
          await _db.deleteTask(t.id); // تنظيف الجهاز محلياً بعد نجاح الحذف السحابي
        } else {
          await _cloud.syncTask(
            id: t.id,
            title: t.title,
            dueDate: t.dueDate,
            priority: t.priority,
            isCompleted: t.isCompleted,
          );
          // تمييز كمتزامن محلياً
          await (_db.update(_db.tasks)..where((tbl) => tbl.id.equals(t.id)))
              .write(const TasksCompanion(isSynced: Value(true)));
        }
      }

      // 2. مزامنة المذكرات المعلقة (Voice Memos)
      final pendingMemos = await (_db.select(_db.voiceMemos)..where((m) => m.isSynced.equals(false))).get();
      for (var m in pendingMemos) {
        if (m.deletedAt != null) {
          await _cloud.softDeleteMemoInCloud(m.id);
          await _db.deleteMemo(m.id);
        } else {
          await _cloud.syncMemo(id: m.id, title: m.title, content: m.content);
          await (_db.update(_db.voiceMemos)..where((tbl) => tbl.id.equals(m.id)))
              .write(const VoiceMemosCompanion(isSynced: Value(true)));
        }
      }

      // 3. مزامنة جهات الاتصال المعلقة (Contacts)
      final pendingContacts = await (_db.select(_db.contacts)..where((c) => c.isSynced.equals(false))).get();
      for (var c in pendingContacts) {
        if (c.deletedAt != null) {
          await _cloud.softDeleteContactInCloud(c.id);
          await _db.deleteContact(c.id);
        } else {
          await _cloud.syncContact(
            id: c.id,
            name: c.name,
            phoneNumber: c.phoneNumber,
            relationship: c.relationship,
            isEmergency: c.isEmergency,
          );
          await (_db.update(_db.contacts)..where((tbl) => tbl.id.equals(c.id)))
              .write(const ContactsCompanion(isSynced: Value(true)));
        }
      }

      // 4. مزامنة المنبهات المعلقة (Alarms)
      final pendingAlarms = await (_db.select(_db.alarms)..where((a) => a.isSynced.equals(false))).get();
      for (var a in pendingAlarms) {
        if (a.deletedAt != null) {
          await _cloud.softDeleteAlarmInCloud(a.id);
          await _db.deleteAlarm(a.id);
        } else {
          await _cloud.syncAlarm(
            id: a.id,
            hour: a.hour,
            minute: a.minute,
            label: a.label,
            daysOfWeek: a.daysOfWeek,
            isActive: a.isActive,
          );
          await (_db.update(_db.alarms)..where((tbl) => tbl.id.equals(a.id)))
              .write(const AlarmsCompanion(isSynced: Value(true)));
        }
      }

      // 5. مزامنة الإعدادات إذا تم تعديلها أوفلاين
      final settings = await _db.getSettings();
      if (!settings.isSynced) {
        await _cloud.syncSettings({
          'id': settings.id,
          'speech_rate': settings.speechRate,
          'haptics_enabled': settings.hapticsEnabled,
          'sound_cues_enabled': settings.soundCuesEnabled,
          'is_high_contrast': settings.isHighContrast,
          'default_priority': settings.defaultPriority,
          'auto_archive_completed': settings.autoArchiveCompleted,
          'speak_due_dates_aloud': settings.speakDueDatesAloud,
          'auto_dial_emergency': settings.autoDialEmergency,
          'share_gps_on_sos': settings.shareGpsOnSos,
          'speak_incoming_sms': settings.speakIncomingSms,
          'voice_chime_halfway': settings.voiceChimeHalfway,
          'vibrate_on_session_finish': settings.vibrateOnSessionFinish,
          'sync_alarms_with_android_clock': settings.syncAlarmsWithAndroidClock,
          'vision_inspection_detail': settings.visionInspectionDetail,
          'auto_flashlight_in_dark': settings.autoFlashlightInDark,
          'preferred_currency': settings.preferredCurrency,
        });
        await _db.updateSettings(const AppSettingsCompanion(isSynced: Value(true)));
      }

      log('LauncherRepository: Background Offline Sync Completed Successfully.');
    } catch (e, st) {
      log('LauncherRepository: Background Sync encountered an error: $e', stackTrace: st);
    }
  }




  // ===========================================================================
  // 🎙️ 1. محركات الصوت والكلام (Speech & TTS)
  // ===========================================================================

  Future<void> initializeEngines() async {
    await _speech.initialize();
    await _tts.initialize();
    try {
      final settings = await _db.getSettings();
      await setSpeechRate(settings.speechRate);
    } catch (_) {}
  }

  Future<void> setSpeechRate(double rate) async {
    // سرعة مناسبة للمكفوفين
  }

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

  Future<String> stopListening() => _speech.stopListening();
  Future<void> speak(String text) => _tts.speak(text);
  Future<void> stopSpeaking() => _tts.stop();

  // ===========================================================================
  // ⚙️ 2. إدارة الإعدادات الشاملة (AppSettings Engine)
  // ===========================================================================

  Stream<AppSetting> watchSettings() => _db.watchSettings();
  Future<AppSetting> getSettings() => _db.getSettings();

  Future<void> updateSettings(AppSettingsCompanion updated) async {
    await _db.updateSettings(updated);

    final current = await _db.getSettings();
    await _cloud.syncSettings({
      'id': current.id,
      'speech_rate': current.speechRate,
      'haptics_enabled': current.hapticsEnabled,
      'sound_cues_enabled': current.soundCuesEnabled,
      'is_high_contrast': current.isHighContrast,
      'default_priority': current.defaultPriority,
      'auto_archive_completed': current.autoArchiveCompleted,
      'speak_due_dates_aloud': current.speakDueDatesAloud,
      'auto_dial_emergency': current.autoDialEmergency,
      'share_gps_on_sos': current.shareGpsOnSos,
      'speak_incoming_sms': current.speakIncomingSms,
      'voice_chime_halfway': current.voiceChimeHalfway,
      'vibrate_on_session_finish': current.vibrateOnSessionFinish,
      'sync_alarms_with_android_clock': current.syncAlarmsWithAndroidClock,
      'vision_inspection_detail': current.visionInspectionDetail,
      'auto_flashlight_in_dark': current.autoFlashlightInDark,
      'preferred_currency': current.preferredCurrency,
    });
  }

  // ===========================================================================
  // 📇 3. جهات الاتصال ورادار الطوارئ (Contacts)
  // ===========================================================================

  Future<String> saveContact({
    required String name,
    required String phoneNumber,
    String? relationship,
    bool isEmergency = false,
  }) async {
    final id = await _db.insertContact(
      name: name,
      phoneNumber: phoneNumber,
      relationship: relationship,
      isEmergency: isEmergency,
    );

    await _cloud.syncContact(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      relationship: relationship,
      isEmergency: isEmergency,
    );
    return id;
  }

  Future<void> deleteContact(dynamic contactOrId) async {
    final String id = contactOrId is Contact ? contactOrId.id : contactOrId.toString();
    await _db.softDeleteContact(id);
    await _cloud.softDeleteContactInCloud(id);
  }

  Stream<List<Contact>> watchContacts() => _db.watchAllContacts();
  Future<List<Contact>> getEmergencyContacts() => _db.getEmergencyContacts();
  Future<Contact?> findContact(String query) => _db.findContactByNameOrRelation(query);

  // ===========================================================================
  // 💬 4. سجل التراسل الصامت (Messages Vault)
  // ===========================================================================

  Future<String> recordMessage({
    required String contactIdentifier,
    required String senderName,
    required String messageText,
    String platform = 'sms',
    bool isOutgoing = false,
  }) async {
    final id = await _db.insertMessage(
      contactIdentifier: contactIdentifier,
      senderName: senderName,
      messageText: messageText,
      platform: platform,
      isOutgoing: isOutgoing,
    );

    await _cloud.syncMessage(
      id: id,
      contactIdentifier: contactIdentifier,
      senderName: senderName,
      messageText: messageText,
      platform: platform,
      isOutgoing: isOutgoing,
    );
    return id;
  }

  Stream<List<MessagesVaultData>> watchMessages(String contactIdentifier) =>
      _db.watchMessagesForContact(contactIdentifier);

  Future<List<MessagesVaultData>> getUnreadMessages() => _db.getUnreadMessages();

  Future<void> markMessagesAsRead(String contactIdentifier) async {
    await _db.markMessagesAsRead(contactIdentifier);
    await _cloud.markMessagesAsReadInCloud(contactIdentifier);
  }

  // ===========================================================================
  // 📋 5. المهام والأجندة (Tasks & Agenda)
  // ===========================================================================

  Stream<List<Task>> watchTasks() => _db.watchAllTasks();

  Future<String> createTask({
    required String title,
    DateTime? dueDate,
    String priority = 'medium',
  }) async {
    final id = await _db.insertTask(
      title: title,
      dueDate: dueDate,
      priority: priority,
    );
    await _cloud.syncTask(
      id: id,
      title: title,
      dueDate: dueDate,
      priority: priority,
    );
    return id;
  }

  Future<void> toggleTask(Task task) async {
    final nextStatus = !task.isCompleted;
    await _db.toggleTaskCompletion(task.id, nextStatus);
    await _cloud.syncTask(
      id: task.id,
      title: task.title,
      dueDate: task.dueDate,
      priority: task.priority,
      isCompleted: nextStatus,
    );
  }

  Future<void> deleteTask(dynamic taskOrId) async {
    final String id = taskOrId is Task ? taskOrId.id : taskOrId.toString();
    await _db.softDeleteTask(id);
    await _cloud.softDeleteTaskInCloud(id);
  }

  // ===========================================================================
  // 🎙️ 6. المذكرات والملاحظات الصوتية (Voice Memos)
  // ===========================================================================

  Stream<List<VoiceMemo>> watchMemos() => _db.watchRecentMemos();

  Future<String> createMemo({
    required String title,
    required String content,
  }) async {
    final id = await _db.insertMemo(title: title, content: content);
    await _cloud.syncMemo(id: id, title: title, content: content);
    return id;
  }

  Future<void> deleteMemo(dynamic memoOrId) async {
    final String id = memoOrId is VoiceMemo ? memoOrId.id : memoOrId.toString();
    await _db.softDeleteMemo(id);
    await _cloud.softDeleteMemoInCloud(id);
  }

  // ===========================================================================
  // ⏰ 7. المنبهات وجلسات التركيز (Alarms & Focus)
  // ===========================================================================

  Stream<List<Alarm>> watchAlarms() => _db.watchAllAlarms();

  Future<String> createAlarm({
    required int hour,
    required int minute,
    String label = 'Beacon Alarm',
  }) async {
    final id = await _db.insertAlarm(hour: hour, minute: minute, label: label);
    await _hardware.setSystemAlarm(hour: hour, minute: minute, label: label);
    await _cloud.syncAlarm(id: id, hour: hour, minute: minute, label: label);
    return id;
  }

  Future<void> toggleAlarm(Alarm alarm) async {
    final newStatus = !alarm.isActive;
    await _db.toggleAlarmStatus(alarm.id, newStatus);
    if (newStatus) {
      await _hardware.setSystemAlarm(
        hour: alarm.hour,
        minute: alarm.minute,
        label: alarm.label,
      );
    }
    await _cloud.syncAlarm(
      id: alarm.id,
      hour: alarm.hour,
      minute: alarm.minute,
      label: alarm.label,
      isActive: newStatus,
    );
  }

  Future<void> deleteAlarm(dynamic alarmOrId) async {
    final String id = alarmOrId is Alarm ? alarmOrId.id : alarmOrId.toString();
    await _db.softDeleteAlarm(id);
    await _cloud.softDeleteAlarmInCloud(id);
  }

  Stream<List<FocusSession>> watchTodayFocusSessions() =>
      _db.watchTodayFocusSessions();

  Future<void> recordCompletedFocusSession(int minutes) async {
    final id = await _db.insertFocusSession(minutes);
    await _cloud.syncFocusSession(id: id, durationMinutes: minutes);
  }

  // ===========================================================================
  // 🚨 8. رادار الطوارئ وبث الاستغاثة (Emergency SOS Radar)
  // ===========================================================================

  Future<void> triggerEmergencySos({
    required double latitude,
    required double longitude,
    int? batteryLevel,
  }) async {
    final googleMapsUrl = 'https://maps.google.com/?q=$latitude,$longitude';
    final alertId = await _db.insertSosAlert(
      latitude: latitude,
      longitude: longitude,
      batteryLevel: batteryLevel ?? 100,
      googleMapsUrl: googleMapsUrl,
    );

    await _cloud.broadcastEmergencySos(
      id: alertId,
      latitude: latitude,
      longitude: longitude,
      batteryLevel: batteryLevel ?? 100,
    );

    final emergencyContacts = await _db.getEmergencyContacts();
    if (emergencyContacts.isNotEmpty) {
      final primary = emergencyContacts.first;
      log('LauncherRepository: Auto-dialing emergency contact: ${primary.name}');
      await _hardware.callPhoneNumber(primary.phoneNumber);
    }
  }

  // ===========================================================================
  // 👁️ 9. استوديو الرؤية المكانية (Vision Scans)
  // ===========================================================================

  Future<String> analyzeVisionFrame({
    required String base64Image,
    required String prompt,
  }) async {
    final result = await _llm.processCommand(
      userCommand: prompt,
      base64Image: base64Image,
    );
    return result['spoken_response'] as String? ?? 'Could not identify the scene.';
  }

  Future<void> saveVisionScanAsMemo({
    required String title,
    required String description,
    String mode = 'surroundings',
  }) async {
    final scanId = await _db.insertVisionScan(
      mode: mode,
      prompt: title,
      description: description,
    );
    await _cloud.syncVisionScan(
      id: scanId,
      mode: mode,
      prompt: title,
      description: description,
    );
    await createMemo(title: title, content: description);
  }

  // ===========================================================================
  // 🧠 10. موجه الأوامر التنفيذية الفوري (Voice & Action Dispatcher)
  // ===========================================================================

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

    // -------------------------------------------------------------
    // مسار الاستجابة اللحظية أوفلاين (Sub-5ms Local Dispatch)
    // -------------------------------------------------------------

    // 1. فحص محلي فوري للمنبه
    if (cleanQuery.contains('alarm')) {
      final match = RegExp(r'(\d{1,2})(?::(\d{2}))?').firstMatch(cleanQuery);
      if (match != null) {
        var hour = int.tryParse(match.group(1) ?? '8') ?? 8;
        final minute = int.tryParse(match.group(2) ?? '0') ?? 0;

        if (cleanQuery.contains('pm') && hour < 12) hour += 12;
        if (cleanQuery.contains('am') && hour == 12) hour = 0;

        await createAlarm(hour: hour, minute: minute, label: 'Beacon Alarm');
        final timeDisplay =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        return LauncherCommandResult(
          intent: 'SET_ALARM',
          spokenResponse: 'Alarm has been set for $timeDisplay.',
        );
      }
    }

    // 2. الكشاف (Flashlight)
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

    // 3. قفل الشاشة والنوم الهادئ
    if (cleanQuery.contains('lock screen') ||
        cleanQuery.contains('turn off screen') ||
        cleanQuery == 'sleep' ||
        cleanQuery == 'lock') {
      await _hardware.lockScreen();
      return const LauncherCommandResult(
        intent: 'LOCK_SCREEN',
        spokenResponse: 'Locking screen.',
      );
    }

    // 4. إطلاق التطبيقات
    if (cleanQuery.startsWith('open ') || cleanQuery.startsWith('launch ')) {
      final targetApp = cleanQuery
          .replaceFirst(RegExp(r'^(open|launch)\s+'), '')
          .trim();
      final package = _knownAppPackages[targetApp] ?? targetApp;
      final launched = await _hardware.openApp(package);
      return LauncherCommandResult(
        intent: 'OPEN_APP',
        spokenResponse: launched
            ? 'Opening $targetApp.'
            : 'Could not find or launch $targetApp.',
      );
    }

    // 5. الاتصال الهاتفي الذكي بالاسم أو صلة القرابة (مثل: "call dad", "call doctor")
    if (cleanQuery.startsWith('call ') || cleanQuery.startsWith('dial ')) {
      final target = cleanQuery
          .replaceFirst(RegExp(r'^(call|dial)\s+'), '')
          .trim();

      final contact = await _db.findContactByNameOrRelation(target);
      final numberToCall = contact != null ? contact.phoneNumber : target;
      final displayName = contact != null ? contact.name : target;

      final called = await _hardware.callPhoneNumber(numberToCall);
      return LauncherCommandResult(
        intent: 'CALL_PHONE',
        spokenResponse: called
            ? 'Calling $displayName.'
            : 'Unable to place a call to $displayName.',
        actionPayload: {'name': displayName, 'phoneNumber': numberToCall},
      );
    }

    // 6. إضافة جهة اتصال صوتياً (مثال: "save contact dad 0551234567")
    if (cleanQuery.startsWith('save contact ') ||
        cleanQuery.startsWith('add contact ')) {
      final raw = userQuery
          .replaceFirst(
            RegExp(r'^(save contact|add contact)\s+', caseSensitive: false),
            '',
          )
          .trim();
      final match = RegExp(r'^(.*?)\s+([0-9\+\-\s]{5,})$').firstMatch(raw);
      if (match != null) {
        final name = match.group(1)!.trim();
        final phone = match.group(2)!.replaceAll(RegExp(r'\s+'), '');
        await saveContact(name: name, phoneNumber: phone);
        return LauncherCommandResult(
          intent: 'SAVE_CONTACT',
          spokenResponse: 'Contact $name saved.',
          actionPayload: {'name': name, 'phoneNumber': phone},
        );
      }
    }

    // 7. قراءة الرسائل غير المقروءة (Headless Messages Digest)
    if (cleanQuery.contains('read messages') ||
        cleanQuery.contains('check messages') ||
        cleanQuery == 'messages') {
      final unread = await _db.getUnreadMessages();
      if (unread.isEmpty) {
        return const LauncherCommandResult(
          intent: 'READ_MESSAGES',
          spokenResponse: 'You have no unread messages.',
        );
      }
      final buffer = StringBuffer(
        'You have ${unread.length} new message${unread.length > 1 ? 's' : ''}: ',
      );
      for (var i = 0; i < unread.length && i < 3; i++) {
        buffer.write(
          'From ${unread[i].senderName}: ${unread[i].messageText}. ',
        );
      }
      return LauncherCommandResult(
        intent: 'READ_MESSAGES',
        spokenResponse: buffer.toString().trim(),
        actionPayload: unread,
      );
    }

    // 8. الوقت والتاريخ
    if (cleanQuery.contains('time') ||
        cleanQuery.contains('clock') ||
        cleanQuery == 'date') {
      final now = DateTime.now();
      final timeStr = DateFormat('h:mm a, EEEE').format(now);
      return LauncherCommandResult(
        intent: 'TIME',
        spokenResponse: 'The time is $timeStr.',
      );
    }

    // 9. مستوى البطارية
    if (cleanQuery.contains('battery') || cleanQuery.contains('charge')) {
      final batteryStatus = await _hardware.getBatteryStatus();
      return LauncherCommandResult(
        intent: 'BATTERY',
        spokenResponse: batteryStatus,
      );
    }

    // 10. قراءة المهام
    if (cleanQuery.contains('my tasks') ||
        cleanQuery.contains('what are my tasks') ||
        cleanQuery.contains('read tasks')) {
      final pending = await _db.getPendingTasks();
      if (pending.isEmpty) {
        return const LauncherCommandResult(
          intent: 'READ_TASKS',
          spokenResponse:
              'You have no pending tasks. Your day is completely clear.',
        );
      }
      final buffer = StringBuffer(
        'You have ${pending.length} pending task${pending.length > 1 ? 's' : ''}: ',
      );
      for (var i = 0; i < pending.length; i++) {
        buffer.write('Task ${i + 1}: ${pending[i].title}. ');
      }
      return LauncherCommandResult(
        intent: 'READ_TASKS',
        spokenResponse: buffer.toString().trim(),
      );
    }

    // 11. حفظ مهمة سريعة
    if (cleanQuery.startsWith('remind me to') ||
        cleanQuery.startsWith('task:')) {
      final title = userQuery
          .replaceFirst(
            RegExp(r'^(remind me to|task:)\s*', caseSensitive: false),
            '',
          )
          .trim();
      await createTask(title: title);
      return LauncherCommandResult(
        intent: 'SAVE_TASK',
        spokenResponse: 'Task saved: $title.',
      );
    }

    // 12. حفظ مذكرة سريعة (Note/Memo)
    if (cleanQuery.startsWith('note:') ||
        cleanQuery.startsWith('take a note') ||
        cleanQuery.startsWith('memo:')) {
      final content = userQuery
          .replaceFirst(
            RegExp(r'^(note:|take a note|memo:)\s*', caseSensitive: false),
            '',
          )
          .trim();
      final title = content.length > 25
          ? '${content.substring(0, 25)}...'
          : content;
      await createMemo(title: title, content: content);
      return LauncherCommandResult(
        intent: 'SAVE_MEMO',
        spokenResponse: 'Note saved: $title.',
      );
    }

    // -------------------------------------------------------------
    // مسار الذكاء الاصطناعي مع حقن السياق (Gemini + Context Injection)
    // -------------------------------------------------------------
    final currentTasks = await _db.getPendingTasks();
    final currentAlarms = await _db.watchAllAlarms().first;
    final currentSettings = await _db.getSettings();

    final systemContext = {
      'tasks': currentTasks
          .map((t) => {'id': t.id, 'title': t.title, 'priority': t.priority})
          .toList(),
      'alarms': currentAlarms
          .map((a) => {
                'id': a.id,
                'time': '${a.hour}:${a.minute}',
                'active': a.isActive,
                'label': a.label
              })
          .toList(),
      'settings': {
        'speech_rate': currentSettings.speechRate,
        'haptics_enabled': currentSettings.hapticsEnabled,
        'is_high_contrast': currentSettings.isHighContrast,
        'vision_detail': currentSettings.visionInspectionDetail,
      },
    };

    final aiResult = await _llm.processCommand(
      userCommand: userQuery,
      base64Image: base64Image,
      systemContext: systemContext,
    );

    final intent = aiResult['intent'] as String? ?? 'GENERAL_CHAT';
    final spokenResponse =
        aiResult['spoken_response'] as String? ?? 'Command processed.';

    final dynamic rawParams = aiResult['parameters'];
    final Map<String, dynamic> params = rawParams is Map
        ? Map<String, dynamic>.from(rawParams)
        : <String, dynamic>{};

    // تنفيذ قرارات الذكاء الاصطناعي
    switch (intent) {
      case 'SAVE_TASK':
        final title = params['title'] as String? ?? userQuery;
        DateTime? dueDate;
        if (params['due_date'] != null) {
          dueDate = DateTime.tryParse(params['due_date'] as String);
        }
        final priority = params['priority'] as String? ?? 'medium';
        await createTask(title: title, dueDate: dueDate, priority: priority);
        break;

      case 'COMPLETE_TASK':
        final taskId = params['task_id'] as String?;
        if (taskId != null) {
          await _db.toggleTaskCompletion(taskId, true);
          await _cloud.syncTask(id: taskId, title: '', isCompleted: true);
        }
        break;

      case 'DELETE_TASK':
        final taskId = params['task_id'] as String?;
        if (taskId != null) {
          await deleteTask(taskId);
        }
        break;

      case 'SAVE_MEMO':
        final title = params['title'] as String? ?? 'Voice Note';
        final content = params['content'] as String? ?? title;
        await createMemo(title: title, content: content);
        break;

      case 'DELETE_MEMO':
        final memoId = params['memo_id'] as String?;
        if (memoId != null) {
          await deleteMemo(memoId);
        }
        break;

      case 'SET_ALARM':
        final timeStr = params['time'] as String?;
        if (timeStr != null && timeStr.contains(':')) {
          final parts = timeStr.split(':');
          final hour = int.tryParse(parts[0]) ?? 8;
          final minute = int.tryParse(parts[1]) ?? 0;
          final label = params['label'] as String? ?? 'Beacon Alarm';
          await createAlarm(hour: hour, minute: minute, label: label);
        }
        break;

      case 'TOGGLE_ALARM':
        final alarmId = params['alarm_id'] as String?;
        final isActive = params['is_active'] as bool? ?? false;
        if (alarmId != null) {
          await _db.toggleAlarmStatus(alarmId, isActive);
          await _cloud.syncAlarm(
            id: alarmId,
            hour: 0,
            minute: 0,
            label: '',
            isActive: isActive,
          );
        }
        break;

      case 'DELETE_ALARM':
        final alarmId = params['alarm_id'] as String?;
        if (alarmId != null) {
          await deleteAlarm(alarmId);
        }
        break;

      case 'CALL_CONTACT':
        final target = params['contact_name'] as String? ?? '';
        if (target.isNotEmpty) {
          final contact = await _db.findContactByNameOrRelation(target);
          final numberToCall = contact != null ? contact.phoneNumber : target;
          await _hardware.callPhoneNumber(numberToCall);
        }
        break;

      case 'SAVE_CONTACT':
        final name = params['name'] as String? ?? '';
        final phone = params['phone_number'] as String? ?? '';
        final relation = params['relationship'] as String?;
        final isEmergency = params['is_emergency'] as bool? ?? false;
        if (name.isNotEmpty && phone.isNotEmpty) {
          await saveContact(
            name: name,
            phoneNumber: phone,
            relationship: relation,
            isEmergency: isEmergency,
          );
        }
        break;

      case 'DELETE_CONTACT':
        final contactId = params['contact_id'] as String?;
        if (contactId != null) {
          await deleteContact(contactId);
        }
        break;

      case 'UPDATE_SETTINGS':
        final key = params['key'] as String?;
        final val = params['value'];
        if (key != null && val != null) {
          if (key == 'speech_rate' && val is num) {
            await updateSettings(
              AppSettingsCompanion(speechRate: Value(val.toDouble())),
            );
          } else if (key == 'haptics_enabled' && val is bool) {
            await updateSettings(
              AppSettingsCompanion(hapticsEnabled: Value(val)),
            );
          } else if (key == 'is_high_contrast' && val is bool) {
            await updateSettings(
              AppSettingsCompanion(isHighContrast: Value(val)),
            );
          } else if (key == 'auto_flashlight_in_dark' && val is bool) {
            await updateSettings(
              AppSettingsCompanion(autoFlashlightInDark: Value(val)),
            );
          } else if (key == 'vision_inspection_detail' && val is String) {
            await updateSettings(
              AppSettingsCompanion(visionInspectionDetail: Value(val)),
            );
          }
        }
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
}