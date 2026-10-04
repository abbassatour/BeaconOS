// lib/focus_alarms/intents/focus_intents.dart
import 'package:beacon_os/core/spatial_kernel/voice_intent_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

/// معالج ضبط المنبه بالمسار السريع (Sub-5ms Fast Path)
class SetAlarmIntentHandler extends VoiceIntentHandler {
  @override
  String get intentId => 'SET_ALARM';

  @override
  int get priority => 90; // أولوية مرتفعة لسرعة الاستجابة

  @override
  RegExp get fastPathPattern =>
      RegExp(r'.*alarm.*', caseSensitive: false);

  @override
  Future<LauncherCommandResult> execute(
    BuildContext context,
    VoiceIntentContext intentContext,
  ) async {
    final repo = context.read<LauncherRepository>();
    final query = intentContext.normalizedQuery;

    // استخراج التوقيت محلياً بسرعة خاطفة
    final match = RegExp(r'(\d{1,2})(?::(\d{2}))?').firstMatch(query);
    if (match != null) {
      var hour = int.tryParse(match.group(1) ?? '8') ?? 8;
      final minute = int.tryParse(match.group(2) ?? '0') ?? 0;

      if (query.contains('pm') && hour < 12) hour += 12;
      if (query.contains('am') && hour == 12) hour = 0;

      await repo.focusAlarms.createAlarm(
        hour: hour,
        minute: minute,
        label: 'Beacon Alarm',
      );

      final timeDisplay =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      return LauncherCommandResult(
        intent: 'SET_ALARM',
        spokenResponse: 'Alarm has been set for $timeDisplay.',
      );
    }

    return const LauncherCommandResult(
      intent: 'SET_ALARM_FAILED',
      spokenResponse: 'Please specify the alarm time, for example 7 AM.',
    );
  }
}