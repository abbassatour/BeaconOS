// packages/local_vault_api/lib/src/tables/contacts_table.dart
import 'package:drift/drift.dart';

class Contacts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get phoneNumber => text().withLength(min: 3, max: 40)();
  TextColumn get relationship => text().nullable()();
  BoolColumn get isEmergency => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}