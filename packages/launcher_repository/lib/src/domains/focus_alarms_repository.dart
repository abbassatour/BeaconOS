// packages/launcher_repository/lib/src/domains/focus_alarms_repository.dart
import 'dart:developer';
import 'package:cloud_sync_api/cloud_sync_api.dart';
import 'package:drift/drift.dart';
import 'package:local_vault_api/local_vault_api.dart';
import 'package:system_hardware_api/system_hardware_api.dart';

abstract class FocusAlarmsRepository {
  Stream<List<Alarm>> watchAlarms();
  Future<String> createAlarm({
    required int hour,
    required int minute,
    String label = 'Beacon Alarm',
  });
  Future<void> toggleAlarm(Alarm alarm);
  Future<void> deleteAlarm(dynamic alarmOrId);

  Stream<List<FocusSession>> watchTodayFocusSessions();
  Future<String> recordCompletedFocusSession(int minutes);
  Future<void> syncPendingAlarms();
}

class FocusAlarmsRepositoryImpl implements FocusAlarmsRepository {
  FocusAlarmsRepositoryImpl({
    required AppDatabase database,
    required CloudSyncClient cloudSync,
    required HardwareClient hardware,
  })  : _db = database,
        _cloud = cloudSync,
        _hardware = hardware;

  final AppDatabase _db;
  final CloudSyncClient _cloud;
  final HardwareClient _hardware;

  @override
  Stream<List<Alarm>> watchAlarms() => _db.watchAllAlarms();

  @override
  Future<String> createAlarm({
    required int hour,
    required int minute,
    String label = 'Beacon Alarm',
  }) async {
    final id = await _db.insertAlarm(hour: hour, minute: minute, label: label);

    // ⚡️ فحص إعداد مزامنة المنبهات مع ساعة أندرويد الرسمية
    final settings = await _db.getSettings();
    if (settings.syncAlarmsWithAndroidClock) {
      await _hardware.setSystemAlarm(hour: hour, minute: minute, label: label);
    }

    _cloud.syncAlarm(id: id, hour: hour, minute: minute, label: label).catchError((Object error) {
      log('FocusAlarmsRepository: Cloud alarm sync deferred [$id]: $error');
    });

    return id;
  }

  @override
  Future<void> toggleAlarm(Alarm alarm) async {
    final nextStatus = !alarm.isActive;
    await _db.toggleAlarmStatus(alarm.id, nextStatus);

    if (nextStatus) {
      // ⚡️ مزامنة التفعيل مع أندرويد فقط إذا سمح المستخدم بذلك
      final settings = await _db.getSettings();
      if (settings.syncAlarmsWithAndroidClock) {
        await _hardware.setSystemAlarm(
          hour: alarm.hour,
          minute: alarm.minute,
          label: alarm.label,
        );
      }
    }

    _cloud.syncAlarm(
      id: alarm.id,
      hour: alarm.hour,
      minute: alarm.minute,
      label: alarm.label,
      isActive: nextStatus,
    ).catchError((Object error) {
      log('FocusAlarmsRepository: Cloud alarm toggle deferred: $error');
    });
  }

  @override
  Future<void> deleteAlarm(dynamic alarmOrId) async {
    final String id = alarmOrId is Alarm ? alarmOrId.id : alarmOrId.toString();
    await _db.softDeleteAlarm(id);

    _cloud.softDeleteAlarmInCloud(id).catchError((Object error) {
      log('FocusAlarmsRepository: Cloud alarm delete deferred [$id]: $error');
    });
  }

  @override
  Stream<List<FocusSession>> watchTodayFocusSessions() =>
      _db.watchTodayFocusSessions();

  @override
  Future<String> recordCompletedFocusSession(int minutes) async {
    final id = await _db.insertFocusSession(minutes);

    _cloud.syncFocusSession(id: id, durationMinutes: minutes).catchError((Object error) {
      log('FocusAlarmsRepository: Cloud focus sync deferred [$id]: $error');
    });

    return id;
  }

  @override
  Future<void> syncPendingAlarms() async {
    if (!_cloud.isAuthenticated) return;
    try {
      final pending = await (_db.select(_db.alarms)..where((a) => a.isSynced.equals(false))).get();
      for (final a in pending) {
        if (a.deletedAt != null) {
          await _cloud.softDeleteAlarmInCloud(a.id);
          await _db.deleteAlarm(a.id);
        } else {
          await _cloud.syncAlarm(
            id: a.id,
            hour: a.hour,
            minute: a.minute,
            label: a.label,
            daysOfWeek: a.daysOfWeek,
            isActive: a.isActive,
          );
          await (_db.update(_db.alarms)..where((tbl) => tbl.id.equals(a.id)))
              .write(const AlarmsCompanion(isSynced: Value(true)));
        }
      }
    } catch (e) {
      log('FocusAlarmsRepository: Pending alarm sync error: $e');
    }
  }
}