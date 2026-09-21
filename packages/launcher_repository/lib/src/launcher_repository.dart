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
  }) : _db = database ?? AppDatabase(),
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
  // 🎙️ 1. محركات الصوت والكلام (Speech & TTS)
  // ===========================================================================

  Future<void> initializeEngines() async {
    await _speech.initialize();
    await _tts.initialize();
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

  Future<String> stopListening() async {
    return _speech.stopListening();
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  // ===========================================================================
  // 📇 2. إدارة جهات الاتصال ورادار الطوارئ (Contacts & Emergency Hub)
  // ===========================================================================

  /// حفظ جهة اتصال جديدة (محلياً وسحابياً)
  Future<void> saveContact({
    required String name,
    required String phoneNumber,
    String? relationship,
    bool isEmergency = false,
  }) async {
    await _db.insertContact(
      ContactsCompanion.insert(
        name: name,
        phoneNumber: phoneNumber,
        relationship: Value(relationship),
        isEmergency: Value(isEmergency),
      ),
    );

    // رفع خلفي إلى Supabase
    await _cloud.syncContact(
      name: name,
      phoneNumber: phoneNumber,
      relationship: relationship,
      isEmergency: isEmergency,
    );
  }

  /// حذف جهة اتصال
  Future<void> deleteContact(int localId, {String? cloudId}) async {
    await _db.deleteContact(localId);
    if (cloudId != null) {
      await _cloud.deleteContact(cloudId);
    }
  }

  /// بث حي لجهات الاتصال لقمرة القيادة
  Stream<List<Contact>> watchContacts() => _db.watchAllContacts();

  /// جلب جهات اتصال الطوارئ المعتمدة
  Future<List<Contact>> getEmergencyContacts() => _db.getEmergencyContacts();

  /// البحث الذكي بالاسم أو صلة القرابة (أبي، طبيبي، أمي)
  Future<Contact?> findContact(String query) =>
      _db.findContactByNameOrRelation(query);

  // ===========================================================================
  // 💬 3. سجل التراسل الصامت (Messages Vault)
  // ===========================================================================

  /// تسجيل رسالة جديدة واردة أو صادرة
  Future<void> recordMessage({
    required String contactIdentifier,
    required String senderName,
    required String messageText,
    String platform = 'sms',
    bool isOutgoing = false,
  }) async {
    await _db.insertMessage(
      MessagesVaultCompanion.insert(
        contactIdentifier: contactIdentifier,
        senderName: senderName,
        messageText: messageText,
        platform: Value(platform),
        isOutgoing: Value(isOutgoing),
      ),
    );

    await _cloud.syncMessage(
      contactIdentifier: contactIdentifier,
      senderName: senderName,
      messageText: messageText,
      platform: platform,
      isOutgoing: isOutgoing,
    );
  }

  /// استعراض رسائل محادثة معينة
  Stream<List<MessagesVaultData>> watchMessages(String contactIdentifier) =>
      _db.watchMessagesForContact(contactIdentifier);

  /// جلب الرسائل غير المقروءة لتلخيصها صوتياً
  Future<List<MessagesVaultData>> getUnreadMessages() =>
      _db.getUnreadMessages();

  /// تمييز الرسائل كمقروءة
  Future<void> markMessagesAsRead(String contactIdentifier) async {
    await _db.markMessagesAsRead(contactIdentifier);
    await _cloud.markMessagesAsReadInCloud(contactIdentifier);
  }

  // ===========================================================================
  // 🧠 4. موجه الأوامر التنفيذية الفوري (Voice & Action Dispatcher)
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

        await _hardware.setSystemAlarm(
          hour: hour,
          minute: minute,
          label: 'Beacon Alarm',
        );
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

      // فحص هل الاسم أو صلة القرابة مسجلة مسبقاً في دليل الهاتف؟
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
      await _db.insertTask(TasksCompanion.insert(title: title));
      await _cloud.backupTask(title: title);
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
      await _db.insertMemo(
        VoiceMemosCompanion.insert(title: title, content: content),
      );
      await _cloud.backupMemo(title: title, content: content);
      return LauncherCommandResult(
        intent: 'SAVE_MEMO',
        spokenResponse: 'Note saved: $title.',
      );
    }

    // -------------------------------------------------------------
    // مسار الذكاء الاصطناعي المتقدم (Gemini 2.0 Flash via OpenRouter)
    // -------------------------------------------------------------
    final aiResult = await _llm.processCommand(
      userCommand: userQuery,
      base64Image: base64Image,
    );

    final intent = aiResult['intent'] as String? ?? 'GENERAL_CHAT';
    final spokenResponse =
        aiResult['spoken_response'] as String? ?? 'Command processed.';

    final dynamic rawParams = aiResult['parameters'];
    final Map<String, dynamic> params = rawParams is Map
        ? Map<String, dynamic>.from(rawParams)
        : <String, dynamic>{};

    // تنفيذ إجراءات استدعاء الدوال الذاتية (Autonomous Tool Execution)
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
        if (target.isNotEmpty) {
          final contact = await _db.findContactByNameOrRelation(target);
          final numberToCall = contact != null ? contact.phoneNumber : target;
          await _hardware.callPhoneNumber(numberToCall);
        }
        break;

      case 'SAVE_TASK':
        final taskTitle = params['task_title'] as String? ?? '';
        if (taskTitle.isNotEmpty) {
          DateTime? dueDate;
          final dueStr = params['due_date'] as String?;
          if (dueStr != null) dueDate = DateTime.tryParse(dueStr);
          await _db.insertTask(
            TasksCompanion.insert(title: taskTitle, dueDate: Value(dueDate)),
          );
          await _cloud.backupTask(title: taskTitle, dueDate: dueDate);
        }
        break;

      case 'SAVE_MEMO':
        final memoTitle = params['memo_title'] as String? ?? 'Voice Note';
        final memoContent = params['memo_content'] as String? ?? memoTitle;
        await _db.insertMemo(
          VoiceMemosCompanion.insert(title: memoTitle, content: memoContent),
        );
        await _cloud.backupMemo(title: memoTitle, content: memoContent);
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

  // ===========================================================================
  // 🚨 5. رادار الطوارئ وبث الاستغاثة (Emergency SOS Radar)
  // ===========================================================================

  Future<void> triggerEmergencySos({
    required double latitude,
    required double longitude,
    int? batteryLevel,
  }) async {
    // 1. بث الإحداثيات لسيرفرات Supabase لمتابعة المرافقين لحظياً
    await _cloud.broadcastEmergencySos(
      latitude: latitude,
      longitude: longitude,
      batteryLevel: batteryLevel,
    );

    // 2. فحص جهات اتصال الطوارئ والاتصال التلقائي برقم الطوارئ الأول
    final emergencyContacts = await _db.getEmergencyContacts();
    if (emergencyContacts.isNotEmpty) {
      final primaryContact = emergencyContacts.first;
      log(
        'LauncherRepository: Auto-dialing emergency contact: ${primaryContact.name}',
      );
      await _hardware.callPhoneNumber(primaryContact.phoneNumber);
    }
  }
  // أضف هذه الدوال داخل LauncherRepository:

  // --- المهام والأجندة ---
  Stream<List<Task>> watchTasks() => _db.watchAllTasks();

  Future<void> createTask({
    required String title,
    DateTime? dueDate,
    String priority = 'medium',
  }) async {
    await _db.insertTask(
      TasksCompanion.insert(
        title: title,
        dueDate: Value(dueDate),
        priority: Value(priority),
      ),
    );
    await _cloud.backupTask(title: title, dueDate: dueDate);
  }

  Future<void> toggleTask(Task task) async {
    final nextStatus = !task.isCompleted;
    await _db.toggleTaskCompletion(task.id, nextStatus);
    await _cloud.updateTaskStatusInCloud(
      taskTitle: task.title,
      isCompleted: nextStatus,
    );
  }

  Future<void> deleteTask(Task task) async {
    await _db.deleteTask(task.id);
    await _cloud.deleteTaskFromCloud(task.title);
  }

  // --- المذكرات والملاحظات ---
  Stream<List<VoiceMemo>> watchMemos() => _db.watchRecentMemos();

  Future<void> deleteMemo(int id) async {
    await _db.deleteMemo(id);
  }

  // --- المنبهات وجلسات التركيز ---
  Stream<List<Alarm>> watchAlarms() => _db.watchAllAlarms();

  Future<void> createAlarm({
    required int hour,
    required int minute,
    String label = 'Beacon Alarm',
  }) async {
    // 1. حفظ في قاعدة البيانات المحلية
    await _db.insertAlarm(
      AlarmsCompanion.insert(hour: hour, minute: minute, label: Value(label)),
    );

    // 2. تفعيل المنبه الفعلي في نظام أندرويد عبر الجسر الأصلي (Kotlin Bridge)
    await _hardware.setSystemAlarm(hour: hour, minute: minute, label: label);

    // 3. مزامنة سحابية بالخلفية
    await _cloud.syncAlarm(hour: hour, minute: minute, label: label);
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
  }

  Future<void> deleteAlarm(int alarmId) => _db.deleteAlarm(alarmId);

  Stream<List<FocusSession>> watchTodayFocusSessions() =>
      _db.watchTodayFocusSessions();

  Future<void> recordCompletedFocusSession(int minutes) async {
    await _db.insertFocusSession(
      FocusSessionsCompanion.insert(durationMinutes: minutes),
    );
    await _cloud.logFocusSession(durationMinutes: minutes);
  }

  // أضف هذه الدوال داخل كلاس LauncherRepository في:
  // packages/launcher_repository/lib/src/launcher_repository.dart

  // ===========================================================================
  // 👁️ دوال استوديو الرؤية المكانية (Multimodal Vision Engine)
  // ===========================================================================

  /// تحليل الإطار الملتقط بواسطة Gemini 2.0 Flash عبر موجه متخصص
  Future<String> analyzeVisionFrame({
    required String base64Image,
    required String prompt,
  }) async {
    final result = await _llm.processCommand(
      userCommand: prompt,
      base64Image: base64Image,
    );
    return result['spoken_response'] as String? ??
        'Could not identify the scene.';
  }

  /// حفظ النتيجة البصرية كمذكرة صوتية دائمة في بنك الذاكرة والسحابة
  Future<void> saveVisionScanAsMemo({
    required String title,
    required String description,
  }) async {
    await _db.insertMemo(
      VoiceMemosCompanion.insert(title: title, content: description),
    );
    await _cloud.backupMemo(title: title, content: description);
  }
}
