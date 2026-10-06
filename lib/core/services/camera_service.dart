// lib/core/services/camera_service.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

enum CameraPermissionState {
  granted,
  denied,
  permanentlyDenied,
}

class CameraService {
  CameraService._();
  static final CameraService instance = CameraService._();

  bool _isCapturing = false;

  /// فحص حالة إذن الكاميرا الحالية
  Future<CameraPermissionState> getPermissionState() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      return CameraPermissionState.granted;
    } else if (status.isPermanentlyDenied) {
      return CameraPermissionState.permanentlyDenied;
    } else {
      return CameraPermissionState.denied;
    }
  }

  /// طلب إذن استخدام الكاميرا من نظام أندرويد
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// فتح شاشة إعدادات التطبيق في النظام في حال الرفض الدائم
  Future<bool> openSettings() async {
    return openAppSettings();
  }

  /// التقاط صورة فورية مع فحص وطلب الإذن تلقائياً وتحرير الموارد فوراً
  Future<String?> captureAsBase64() async {
    if (_isCapturing) return null;
    _isCapturing = true;

    // 1. فحص إذن الكاميرا وطلبه وقت التشغيل إن لم يكن ممنوحاً
    final isGranted = await Permission.camera.isGranted;
    if (!isGranted) {
      final requested = await Permission.camera.request();
      if (!requested.isGranted) {
        log('CameraService: Camera permission denied by user.');
        _isCapturing = false;
        return null;
      }
    }

    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        log('CameraService: No cameras found on device.');
        return null;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // تهيئة مؤقتة لالتقاط لقطة واحدة فقط
      controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      final XFile file = await controller.takePicture();

      final bytes = await File(file.path).readAsBytes();
      final base64String = base64Encode(bytes);

      // مسح الملف المؤقت فوراً لحماية الخصوصية وتوفير المساحة
      await File(file.path).delete();
      log('CameraService: Scene captured and encoded successfully.');

      return base64String;
    } on CameraException catch (e, st) {
      log('CameraService: CameraException [${e.code}]: ${e.description}', stackTrace: st);
      return null;
    } catch (e, st) {
      log('CameraService: General Capture Error: $e', stackTrace: st);
      return null;
    } finally {
      // إغلاق الكاميرا وتحرير العتاد فوراً (يسمح للكشاف بالعمل ويمنع استهلاك البطارية)
      await controller?.dispose();
      _isCapturing = false;
    }
  }

  void dispose() {}
}