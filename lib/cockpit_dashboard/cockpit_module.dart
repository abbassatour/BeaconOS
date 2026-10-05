// lib/cockpit_dashboard/cockpit_module.dart
import 'package:beacon_os/cockpit_dashboard/cubit/cockpit_dashboard_cubit.dart';
import 'package:beacon_os/cockpit_dashboard/intents/cockpit_intents.dart';
import 'package:beacon_os/cockpit_dashboard/view/cockpit_dashboard_view.dart';
import 'package:beacon_os/cockpit_dashboard/view/settings_core_room.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/spatial_kernel/spatial_module.dart';
import 'package:beacon_os/core/spatial_kernel/voice_intent_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

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
        OpenAppIntentHandler(), // 👈 تم التسجيل هنا
      ];

  @override
  Widget buildFloorView(BuildContext context, int floorLevel) {
    return BlocProvider(
      create: (context) => CockpitDashboardCubit(
        taskRepository: context.read<TaskAgendaRepository>(),
        focusAlarmsRepository: context.read<FocusAlarmsRepository>(),
        hardwareRepository: context.read<SystemHardwareRepository>(),
        assistantRepository: context.read<AssistantRepository>(),
      ),
      child: Builder(
        builder: (ctx) {
          if (floorLevel == 1) {
            return const SettingsCoreRoom();
          }
          return const CockpitDashboardContentView();
        },
      ),
    );
  }
}