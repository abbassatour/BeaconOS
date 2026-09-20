// packages/local_vault_api/lib/src/app_database.dart
import 'package:drift/drift.dart';
import 'connection.dart';
import 'tables/tasks_table.dart';
import 'tables/voice_memos_table.dart';
import 'tables/notifications_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [VoiceMemos, Tasks, NotificationsDigest])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;

  // -- المهام --
  Future<List<Task>> getPendingTasks() =>
      (select(tasks)..where((t) => t.isCompleted.equals(false))).get();
      
  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  // -- الملاحظات --
  Future<List<VoiceMemo>> getAllMemos() =>
      (select(voiceMemos)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
      
  Future<int> insertMemo(VoiceMemosCompanion memo) => into(voiceMemos).insert(memo);

  // -- الإشعارات --
  Future<List<NotificationsDigestData>> getUnreadNotifications() =>
      (select(notificationsDigest)..where((t) => t.isRead.equals(false))).get();
      
  Future<int> insertNotification(NotificationsDigestCompanion notif) => 
      into(notificationsDigest).insert(notif);
      
  Future<void> markAllNotificationsAsRead() =>
      (update(notificationsDigest)..where((t) => t.isRead.equals(false)))
          .write(const NotificationsDigestCompanion(isRead: Value(true)));
}