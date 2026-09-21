// packages/local_vault_api/lib/src/tables/messages_vault_table.dart
import 'package:drift/drift.dart';

class MessagesVault extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// معرف جهة الاتصال (سواء كان رقم هاتف أو اسم)
  TextColumn get contactIdentifier => text().withLength(min: 1, max: 120)();

  /// اسم المرسل الظاهر
  TextColumn get senderName => text()();

  /// محتوى الرسالة النصية
  TextColumn get messageText => text()();

  /// التطبيق أو المنصة المصدر (sms, whatsapp, telegram)
  TextColumn get platform => text().withDefault(const Constant('sms'))();

  /// هل الرسالة صادرة من المستخدم (عبر الرد الصوتي) أم واردة؟
  BoolColumn get isOutgoing => boolean().withDefault(const Constant(false))();

  /// توقيت الرسالة
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();

  /// هل استمع إليها المستخدم أو قرأها؟
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}
