// packages/launcher_repository/lib/src/domains/comms_repository.dart
import 'dart:developer';
import 'package:cloud_sync_api/cloud_sync_api.dart';
import 'package:drift/drift.dart';
import 'package:local_vault_api/local_vault_api.dart';
import 'package:system_hardware_api/system_hardware_api.dart';
import 'package:uuid/uuid.dart';

abstract class CommsRepository {
  Stream<List<Contact>> watchContacts();
  Future<List<Contact>> getEmergencyContacts();
  Future<Contact?> findContact(String query);
  Future<String> saveContact({
    required String name,
    required String phoneNumber,
    String? relationship,
    bool isEmergency = false,
  });
  Future<void> deleteContact(dynamic contactOrId);

  /// مزامنة جهات اتصال الهاتف وتسويتها داخل الخزنة المحلية والسحابية
  Future<({int addedCount, int updatedCount})> syncDeviceContactsToVault();

  Stream<List<MessagesVaultData>> watchMessages(String contactIdentifier);
  Future<List<MessagesVaultData>> getUnreadMessages();
  Future<void> markMessagesAsRead(String contactIdentifier);
  Future<String> recordMessage({
    required String contactIdentifier,
    required String senderName,
    required String messageText,
    String platform = 'sms',
    bool isOutgoing = false,
  });

  Future<String> triggerEmergencySos({
    double? latitude,
    double? longitude,
    int? batteryLevel,
  });

  Future<void> restoreCommsFromCloud();
  Future<void> syncPendingComms();
}

class CommsRepositoryImpl implements CommsRepository {
  CommsRepositoryImpl({
    required AppDatabase database,
    required CloudSyncClient cloudSync,
    required HardwareClient hardware,
  })  : _db = database,
        _cloud = cloudSync,
        _hardware = hardware;

  final AppDatabase _db;
  final CloudSyncClient _cloud;
  final HardwareClient _hardware;
  final _uuid = const Uuid();

  @override
  Stream<List<Contact>> watchContacts() => _db.watchAllContacts();

  @override
  Future<List<Contact>> getEmergencyContacts() => _db.getEmergencyContacts();

  @override
  Future<Contact?> findContact(String query) =>
      _db.findContactByNameOrRelation(query);

  @override
  Future<String> saveContact({
    required String name,
    required String phoneNumber,
    String? relationship,
    bool isEmergency = false,
  }) async {
    final id = await _db.insertContact(
      name: name,
      phoneNumber: phoneNumber,
      relationship: relationship,
      isEmergency: isEmergency,
    );

    _cloud.syncContact(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      relationship: relationship,
      isEmergency: isEmergency,
    ).catchError((Object error) {
      log('CommsRepository: Cloud contact sync deferred: $error');
    });

    return id;
  }

  @override
  Future<void> deleteContact(dynamic contactOrId) async {
    final String id =
        contactOrId is Contact ? contactOrId.id : contactOrId.toString();
    await _db.softDeleteContact(id);
    _cloud.softDeleteContactInCloud(id).catchError((Object error) {
      log('CommsRepository: Cloud contact delete deferred: $error');
    });
  }

  @override
  Future<({int addedCount, int updatedCount})> syncDeviceContactsToVault() async {
    try {
      // 1. جلب جهات اتصال الجهاز الحقيقية
      final deviceRecords = await _hardware.getDeviceContacts();
      if (deviceRecords.isEmpty) {
        log('CommsRepository: No contacts found on device or permission rejected.');
        return (addedCount: 0, updatedCount: 0);
      }

      // 2. جلب جهات الاتصال المسجلة حالياً في Drift (المشفرة محلياً)
      final existingContacts = await (_db.select(_db.contacts)..where((c) => c.deletedAt.isNull())).get();

      // خريطة لتسريع البحث باستخدام رقم الهاتف كمفتاح أساسي
      final Map<String, Contact> phoneMap = {
        for (final c in existingContacts) _sanitizeNumber(c.phoneNumber): c,
      };

      var addedCount = 0;
      var updatedCount = 0;

      // 3. المعالجة الدفعية في Drift (Batch Operation)
      await _db.batch((batch) {
        for (final record in deviceRecords) {
          final cleanPhone = _sanitizeNumber(record.phoneNumber);
          final existing = phoneMap[cleanPhone];

          if (existing != null) {
            // جهة الاتصال موجودة: إذا تغيّر الاسم في الهاتف نقوم بتحديثه مع الحفاظ على خصائص الطوارئ والـ ID
            if (existing.name != record.name) {
              batch.update(
                _db.contacts,
                ContactsCompanion(
                  name: Value(record.name),
                  updatedAt: Value(DateTime.now()),
                  isSynced: const Value(false),
                ),
                where: (tbl) => tbl.id.equals(existing.id),
              );
              updatedCount++;
            }
          } else {
            // جهة اتصال جديدة تماماً: نقوم بإضافتها
            final newId = _uuid.v4();
            batch.insert(
              _db.contacts,
              ContactsCompanion.insert(
                id: newId,
                name: record.name,
                phoneNumber: cleanPhone,
                isEmergency: const Value(false),
                isSynced: const Value(false),
              ),
            );
            addedCount++;
          }
        }
      });

      log('CommsRepository: Device contacts reconciled. Added: $addedCount, Updated: $updatedCount');

      // 4. تشغيل المزامنة السحابية غير المعطلة للأسماء غير المزامنة
      syncPendingComms().catchError((Object err) {
        log('CommsRepository: Cloud sync deferred after import: $err');
      });

      return (addedCount: addedCount, updatedCount: updatedCount);
    } catch (e, st) {
      log('CommsRepository: Error during contacts synchronization: $e', stackTrace: st);
      return (addedCount: 0, updatedCount: 0);
    }
  }

