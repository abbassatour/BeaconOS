// packages/local_vault_api/lib/src/app_database.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'connection.dart';
import 'tables/alarms_table.dart';
import 'tables/app_settings_table.dart';
import 'tables/contacts_table.dart';
import 'tables/focus_sessions_table.dart';
import 'tables/messages_vault_table.dart';
import 'tables/notifications_table.dart';
import 'tables/sos_alerts_table.dart';
import 'tables/tasks_table.dart';
import 'tables/vision_scans_table.dart';
import 'tables/voice_memos_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    VoiceMemos,
    Tasks,
    NotificationsDigest,
    Contacts,
    MessagesVault,
    Alarms,
    FocusSessions,
    AppSettings,
    SosAlerts,
    VisionScans,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 5;

  static const _uuid = Uuid();
  static const defaultSettingsId = 'local_device_settings';

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // تهيئة الإعدادات الافتراضية عند أول تشغيل
        await into(appSettings).insert(
          AppSettingsCompanion.insert(id: defaultSettingsId),
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 5) {
          // ترقية هيكلية الجداول للنسخة الحديثة 5.0
          await m.createTable(appSettings);
          await m.createTable(sosAlerts);
          await m.createTable(visionScans);
          
          // إدخال الإعدادات الافتراضية
          await into(appSettings).insert(
            AppSettingsCompanion.insert(id: defaultSettingsId),
            mode: InsertMode.insertOrIgnore,
          );
        }
      },
    );
  }

  // ===========================================================================
  // ⚙️ 1. إدارة الإعدادات الشاملة (App Settings Engine)
  // ===========================================================================

  Stream<AppSetting> watchSettings() {
    return (select(appSettings)..where((s) => s.id.equals(defaultSettingsId)))
        .watchSingle();
  }

  Future<AppSetting> getSettings() async {
    final existing = await (select(appSettings)
          ..where((s) => s.id.equals(defaultSettingsId)))
        .getSingleOrNull();

    if (existing != null) return existing;

    // في حال عدم وجودها، يتم إنشاؤها فوراً
    await into(appSettings).insert(
      AppSettingsCompanion.insert(id: defaultSettingsId),
      mode: InsertMode.insertOrIgnore,
    );
    return (select(appSettings)
          ..where((s) => s.id.equals(defaultSettingsId)))
        .getSingle();
  }

  Future<void> updateSettings(AppSettingsCompanion updated) {
    return (update(appSettings)..where((s) => s.id.equals(defaultSettingsId)))
        .write(updated.copyWith(
          updatedAt: Value(DateTime.now()),
          isSynced: const Value(false),
        ));
  }

  // ===========================================================================
  // 📋 2. عمليات المهام مع الحذف الناعم (Tasks Engine)
  // ===========================================================================

  Stream<List<Task>> watchAllTasks() => (select(tasks)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm.asc(t.isCompleted),
          (t) => OrderingTerm.asc(t.dueDate),
        ]))
      .watch();

  Stream<List<Task>> watchPendingTasks() => (select(tasks)
        ..where((t) => t.deletedAt.isNull() & t.isCompleted.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
      .watch();

  Future<List<Task>> getPendingTasks() => (select(tasks)
        ..where((t) => t.deletedAt.isNull() & t.isCompleted.equals(false)))
      .get();

  Future<String> insertTask({
    required String title,
    DateTime? dueDate,
    String priority = 'medium',
    String? id,
  }) async {
    final taskId = id ?? _uuid.v4();
    await into(tasks).insert(
      TasksCompanion.insert(
        id: taskId,
        title: title,
        dueDate: Value(dueDate),
        priority: Value(priority),
      ),
    );
    return taskId;
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        isCompleted: Value(isCompleted),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  Future<void> softDeleteTask(String taskId) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  // ===========================================================================
  // 🎙️ 3. المذكرات والملاحظات الصوتية (Voice Memos)
  // ===========================================================================

  Stream<List<VoiceMemo>> watchRecentMemos({int limit = 25}) =>
      (select(voiceMemos)
            ..where((m) => m.deletedAt.isNull())
            ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
            ..limit(limit))
          .watch();

  Future<String> insertMemo({
    required String title,
    required String content,
    String? id,
  }) async {
    final memoId = id ?? _uuid.v4();
    await into(voiceMemos).insert(
      VoiceMemosCompanion.insert(
        id: memoId,
        title: title,
        content: content,
      ),
    );
    return memoId;
  }

  Future<void> softDeleteMemo(String memoId) {
    return (update(voiceMemos)..where((m) => m.id.equals(memoId))).write(
      VoiceMemosCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  // ===========================================================================
  // 📇 4. جهات الاتصال (Contacts)
  // ===========================================================================

  Stream<List<Contact>> watchAllContacts() => (select(contacts)
        ..where((c) => c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.name)]))
      .watch();

  Future<List<Contact>> getEmergencyContacts() => (select(contacts)
        ..where((c) => c.deletedAt.isNull() & c.isEmergency.equals(true)))
      .get();

  Future<Contact?> findContactByNameOrRelation(String query) {
    final clean = query.trim().toLowerCase();
    return (select(contacts)
          ..where((c) =>
              c.deletedAt.isNull() &
              (c.name.lower().equals(clean) |
                  c.relationship.lower().equals(clean) |
                  c.name.lower().like('%$clean%') |
                  c.relationship.lower().like('%$clean%')))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<String> insertContact({
    required String name,
    required String phoneNumber,
    String? relationship,
    bool isEmergency = false,
    String? id,
  }) async {
    final contactId = id ?? _uuid.v4();
    await into(contacts).insert(
      ContactsCompanion.insert(
        id: contactId,
        name: name,
        phoneNumber: phoneNumber,
        relationship: Value(relationship),
        isEmergency: Value(isEmergency),
      ),
    );
    return contactId;
  }

  Future<void> softDeleteContact(String contactId) {
    return (update(contacts)..where((c) => c.id.equals(contactId))).write(
      ContactsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  // ===========================================================================
  // ⏰ 5. المنبهات الهادئة (Alarms)
  // ===========================================================================

  Stream<List<Alarm>> watchAllAlarms() => (select(alarms)
        ..where((a) => a.deletedAt.isNull())
        ..orderBy([
          (a) => OrderingTerm.asc(a.hour),
          (a) => OrderingTerm.asc(a.minute),
        ]))
      .watch();

  Future<String> insertAlarm({
    required int hour,
    required int minute,
    String label = 'Beacon Alarm',
    String? id,
  }) async {
    final alarmId = id ?? _uuid.v4();
    await into(alarms).insert(
      AlarmsCompanion.insert(
        id: alarmId,
        hour: hour,
        minute: minute,
        label: Value(label),
      ),
    );
    return alarmId;
  }

  Future<void> toggleAlarmStatus(String alarmId, bool isActive) {
    return (update(alarms)..where((a) => a.id.equals(alarmId))).write(
      AlarmsCompanion(
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  Future<void> softDeleteAlarm(String alarmId) {
    return (update(alarms)..where((a) => a.id.equals(alarmId))).write(
      AlarmsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  // ===========================================================================
  // ⏳ 6. جلسات التركيز (Focus Sessions)
  // ===========================================================================

  Stream<List<FocusSession>> watchTodayFocusSessions() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return (select(focusSessions)
          ..where((s) =>
              s.deletedAt.isNull() &
              s.completedAt.isBiggerOrEqualValue(startOfDay))
          ..orderBy([(s) => OrderingTerm.desc(s.completedAt)]))
        .watch();
  }

  Future<String> insertFocusSession(int durationMinutes, {String? id}) async {
    final sessionId = id ?? _uuid.v4();
    await into(focusSessions).insert(
      FocusSessionsCompanion.insert(
        id: sessionId,
        durationMinutes: durationMinutes,
      ),
    );
    return sessionId;
  }

  // ===========================================================================
  // 🚨 7. استغاثات الطوارئ وسجل الرادار (SOS Alerts)
  // ===========================================================================

  Future<String> insertSosAlert({
    required double latitude,
    required double longitude,
    required int batteryLevel,
    required String googleMapsUrl,
    String status = 'active',
  }) async {
    final alertId = _uuid.v4();
    await into(sosAlerts).insert(
      SosAlertsCompanion.insert(
        id: alertId,
        latitude: latitude,
        longitude: longitude,
        batteryLevel: Value(batteryLevel),
        googleMapsUrl: googleMapsUrl,
        status: Value(status),
      ),
    );
    return alertId;
  }

  // ===========================================================================
  // 👁️ 8. الفحوصات البصرية الذكية (Vision Scans)
  // ===========================================================================

  Future<String> insertVisionScan({
    required String mode,
    required String prompt,
    required String description,
  }) async {
    final scanId = _uuid.v4();
    await into(visionScans).insert(
      VisionScansCompanion.insert(
        id: scanId,
        mode: mode,
        prompt: prompt,
        description: description,
      ),
    );
    return scanId;
  }

  Stream<List<VisionScan>> watchRecentVisionScans({int limit = 20}) =>
      (select(visionScans)
            ..where((v) => v.deletedAt.isNull())
            ..orderBy([(v) => OrderingTerm.desc(v.createdAt)])
            ..limit(limit))
          .watch();

  // ===========================================================================
  // 💬 9. الرسائل والإشعارات (Messages & Notifications)
  // ===========================================================================

  /// 1. بث حي لرسائل جهة اتصال محددة مرتبة زمنياً
  Stream<List<MessagesVaultData>> watchMessagesForContact(
    String contactIdentifier,
  ) {
    return (select(messagesVault)
          ..where((m) =>
              m.deletedAt.isNull() &
              m.contactIdentifier.equals(contactIdentifier))
          ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
        .watch();
  }

  /// 2. جلب أحدث الرسائل غير المحذوفة
  Future<List<MessagesVaultData>> getRecentMessages({int limit = 50}) =>
      (select(messagesVault)
            ..where((m) => m.deletedAt.isNull())
            ..orderBy([(m) => OrderingTerm.desc(m.timestamp)])
            ..limit(limit))
          .get();

  /// 3. جلب الرسائل غير المقروءة (دالتك الحالية)
  Future<List<MessagesVaultData>> getUnreadMessages() => (select(messagesVault)
        ..where((m) => m.deletedAt.isNull() & m.isRead.equals(false)))
      .get();

  /// 4. إدخال رسالة جديدة وتوليد UUID لها (دالتك الحالية)
  Future<String> insertMessage({
    required String contactIdentifier,
    required String senderName,
    required String messageText,
    String platform = 'sms',
    bool isOutgoing = false,
  }) async {
    final msgId = _uuid.v4();
    await into(messagesVault).insert(
      MessagesVaultCompanion.insert(
        id: msgId,
        contactIdentifier: contactIdentifier,
        senderName: senderName,
        messageText: messageText,
        platform: Value(platform),
        isOutgoing: Value(isOutgoing),
      ),
    );
    return msgId;
  }

  /// 5. تمييز الرسائل كمقروءة وتحديث طابع التعديل (دالتك الحالية)
  Future<void> markMessagesAsRead(String contactIdentifier) {
    return (update(messagesVault)
          ..where((m) => m.contactIdentifier.equals(contactIdentifier)))
        .write(MessagesVaultCompanion(
          isRead: const Value(true),
          updatedAt: Value(DateTime.now()),
          isSynced: const Value(false),
        ));
  }

  // --- دوال جدول ملخص الإشعارات (Notifications Digest) ---

  Future<List<NotificationsDigestData>> getUnreadNotifications() =>
      (select(notificationsDigest)..where((t) => t.isRead.equals(false))).get();

  Future<int> insertNotification(NotificationsDigestCompanion notif) =>
      into(notificationsDigest).insert(notif);

  Future<void> markAllNotificationsAsRead() =>
      (update(notificationsDigest)..where((t) => t.isRead.equals(false))).write(
        const NotificationsDigestCompanion(isRead: Value(true)),
      );

  // ===========================================================================
  // 🧹 عمليات الحذف النهائي (Hard Deletes for Sync Cleanup)
  // ===========================================================================

  /// تُستخدم هذه الدوال فقط بواسطة محرك المزامنة بالخلفية لتنظيف مساحة الهاتف
  /// بعد التأكد من أن السجلات حُذفت بنجاح من سحابة Supabase.
  
  Future<int> deleteTask(String id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  Future<int> deleteMemo(String id) =>
      (delete(voiceMemos)..where((m) => m.id.equals(id))).go();

  Future<int> deleteContact(String id) =>
      (delete(contacts)..where((c) => c.id.equals(id))).go();

  Future<int> deleteAlarm(String id) =>
      (delete(alarms)..where((a) => a.id.equals(id))).go();
}