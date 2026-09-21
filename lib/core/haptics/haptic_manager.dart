// lib/core/haptics/haptic_manager.dart
import 'dart:async';
import 'package:flutter/services.dart';

class HapticManager {
  HapticManager._();
  static final HapticManager instance = HapticManager._();

  Timer? _listeningPulseTimer;

  /// نبضات خفيفة دورية لطمأنة المستخدم أثناء وضع إصبعه على الشاشة بأن الميكروفون يستمع
  void startListeningPulse() {
    _listeningPulseTimer?.cancel();
    HapticFeedback.mediumImpact();
    _listeningPulseTimer = Timer.periodic(
      const Duration(milliseconds: 350),
      (_) => HapticFeedback.selectionClick(),
    );
  }

  void stopListeningPulse() {
    _listeningPulseTimer?.cancel();
    _listeningPulseTimer = null;
  }

  /// اهتزاز مزدوج يؤكد نجاح العملية
  Future<void> successNotification() async {
    stopListeningPulse();
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// اهتزاز قوي للتنبيه على حدوث خطأ أو إلغاء أمر
  Future<void> errorAlert() async {
    stopListeningPulse();
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  /// نبضات تصاعدية سريعة لحالة الطوارئ SOS
  Future<void> emergencyAlarmPulse() async {
    stopListeningPulse();
    for (var i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  void dispose() {
    stopListeningPulse();
  }
}
