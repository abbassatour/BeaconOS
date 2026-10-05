// lib/cockpit_dashboard/cockpit_module.dart
import 'package:beacon_os/cockpit_dashboard/intents/cockpit_intents.dart';
import 'package:beacon_os/cockpit_dashboard/view/cockpit_dashboard_view.dart';
import 'package:beacon_os/cockpit_dashboard/view/settings_core_room.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/spatial_kernel/spatial_module.dart';
import 'package:beacon_os/core/spatial_kernel/voice_intent_handler.dart';
import 'package:flutter/material.dart';

class CockpitModule extends SpatialModule {
  CockpitModule._();
  static final CockpitModule instance = CockpitModule._();

  @override
  String get id => 'cockpit';

  @override
  String get title => 'TODAY COCKPIT';

  @override
  String get shortTitle => 'Cockpit';

  @override
  IconData get icon => Icons.dashboard_rounded;

  @override
  SoundCue get sonicSignature => SoundCue.navCenter;

  @override
  bool supportsFloor(int floorLevel) => floorLevel == 0 || floorLevel == 1;

  @override
  String getFloorTitle(int floorLevel) {
    if (floorLevel == 1) return 'CORE ENGINE & PREFERENCES';
    return title;
  }

  @override
  List<VoiceIntentHandler> get voiceIntents => [
        BatteryStatusIntentHandler(),
        FlashlightIntentHandler(),
        LockScreenIntentHandler(),
        TimeDateIntentHandler(),
        DailyBriefingIntentHandler(),
        OpenAppIntentHandler(),
      ];

  @override
  Widget buildFloorView(BuildContext context, int floorLevel) {
    if (floorLevel == 1) {
      return const SettingsCoreRoom(
        key: ValueKey('settings_core_room_view'),
      );
    }
    return const CockpitDashboardContentView(
      key: ValueKey('cockpit_dashboard_content_view'),
    );
  }
}