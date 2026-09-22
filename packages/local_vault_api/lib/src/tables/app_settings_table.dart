// packages/local_vault_api/lib/src/tables/app_settings_table.dart
import 'package:drift/drift.dart';

class AppSettings extends Table {
  /// معرّف الإعدادات (نستخدم 'local_settings' كمعرف ثابت للمستخدم النشط)
  TextColumn get id => text()();

  // ==========================================
  // 🎛️ 1. Core & Audio Engine (Floor 2 - Center)
  // ==========================================
  RealColumn get speechRate => real().withDefault(const Constant(0.5))();
  BoolColumn get hapticsEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get soundCuesEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get isHighContrast => boolean().withDefault(const Constant(false))();

  // ==========================================
  // 📅 2. Agenda & Tasks Engine (Floor 2 - North)
  // ==========================================
  TextColumn get defaultPriority => text().withDefault(const Constant('medium'))();
  BoolColumn get autoArchiveCompleted => boolean().withDefault(const Constant(true))();
  BoolColumn get speakDueDatesAloud => boolean().withDefault(const Constant(true))();

  // ==========================================
  // 🛡️ 3. Comms & SOS Radar (Floor 2 - South)
  // ==========================================
  BoolColumn get autoDialEmergency => boolean().withDefault(const Constant(true))();
  BoolColumn get shareGpsOnSos => boolean().withDefault(const Constant(true))();
  BoolColumn get speakIncomingSms => boolean().withDefault(const Constant(true))();

  // ==========================================
  // ⏳ 4. Focus & Study Tuning (Floor 2 - West)
  // ==========================================
  BoolColumn get voiceChimeHalfway => boolean().withDefault(const Constant(true))();
  BoolColumn get vibrateOnSessionFinish => boolean().withDefault(const Constant(true))();
  BoolColumn get syncAlarmsWithAndroidClock => boolean().withDefault(const Constant(true))();

  // ==========================================
  // 👁️ 5. AI Vision Engine (Floor 2 - East)
  // ==========================================
  TextColumn get visionInspectionDetail => text().withDefault(const Constant('concise'))();
  BoolColumn get autoFlashlightInDark => boolean().withDefault(const Constant(true))();
  TextColumn get preferredCurrency => text().withDefault(const Constant('USD / Local'))();

  // ==========================================
  // 🔄 المزامنة والوقت
  // ==========================================
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}