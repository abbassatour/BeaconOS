// packages/local_vault_api/lib/src/app_database.dart
import 'package:drift/drift.dart';
import 'connection.dart';
import 'tables/alarms_table.dart';
import 'tables/contacts_table.dart';
import 'tables/focus_sessions_table.dart';
import 'tables/messages_vault_table.dart';
import 'tables/notifications_table.dart';
import 'tables/tasks_table.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(contacts);
          await m.createTable(messagesVault);
        }
        if (from < 3) {
          // ترقية جدول المهام بإضافة حقل الأولوية
          await m.addColumn(tasks, tasks.priority);
        }
        if (from < 4) {
          // ترقية بنك الذاكرة لغرفة الغرب: المنبهات وجلسات التركيز
          await m.createTable(alarms);
          await m.createTable(focusSessions);
        }
      },
    );
  }

  // ===========================================================================
  // ⏰ 1. عمليات ساعة المنبهات الهادئة (Alarms Operations)
  // ===========================================================================

  /// تدفق حي لجميع المنبهات مرتبة بالساعة والدقيقة
  Stream<List<Alarm>> watchAllAlarms() =>
      (select(alarms)..orderBy([
            (a) => OrderingTerm.asc(a.hour),
            (a) => OrderingTerm.asc(a.minute),
          ]))
          .watch();

  /// جلب كل المنبهات دفعة واحدة
  Future<List<Alarm>> getAllAlarms() =>
      (select(alarms)..orderBy([
            (a) => OrderingTerm.asc(a.hour),
            (a) => OrderingTerm.asc(a.minute),
          ]))
          .get();

  /// جلب المنبهات النشطة فقط
  Future<List<Alarm>> getActiveAlarms() =>
      (select(alarms)..where((a) => a.isActive.equals(true))).get();

  /// إضافة منبه جديد
  Future<int> insertAlarm(AlarmsCompanion alarm) => into(alarms).insert(alarm);

  /// تفعيل أو تعطيل المنبه
  Future<void> toggleAlarmStatus(int alarmId, bool isActive) =>
      (update(alarms)..where((a) => a.id.equals(alarmId))).write(
        AlarmsCompanion(isActive: Value(isActive)),
      );

  /// تحديث بيانات المنبه كاملاً (الوقت، التسمية، التكرار)
  Future<bool> updateAlarm(Alarm alarm) => update(alarms).replace(alarm);

  /// حذف منبه نهائياً
  Future<int> deleteAlarm(int alarmId) =>
      (delete(alarms)..where((a) => a.id.equals(alarmId))).go();

  // ===========================================================================
  // ⏳ 2. عمليات جلسات التركيز والمذاكرة (Focus Sessions Operations)
  // ===========================================================================

  /// تدفق حي لجلسات التركيز المنجزة اليوم مرتبة بالأحدث
  Stream<List<FocusSession>> watchTodayFocusSessions() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return (select(focusSessions)
          ..where((s) => s.completedAt.isBiggerOrEqualValue(startOfDay))
          ..orderBy([(s) => OrderingTerm.desc(s.completedAt)]))
        .watch();
  }

  /// تسجيل جلسة تركيز مكتملة
  Future<int> insertFocusSession(FocusSessionsCompanion session) =>
      into(focusSessions).insert(session);

  /// جلب إجمالي دقائق التركيز لليوم الحالي
  Future<int> getTodayFocusMinutes() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final sessions = await (select(
      focusSessions,
    )..where((s) => s.completedAt.isBiggerOrEqualValue(startOfDay))).get();
    return sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  // ===========================================================================
  // 📋 3. عمليات المهام والأجندة (Tasks & Agenda)
  // ===========================================================================

  Stream<List<Task>> watchAllTasks() =>
      (select(tasks)..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.asc(t.dueDate),
          ]))
          .watch();

  Future<List<Task>> getPendingTasks() =>
      (select(tasks)..where((t) => t.isCompleted.equals(false))).get();

  Stream<List<Task>> watchPendingTasks() =>
      (select(tasks)
            ..where((t) => t.isCompleted.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
          .watch();

  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  Future<void> toggleTaskCompletion(int taskId, bool isCompleted) =>
      (update(tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(isCompleted: Value(isCompleted)),
      );

  Future<int> deleteTask(int taskId) =>
      (delete(tasks)..where((t) => t.id.equals(taskId))).go();

  // ===========================================================================
  // 🎙️ 4. عمليات المذكرات والملاحظات الصوتية (Voice Memos)
  // ===========================================================================

  Stream<List<VoiceMemo>> watchRecentMemos({int limit = 25}) =>
      (select(voiceMemos)
            ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
            ..limit(limit))
          .watch();

  Future<List<VoiceMemo>> getAllMemos() => (select(
    voiceMemos,
  )..orderBy([(m) => OrderingTerm.desc(m.createdAt)])).get();

  Future<int> insertMemo(VoiceMemosCompanion memo) =>
      into(voiceMemos).insert(memo);

  Future<int> deleteMemo(int memoId) =>
      (delete(voiceMemos)..where((m) => m.id.equals(memoId))).go();

  // ===========================================================================
  // 📇 5. عمليات جهات الاتصال ورادار الطوارئ (Contacts)
  // ===========================================================================

  Future<List<Contact>> getAllContacts() =>
      (select(contacts)..orderBy([(c) => OrderingTerm.asc(c.name)])).get();

  Stream<List<Contact>> watchAllContacts() =>
      (select(contacts)..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();

  Future<List<Contact>> getEmergencyContacts() =>
      (select(contacts)..where((c) => c.isEmergency.equals(true))).get();

  Future<Contact?> findContactByNameOrRelation(String query) {
    final clean = query.trim().toLowerCase();
    return (select(contacts)
          ..where(
            (c) =>
                c.name.lower().equals(clean) |
                c.relationship.lower().equals(clean) |
                c.name.lower().like('%$clean%') |
                c.relationship.lower().like('%$clean%'),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> insertContact(ContactsCompanion contact) =>
      into(contacts).insert(contact);

  Future<bool> updateContact(Contact contact) =>
      update(contacts).replace(contact);

  Future<int> deleteContact(int id) =>
      (delete(contacts)..where((c) => c.id.equals(id))).go();

  // ===========================================================================
  // 💬 6. سجل التراسل الصامت (Messages Vault)
  // ===========================================================================

  Future<List<MessagesVaultData>> getRecentMessages({int limit = 50}) =>
      (select(messagesVault)
            ..orderBy([(m) => OrderingTerm.desc(m.timestamp)])
            ..limit(limit))
          .get();

  Stream<List<MessagesVaultData>> watchMessagesForContact(
    String contactIdentifier,
  ) =>
      (select(messagesVault)
            ..where((m) => m.contactIdentifier.equals(contactIdentifier))
            ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
          .watch();

  Future<List<MessagesVaultData>> getUnreadMessages() =>
      (select(messagesVault)..where((m) => m.isRead.equals(false))).get();

  Future<int> insertMessage(MessagesVaultCompanion message) =>
      into(messagesVault).insert(message);

  Future<void> markMessagesAsRead(String contactIdentifier) =>
      (update(messagesVault)
            ..where((m) => m.contactIdentifier.equals(contactIdentifier)))
          .write(const MessagesVaultCompanion(isRead: Value(true)));

  // ===========================================================================
  // 🔔 7. سجل الإشعارات المحجوبة (Notifications Digest)
  // ===========================================================================

  Future<List<NotificationsDigestData>> getUnreadNotifications() =>
      (select(notificationsDigest)..where((t) => t.isRead.equals(false))).get();

  Future<int> insertNotification(NotificationsDigestCompanion notif) =>
      into(notificationsDigest).insert(notif);

  Future<void> markAllNotificationsAsRead() =>
      (update(notificationsDigest)..where((t) => t.isRead.equals(false))).write(
        const NotificationsDigestCompanion(isRead: Value(true)),
      );
}
