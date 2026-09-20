// packages/local_vault_api/lib/src/tables/notifications_table.dart
import 'package:drift/drift.dart';

class NotificationsDigest extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get appName => text()(); // مثلاً: WhatsApp, Gmail
  TextColumn get content => text()(); // محتوى الرسالة أو الإشعار
  DateTimeColumn get receivedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))(); // هل لخصها الذكاء الاصطناعي أم لا؟
}