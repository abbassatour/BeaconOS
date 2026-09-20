// packages/system_hardware_api/lib/src/hardware_client.dart
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class HardwareClient {
  HardwareClient();

  final Battery _battery = Battery();
  
  // قناة الاتصال مع كود الـ Kotlin (سنقوم ببرمجة الكود الأصلي لاحقاً في الـ MainActivity)
  static const MethodChannel _systemChannel = MethodChannel('com.beaconos/system');

  /// جلب مستوى البطارية وحالتها كنص مقروء للذكاء الاصطناعي
  Future<String> getBatteryStatus() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      
      String stateStr = 'discharging';
      if (state == BatteryState.charging) stateStr = 'charging';
      if (state == BatteryState.full) stateStr = 'fully charged';

      return 'Battery is at $level% and currently $stateStr.';
    } catch (e) {
      return 'Unable to read battery level.';
    }
  }

  /// إجراء مكالمة هاتفية سريعة
  Future<bool> callPhoneNumber(String phoneNumber) async {
    // تنظيف الرقم من أي نصوص أو مسافات
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

  /// قفل شاشة الهاتف (يتطلب Accessibility Service في أندرويد)
  Future<bool> lockScreen() async {
    try {
      final result = await _systemChannel.invokeMethod<bool>('lockScreen');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// ضبط منبه في نظام الهاتف
  Future<bool> setSystemAlarm({
    required int hour, 
    required int minute, 
    String label = 'BeaconOS Alarm',
  }) async {
    try {
      final result = await _systemChannel.invokeMethod<bool>(
        'setAlarm',
        {
          'hour': hour,
          'minute': minute,
          'label': label,
        },
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}