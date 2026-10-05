// packages/system_hardware_api/lib/src/hardware_client.dart
import 'dart:developer';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// كائن يمثل الإحداثيات الجغرافية الحقيقية للجهاز
class GpsCoordinates {
  const GpsCoordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  String toString() => 'GpsCoordinates($latitude, $longitude)';
}

class HardwareClient {
  HardwareClient();

  final Battery _battery = Battery();

  // قناة الاتصال مع طبقة أندرويد الأصلية في MainActivity.kt
  static const MethodChannel _systemChannel = MethodChannel(
    'com.beaconos/system',
  );

  /// جلب مستوى البطارية وحالتها كنص مقروء للمستخدم
  Future<String> getBatteryStatus() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      var stateStr = 'discharging';
      if (state == BatteryState.charging) stateStr = 'charging';
      if (state == BatteryState.full) stateStr = 'fully charged';

      return 'Battery is at $level% and currently $stateStr.';
    } catch (e) {
      return 'Unable to read battery level.';
    }
  }

  /// جلب نسبة شحن البطارية الحقيقية كرقم صحيح (مثلاً: 82)
  Future<int> getBatteryPercentage() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return 100;
    }
  }

  /// جلب إحداثيات الـ GPS الحقيقية مع التحقق الآمن من الصلاحيات والخدمة
  Future<GpsCoordinates?> getCurrentLocation() async {
    try {
      // 1. فحص هل خدمة الموقع مفعلة في الجهاز
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        log('HardwareClient: Location services are disabled by user.');
        return null;
      }

      // 2. فحص والطلب التلقائي لصلاحيات الموقع
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          log('HardwareClient: Location permission denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        log('HardwareClient: Location permission permanently denied.');
        return null;
      }

      // 3. محاولة جلب الإحداثيات الدقيقة مع مهلة 7 ثوانٍ
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 7),
        ),
      ).catchError((Object error) async {
        log('HardwareClient: Timeout fetching high-accuracy GPS, fallback to last known: $error');
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return last;
        throw error;
      });

      return GpsCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e, st) {
      log('HardwareClient: Error retrieving GPS coordinates: $e', stackTrace: st);
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return GpsCoordinates(
            latitude: lastKnown.latitude,
            longitude: lastKnown.longitude,
          );
        }
      } catch (_) {}
      return null;
    }
  }

  /// إجراء مكالمة هاتفية سريعة ومباشرة
  Future<bool> callPhoneNumber(String phoneNumber) async {
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return false;

    final uri = Uri.parse('tel:$digits');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// ضبط منبه حقيقي في نظام أندرويد دون فتح شاشة الساعة
  Future<bool> setSystemAlarm({
    required int hour,
    required int minute,
    String label = 'BeaconOS Alarm',
  }) async {
    try {
      final result = await _systemChannel.invokeMethod<bool>('setAlarm', {
        'hour': hour,
        'minute': minute,
        'label': label,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// تشغيل أو إطفاء فلاش الكاميرا (الكشاف)
  Future<bool> toggleFlashlight({bool? enable}) async {
    try {
      final result = await _systemChannel.invokeMethod<bool>(
        'toggleFlashlight',
        enable != null ? {'enable': enable} : null,
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// فتح أي تطبيق خارجي مثبت على الهاتف عبر اسم الحزمة
  Future<bool> openApp(String packageName) async {
    try {
      final result = await _systemChannel.invokeMethod<bool>('openApp', {
        'packageName': packageName,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// قفل شاشة الهاتف
  Future<bool> lockScreen() async {
    try {
      final result = await _systemChannel.invokeMethod<bool>('lockScreen');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}