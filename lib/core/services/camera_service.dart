// lib/core/services/camera_service.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';

class CameraService {
  CameraService._();
  static final CameraService instance = CameraService._();

  bool _isCapturing = false;

  /// التقاط صورة فورية عند الطلب فقط وإغلاق الكاميرا فوراً
  /// يمنع استهلاك البطارية ويقضي تماماً على انهيار FlutterJNI
  Future<String?> captureAsBase64() async {
    if (_isCapturing) return null;
    _isCapturing = true;

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

      // مسح الملف المؤقت فوراً
      await File(file.path).delete();
      log('CameraService: Scene captured and encoded successfully.');

      return base64String;
    } catch (e, st) {
      log('CameraService: Capture Error: $e', stackTrace: st);
      return null;
    } finally {
      // إغلاق الكاميرا وتحرير العتاد فوراً (يسمح للكشاف بالعمل ويوفر البطارية)
      await controller?.dispose();
      _isCapturing = false;
    }
  }

  void dispose() {}
}
