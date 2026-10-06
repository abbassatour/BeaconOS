// lib/focus_alarms/focus_alarms_module.dart
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/spatial_kernel/spatial_module.dart';
import 'package:beacon_os/core/spatial_kernel/voice_intent_handler.dart';
import 'package:beacon_os/focus_alarms/intents/focus_intents.dart';
import 'package:beacon_os/focus_alarms/view/focus_alarms_view.dart';
import 'package:beacon_os/focus_alarms/view/settings_focus_room.dart';
import 'package:flutter/material.dart';

class FocusAlarmsModule extends SpatialModule {
  FocusAlarmsModule._();
  static final FocusAlarmsModule instance = FocusAlarmsModule._();

  @override
  String get id => 'focus_alarms';

  @override
  String get title => 'FOCUS & ALARMS';

  @override
  String get shortTitle => 'Focus';

  @override
  IconData get icon => Icons.hourglass_top_rounded;

  @override
  SoundCue get sonicSignature => SoundCue.navNorth;

  @override
  bool supportsFloor(int floorLevel) => floorLevel == 0 || floorLevel == 1;

  @override
  String getFloorTitle(int floorLevel) {
    if (floorLevel == 1) return 'FOCUS & ALARMS TUNING';
    return title;
  }

  @override
  List<VoiceIntentHandler> get voiceIntents => [
        SetAlarmIntentHandler(),
        ToggleAlarmIntentHandler(), // 👈 مسجل حديثاً لـ TOGGLE_ALARM
        DeleteAlarmIntentHandler(), // 👈 مسجل حديثاً لـ DELETE_ALARM
      ];

  @override
  Widget buildFloorView(BuildContext context, int floorLevel) {
    if (floorLevel == 1) {
      return const SettingsFocusRoom(
        key: ValueKey('settings_focus_room_view'),
      );
    }
    return const FocusAlarmsContentView(
      key: ValueKey('focus_alarms_content_view'),
    );
  }
}