// packages/local_vault_api/lib/src/tables/messages_vault_table.dart
import 'package:drift/drift.dart';

class MessagesVault extends Table {
  TextColumn get id => text()();
  TextColumn get contactIdentifier => text().withLength(min: 1, max: 120)();
  TextColumn get senderName => text()();
  TextColumn get messageText => text()();
  TextColumn get platform => text().withDefault(const Constant('sms'))();
  BoolColumn get isOutgoing => boolean().withDefault(const Constant(false))();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}