// packages/launcher_repository/lib/src/domains/comms_repository.dart
import 'dart:developer';
import 'package:cloud_sync_api/cloud_sync_api.dart';
import 'package:drift/drift.dart';
import 'package:local_vault_api/local_vault_api.dart';
import 'package:system_hardware_api/system_hardware_api.dart';

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

  /// إطلاق استغاثة الطوارئ مع جلب تلقائي للـ GPS ونسبة البطارية الحقيقية
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
    // ⚡️ 1. قراءة تفضيلات المستخدم من قاعدة البيانات
    final settings = await _db.getSettings();
    final shareGps = settings.shareGpsOnSos;

    // ⚡️ 2. قراءة نسبة البطارية الحقيقية من العتاد
    final actualBattery = batteryLevel ?? await _hardware.getBatteryPercentage();

    // ⚡️ 3. قراءة إحداثيات الـ GPS الحقيقية إذا لم تُمرر
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

    // توليد رابط خرائط جوجل الفعلي
    final googleMapsUrl = (shareGps && effectiveLat != 0.0 && effectiveLng != 0.0)
        ? 'https://maps.google.com/?q=$effectiveLat,$effectiveLng'
        : (shareGps ? 'GPS Unavailable (Searching satellites...)' : 'GPS Sharing Disabled');

    log('CommsRepository: SOS Triggered! Lat: $effectiveLat, Lng: $effectiveLng, Battery: $actualBattery%');

    // ⚡️ 4. حفظ الاستغاثة في الخزنة المشفرة محلياً (Drift)
    final alertId = await _db.insertSosAlert(
      latitude: effectiveLat,
      longitude: effectiveLng,
      batteryLevel: actualBattery,
      googleMapsUrl: googleMapsUrl,
    );

    // ⚡️ 5. بث رادار الاستغاثة سحابياً عبر Supabase
    _cloud.broadcastEmergencySos(
      id: alertId,
      latitude: effectiveLat,
      longitude: effectiveLng,
      batteryLevel: actualBattery,
    ).catchError((Object error) {
      log('CommsRepository: Cloud SOS broadcast deferred: $error');
    });

    // ⚡️ 6. الاتصال التلقائي بجهة الطوارئ الأساسية إن كان الخيار مفعلاً
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