// packages/local_vault_api/lib/src/tables/vision_scans_table.dart
import 'package:drift/drift.dart';

class VisionScans extends Table {
  TextColumn get id => text()();
  TextColumn get mode => text()(); // surroundings, textReader, currency, productExpiry
  TextColumn get prompt => text()();
  TextColumn get description => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}