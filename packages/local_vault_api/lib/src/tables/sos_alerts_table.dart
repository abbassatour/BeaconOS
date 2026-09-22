// packages/local_vault_api/lib/src/tables/sos_alerts_table.dart
import 'package:drift/drift.dart';

class SosAlerts extends Table {
  TextColumn get id => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get batteryLevel => integer().withDefault(const Constant(100))();
  TextColumn get status => text().withDefault(const Constant('active'))(); // active, resolved, test
  TextColumn get googleMapsUrl => text()();
  DateTimeColumn get triggeredAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}