// lib/core/services/onesignal_service.dart
import 'dart:developer';
import 'package:beacon_os/core/constants/api_constants.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  OneSignalService._();
  static final OneSignalService instance = OneSignalService._();

  static Future<void> initialize() async {
    final appId = ApiConstants.oneSignalAppId;
    if (appId.isEmpty) return;

    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.none);
      OneSignal.initialize(appId);
      await OneSignal.Notifications.requestPermission(true);
      log('OneSignalService: Initialized successfully.');
    } catch (e, st) {
      log('OneSignalService: Init error: $e', stackTrace: st);
    }
  }

  /// تسجيل المستخدم لتلقي الملخصات الصباحية اليومية
  Future<void> registerMorningBriefingTag() async {
    try {
      await OneSignal.User.addTags({
        'morning_briefing_enabled': 'true',
        'preferred_time': '08:00',
      });
    } catch (e) {
      log('OneSignal tag error: $e');
    }
  }
}