// packages/local_vault_api/lib/src/app_database.dart
import 'package:drift/drift.dart';
import 'connection.dart';
import 'tables/contacts_table.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // ترقية قاعدة البيانات بإضافة الجداول الجديدة دون مساس ببيانات النسخة الأولى
          await m.createTable(contacts);
          await m.createTable(messagesVault);
        }
      },
    );
  }

  // ==========================================
  // 📋 1. عمليات جهات الاتصال (Contacts)
  // ==========================================

  /// جلب كل جهات الاتصال مرتبة أبجدياً
  Future<List<Contact>> getAllContacts() =>
      (select(contacts)..orderBy([(c) => OrderingTerm.asc(c.name)])).get();

  /// تدفق حي ومباشر لتحديث الواجهات التحريرية وقمرة القيادة
  Stream<List<Contact>> watchAllContacts() =>
      (select(contacts)..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();

  /// جلب أرقام الطوارئ المعتمدة لإرسال الـ SOS إليها
  Future<List<Contact>> getEmergencyContacts() =>
      (select(contacts)..where((c) => c.isEmergency.equals(true))).get();

  /// البحث السريع عن جهة اتصال بالاسم أو صلة القرابة (للأمر الصوتي: "Call Mom")
  Future<Contact?> findContactByNameOrRelation(String query) {
    final clean = query.trim().toLowerCase();
    return (select(contacts)
          ..where((c) =>
              c.name.lower().equals(clean) |
              c.relationship.lower().equals(clean) |
              c.name.lower().like('%$clean%') |
              c.relationship.lower().like('%$clean%'))
          ..limit(1))
        .getSingleOrNull();
  }

  /// إضافة جهة اتصال جديدة
  Future<int> insertContact(ContactsCompanion contact) =>
      into(contacts).insert(contact);

  /// تحديث جهة اتصال
  Future<bool> updateContact(Contact contact) =>
      update(contacts).replace(contact);

  /// حذف جهة اتصال
  Future<int> deleteContact(int id) =>
      (delete(contacts)..where((c) => c.id.equals(id))).go();

  // ==========================================
  // 💬 2. عمليات سجل التراسل (Messages Vault)
  // ==========================================

  /// جلب أحدث الرسائل لأرشيف النظام الصامت
  Future<List<MessagesVaultData>> getRecentMessages({int limit = 50}) =>
      (select(messagesVault)
            ..orderBy([(m) => OrderingTerm.desc(m.timestamp)])
            ..limit(limit))
          .get();

  /// تدفق حي لرسائل محادثة معينة
  Stream<List<MessagesVaultData>> watchMessagesForContact(String contactIdentifier) =>
      (select(messagesVault)
            ..where((m) => m.contactIdentifier.equals(contactIdentifier))
            ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
          .watch();

  /// استرجاع الرسائل غير المقروءة لطلب التلخيص الصوتي
  Future<List<MessagesVaultData>> getUnreadMessages() =>
      (select(messagesVault)..where((m) => m.isRead.equals(false))).get();

  /// حفظ رسالة واردة أو رد صامت صادر
  Future<int> insertMessage(MessagesVaultCompanion message) =>
      into(messagesVault).insert(message);

  /// تمييز الرسائل كمقروءة
  Future<void> markMessagesAsRead(String contactIdentifier) =>
      (update(messagesVault)..where((m) => m.contactIdentifier.equals(contactIdentifier)))
          .write(const MessagesVaultCompanion(isRead: Value(true)));

  // ==========================================
  // 📝 3. المهام والمذكرات والإشعارات (V1)
  // ==========================================
  Future<List<Task>> getPendingTasks() =>
      (select(tasks)..where((t) => t.isCompleted.equals(false))).get();

  Stream<List<Task>> watchPendingTasks() =>
      (select(tasks)..where((t) => t.isCompleted.equals(false))).watch();

  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  Future<List<VoiceMemo>> getAllMemos() =>
      (select(voiceMemos)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Stream<List<VoiceMemo>> watchAllMemos() =>
      (select(voiceMemos)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<int> insertMemo(VoiceMemosCompanion memo) => into(voiceMemos).insert(memo);

  Future<List<NotificationsDigestData>> getUnreadNotifications() =>
      (select(notificationsDigest)..where((t) => t.isRead.equals(false))).get();

  Future<int> insertNotification(NotificationsDigestCompanion notif) =>
      into(notificationsDigest).insert(notif);

  Future<void> markAllNotificationsAsRead() =>
      (update(notificationsDigest)..where((t) => t.isRead.equals(false)))
          .write(const NotificationsDigestCompanion(isRead: Value(true)));
}