// lib/cockpit_dashboard/intents/cockpit_intents.dart
import 'package:beacon_os/core/spatial_kernel/voice_intent_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:launcher_repository/launcher_repository.dart';

/// معالج فحص مستوى البطارية بالمسار السريع (Sub-5ms)
class BatteryStatusIntentHandler extends VoiceIntentHandler {
  @override
  String get intentId => 'BATTERY_STATUS';

  @override
  int get priority => 95;

  @override
  RegExp get fastPathPattern => RegExp(
        r'^(?:battery|what is my battery|battery level|battery status|check battery)',
        caseSensitive: false,
      );

  @override
  Future<LauncherCommandResult> execute(
    BuildContext context,
    VoiceIntentContext intentContext,
  ) async {
    final hardwareRepo = context.read<SystemHardwareRepository>();
    final status = await hardwareRepo.getBatteryStatus();

    return LauncherCommandResult(
      intent: 'BATTERY_STATUS',
      spokenResponse: status,
    );
  }
}

/// معالج تشغيل وإطفاء كشاف الهاتف بالمسار السريع
class FlashlightIntentHandler extends VoiceIntentHandler {
  @override
  String get intentId => 'FLASHLIGHT';

  @override
  int get priority => 95;

  @override
  RegExp get fastPathPattern => RegExp(
        r'^(?:flashlight|torch|turn on flashlight|turn off flashlight|toggle flashlight)',
        caseSensitive: false,
      );

  @override
  Future<LauncherCommandResult> execute(
    BuildContext context,
    VoiceIntentContext intentContext,
  ) async {
    final hardwareRepo = context.read<SystemHardwareRepository>();
    final query = intentContext.normalizedQuery;

    final enable = !query.contains('off');
    await hardwareRepo.toggleFlashlight(enable: enable);

    return LauncherCommandResult(
      intent: 'FLASHLIGHT',
      spokenResponse: enable ? 'Flashlight on.' : 'Flashlight off.',
    );
  }
}

/// معالج قفل الشاشة والعودة لسطح النظام
class LockScreenIntentHandler extends VoiceIntentHandler {
  @override
  String get intentId => 'LOCK_SCREEN';

  @override
  int get priority => 90;

  @override
  RegExp get fastPathPattern => RegExp(
        r'^(?:lock screen|lock phone|sleep|turn off screen)',
        caseSensitive: false,
      );

  @override
  Future<LauncherCommandResult> execute(
    BuildContext context,
    VoiceIntentContext intentContext,
  ) async {
    final hardwareRepo = context.read<SystemHardwareRepository>();
    await hardwareRepo.lockScreen();

    return const LauncherCommandResult(
      intent: 'LOCK_SCREEN',
      spokenResponse: 'Screen locked.',
    );
  }
}

/// معالج الاستعلام عن الوقت والتاريخ الحالي
class TimeDateIntentHandler extends VoiceIntentHandler {
  @override
  String get intentId => 'TIME_AND_DATE';

  @override
  int get priority => 85;

  @override
  RegExp get fastPathPattern => RegExp(
        r'^(?:what time is it|what is the time|current time|what is today|what date is it|what day is it|tell me the time)',
        caseSensitive: false,
      );

  @override
  Future<LauncherCommandResult> execute(
    BuildContext context,
    VoiceIntentContext intentContext,
  ) async {
    final now = DateTime.now();
    final timeStr = DateFormat('h:mm a').format(now);
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    return LauncherCommandResult(
      intent: 'TIME_AND_DATE',
      spokenResponse: 'It is $timeStr on $dateStr.',
    );
  }
}

/// معالج قراءة الملخص الصباحي اليومي الشامل
class DailyBriefingIntentHandler extends VoiceIntentHandler {
  @override
  String get intentId => 'DAILY_BRIEFING';

  @override
  int get priority => 80;

  @override
  RegExp get fastPathPattern => RegExp(
        r'^(?:briefing|daily briefing|morning briefing|overview|what does my day look like)',
        caseSensitive: false,
      );

  @override
  Future<LauncherCommandResult> execute(
    BuildContext context,
    VoiceIntentContext intentContext,
  ) async {
    final tasksRepo = context.read<TaskAgendaRepository>();
    final alarmsRepo = context.read<FocusAlarmsRepository>();
    final hardwareRepo = context.read<SystemHardwareRepository>();

    final now = DateTime.now();
    final timeStr = DateFormat('h:mm a').format(now);
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    final buffer = StringBuffer('Good day. Today is $dateStr, $timeStr. ');

    // 1. فحص المنبه القادم
    final alarms = await alarmsRepo.watchAlarms().first;
    final activeAlarms = alarms.where((a) => a.isActive).toList();
    if (activeAlarms.isNotEmpty) {
      final a = activeAlarms.first;
      final hour12 = a.hour % 12 == 0 ? 12 : a.hour % 12;
      final period = a.hour >= 12 ? 'PM' : 'AM';
      final minStr = a.minute == 0 ? "o'clock" : '${a.minute} minutes past $hour12';
      buffer.write('Next alarm is at $hour12 $period. ');
    } else {
      buffer.write('No active alarms scheduled. ');
    }

    // 2. فحص المهام قيد الإنجاز
    final pending = await tasksRepo.getPendingTasks();
    if (pending.isEmpty) {
      buffer.write('Your agenda is completely clear. ');
    } else {
      buffer.write('You have ${pending.length} pending tasks. Top priority: ${pending.first.title}. ');
    }

    // 3. حالة البطارية
    final battery = await hardwareRepo.getBatteryStatus();
    buffer.write(battery);

    return LauncherCommandResult(
      intent: 'DAILY_BRIEFING',
      spokenResponse: buffer.toString(),
    );
  }
}