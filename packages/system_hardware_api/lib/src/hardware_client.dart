// packages/system_hardware_api/lib/src/hardware_client.dart
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// فتح أي تطبيق خارجي مثبت على الهاتف عبر اسم الحزمة (Package Name)
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