  String _sanitizeNumber(String phone) {
    return phone.replaceAll(RegExp(r'[\s\(\)\-\.]'), '').trim();
  }

  @override
  Stream<List<MessagesVaultData>> watchMessages(String contactIdentifier) =>
      _db.watchMessagesForContact(contactIdentifier);

  @override
  Future<List<MessagesVaultData>> getUnreadMessages() =>
      _db.getUnreadMessages();

  @override
  Future<void> markMessagesAsRead(String contactIdentifier) async {
    await _db.markMessagesAsRead(contactIdentifier);
    _cloud.markMessagesAsReadInCloud(contactIdentifier).catchError((Object error) {
      log('CommsRepository: Cloud mark read deferred: $error');
    });
  }

  @override
  Future<String> recordMessage({
    required String contactIdentifier,
    required String senderName,
    required String messageText,
    String platform = 'sms',
    bool isOutgoing = false,
  }) async {
    final id = await _db.insertMessage(
      contactIdentifier: contactIdentifier,
      senderName: senderName,
      messageText: messageText,
      platform: platform,
      isOutgoing: isOutgoing,
    );

    _cloud.syncMessage(
      id: id,
      contactIdentifier: contactIdentifier,
      senderName: senderName,
      messageText: messageText,
      platform: platform,
      isOutgoing: isOutgoing,
    ).catchError((Object error) {
      log('CommsRepository: Cloud message sync deferred: $error');
    });

    return id;
  }

  @override
  Future<String> triggerEmergencySos({
    double? latitude,
    double? longitude,
    int? batteryLevel,
  }) async {
    final settings = await _db.getSettings();
    final shareGps = settings.shareGpsOnSos;
    final actualBattery = batteryLevel ?? await _hardware.getBatteryPercentage();

    double actualLat = latitude ?? 0.0;
    double actualLng = longitude ?? 0.0;

    if (shareGps && (latitude == null || longitude == null)) {
      final coords = await _hardware.getCurrentLocation();
      if (coords != null) {
        actualLat = coords.latitude;
        actualLng = coords.longitude;
      }
    }

    final effectiveLat = shareGps ? actualLat : 0.0;
    final effectiveLng = shareGps ? actualLng : 0.0;

    final googleMapsUrl = (shareGps && effectiveLat != 0.0 && effectiveLng != 0.0)
        ? 'https://maps.google.com/?q=$effectiveLat,$effectiveLng'
        : (shareGps ? 'GPS Unavailable (Searching satellites...)' : 'GPS Sharing Disabled');

    log('CommsRepository: SOS Triggered! Lat: $effectiveLat, Lng: $effectiveLng, Battery: $actualBattery%');

    final alertId = await _db.insertSosAlert(
      latitude: effectiveLat,
      longitude: effectiveLng,
      batteryLevel: actualBattery,
      googleMapsUrl: googleMapsUrl,
    );

    _cloud.broadcastEmergencySos(
      id: alertId,
      latitude: effectiveLat,
      longitude: effectiveLng,
      batteryLevel: actualBattery,
    ).catchError((Object error) {
      log('CommsRepository: Cloud SOS broadcast deferred: $error');
    });

    if (settings.autoDialEmergency) {
      final emergencyContacts = await _db.getEmergencyContacts();
      if (emergencyContacts.isNotEmpty) {
        final primary = emergencyContacts.first;
        await _hardware.callPhoneNumber(primary.phoneNumber);
      }
    }

    return alertId;
  }

  @override
  Future<void> restoreCommsFromCloud() async {
    if (!_cloud.isAuthenticated) return;
    try {
      final cloudContacts = await _cloud.fetchContacts();
      for (final c in cloudContacts) {
        await _db.into(_db.contacts).insert(
          ContactsCompanion.insert(
            id: c['id'] as String,
            name: c['name'] as String,
            phoneNumber: c['phone_number'] as String,
            relationship: Value(c['relationship'] as String?),
            isEmergency: Value(c['is_emergency'] as bool? ?? false),
            isSynced: const Value(true),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    } catch (e) {
      log('CommsRepository: Contacts cloud restore error: $e');
    }
  }

  @override
  Future<void> syncPendingComms() async {
    if (!_cloud.isAuthenticated) return;
    try {
      final pending = await (_db.select(_db.contacts)
            ..where((c) => c.isSynced.equals(false)))
          .get();
      for (final c in pending) {
        if (c.deletedAt != null) {
          await _cloud.softDeleteContactInCloud(c.id);
          await _db.deleteContact(c.id);
        } else {
          await _cloud.syncContact(
            id: c.id,
            name: c.name,
            phoneNumber: c.phoneNumber,
            relationship: c.relationship,
            isEmergency: c.isEmergency,
          );
          await (_db.update(_db.contacts)..where((tbl) => tbl.id.equals(c.id)))
              .write(const ContactsCompanion(isSynced: Value(true)));
        }
      }
    } catch (e) {
      log('CommsRepository: Pending sync error: $e');
    }
  }
}