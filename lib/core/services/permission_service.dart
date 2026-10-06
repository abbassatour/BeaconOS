// lib/core/services/permission_service.dart
import 'dart:developer';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  /// قائمة الأذونات الأساسية لتشغيل كامل قدرات BeaconOS
  static const List<Permission> _requiredPermissions = [
    Permission.microphone,
    Permission.camera,
    Permission.location,
    Permission.contacts,
    Permission.phone,
    Permission.notification,
  ];

  /// طلب كافة الأذونات دفعة واحدة
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    log('PermissionService: Requesting all system permissions...');
    try {
      final statuses = await _requiredPermissions.request();

      statuses.forEach((permission, status) {
        log('PermissionService: $permission -> $status');
      });

      return statuses;
    } catch (e, st) {
      log('PermissionService: Error requesting permissions: $e', stackTrace: st);
      return {};
    }
  }

  /// فحص هل الأذونات الحرجة ممنوحة
  Future<bool> hasAllCriticalPermissions() async {
    for (final perm in [
      Permission.microphone,
      Permission.camera,
      Permission.location,
    ]) {
      final status = await perm.status;
      if (!status.isGranted) return false;
    }
    return true;
  }
}