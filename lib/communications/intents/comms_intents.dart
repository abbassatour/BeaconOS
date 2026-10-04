// lib/communications/intents/comms_intents.dart
import 'package:beacon_os/core/spatial_kernel/voice_intent_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

/// معالج استغاثة الطوارئ SOS بالمسار السريع الفوري (أعلى أولوية في النظام: 100)
class EmergencySosIntentHandler extends VoiceIntentHandler {
  @override
  String get intentId => 'EMERGENCY_SOS';

  @override
  int get priority => 100; // أولوية سيادية قصوى تسبق كل الأوامر الأخرى

  @override
  RegExp get fastPathPattern => RegExp(
        r'^(?:sos|emergency|help me|mayday|send help)',
        caseSensitive: false,
      );

  @override
  Future<LauncherCommandResult> execute(
    BuildContext context,
    VoiceIntentContext intentContext,
  ) async {
    final commsRepo = context.read<CommsRepository>();

    // إطلاق بث الرادار واستدعاء جهة الطوارئ الأساسية
    final alertId = await commsRepo.triggerEmergencySos(
      latitude: 0.0,
      longitude: 0.0,
      batteryLevel: 100,
    );

    return LauncherCommandResult(
      intent: 'EMERGENCY_SOS',
      spokenResponse:
          'Emergency SOS broadcast initiated! Broadcasting coordinates to family radar and dialing primary contact.',
      actionPayload: alertId,
    );
  }
}

/// معالج الاتصال الهاتفي السريع بجهة اتصال (أولوية مرتفعة: 95)
class CallContactIntentHandler extends VoiceIntentHandler {
  @override
  String get intentId => 'CALL_CONTACT';

  @override
  int get priority => 95;

  @override
  RegExp get fastPathPattern => RegExp(
        r'^(?:call|dial|phone)\s+(.+)',
        caseSensitive: false,
      );

  @override
  Future<LauncherCommandResult> execute(
    BuildContext context,
    VoiceIntentContext intentContext,
  ) async {
    final commsRepo = context.read<CommsRepository>();
    final hardwareRepo = context.read<SystemHardwareRepository>();

    String targetQuery = '';

    // 1. استخراج الاسم من المسار السريع
    final match = fastPathPattern?.firstMatch(intentContext.rawQuery);
    if (match != null && match.groupCount >= 1) {
      targetQuery = match.group(1)?.trim() ?? '';
    }

    // 2. استخراج الاسم من معطيات LLM إذا أتى من المسار الذكي
    if (targetQuery.isEmpty &&
        intentContext.llmParameters.containsKey('contact_name')) {
      targetQuery =
          intentContext.llmParameters['contact_name'] as String? ?? '';
    }

    if (targetQuery.isEmpty) {
      return const LauncherCommandResult(
        intent: 'CALL_CONTACT_FAILED',
        spokenResponse: 'Who would you like me to call?',
      );
    }

    // البحث في قاعدة البيانات المحلية المشفرة (Drift)
    final contact = await commsRepo.findContact(targetQuery);

    if (contact != null) {
      await hardwareRepo.callPhoneNumber(contact.phoneNumber);
      return LauncherCommandResult(
        intent: 'CALL_CONTACT',
        spokenResponse: 'Calling ${contact.name}.',
        actionPayload: contact,
      );
    }

    // إذا كانت القيمة المدخلة أرقاماً مباشرة
    final digitsOnly = targetQuery.replaceAll(RegExp(r'[^\d+]'), '');
    if (digitsOnly.length >= 3) {
      await hardwareRepo.callPhoneNumber(digitsOnly);
      return LauncherCommandResult(
        intent: 'CALL_CONTACT',
        spokenResponse: 'Dialing $digitsOnly.',
      );
    }

    return LauncherCommandResult(
      intent: 'CALL_CONTACT_NOT_FOUND',
      spokenResponse:
          'Could not find a contact named $targetQuery in your vault.',
    );
  }
}