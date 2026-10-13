// lib/core/services/permission_service.dart
import 'dart:developer';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  static const List<Permission> _requiredPermissions = [
    Permission.microphone,
    Permission.camera,
    Permission.location,
    Permission.contacts,
    Permission.phone,
    Permission.notification,
  ];

  /// طلب الأذونات بطريقة آمنة وغير معطلة لخيط الرسوميات الرئيسي
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    // 🛡️ تجاوز أجهزة سطح المكتب تلقائياً
    if (!Platform.isAndroid && !Platform.isIOS) {
      log('PermissionService: Desktop environment detected. Bypassing mobile permission requests.');
      return {
        for (final perm in _requiredPermissions) perm: PermissionStatus.granted,
      };
    }

    log('PermissionService: Requesting system permissions in background...');
    try {
      // ⚡️ حماية بمهلة زمنية (timeout) حتى لا يتجمد التطبيق إذا علق مربع حوار أندرويد في المحاكي
      final statuses = await _requiredPermissions
          .request()
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () => <Permission, PermissionStatus>{},
          );

      statuses.forEach((permission, status) {
        log('PermissionService: $permission -> $status');
      });
      return statuses;
    } catch (e, st) {
      log('PermissionService: Error or timeout requesting permissions: $e', stackTrace: st);
      return {};
    }
  }

  /// فحص هل الأذونات الحرجة ممنوحة
  Future<bool> hasAllCriticalPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

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