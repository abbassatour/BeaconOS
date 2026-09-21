// packages/local_vault_api/lib/src/tables/focus_sessions_table.dart
import 'package:drift/drift.dart';

class FocusSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get durationMinutes => integer()();
  TextColumn get sessionType => text().withDefault(const Constant('study'))();
  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}
