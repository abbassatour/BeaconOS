// packages/local_vault_api/lib/src/tables/alarms_table.dart
import 'package:drift/drift.dart';

class Alarms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  TextColumn get label => text().withDefault(const Constant('Beacon Alarm'))();
  TextColumn get daysOfWeek => text().withDefault(const Constant('daily'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}