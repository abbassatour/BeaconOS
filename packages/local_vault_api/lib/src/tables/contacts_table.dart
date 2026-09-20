// packages/local_vault_api/lib/src/tables/contacts_table.dart
import 'package:drift/drift.dart';

class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  /// الاسم الظاهر (مثلاً: أحمد، John Smith)
  TextColumn get name => text().withLength(min: 1, max: 120)();
  
  /// رقم الهاتف المعياري
  TextColumn get phoneNumber => text().withLength(min: 3, max: 40)();
  
  /// صلة القرابة لتمكين الأوامر الصوتية الذكية (مثلاً: أبي، Dad, Doctor, Sister)
  TextColumn get relationship => text().nullable()();
  
  /// هل يتم اعتماده كجهة اتصال للطوارئ في رادار الاستغاثة SOS؟
  BoolColumn get isEmergency => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}