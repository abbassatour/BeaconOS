// lib/agenda/agenda_module.dart
import 'package:beacon_os/agenda/cubit/agenda_cubit.dart';
import 'package:beacon_os/agenda/intents/agenda_intents.dart';
import 'package:beacon_os/agenda/view/agenda_view.dart';
import 'package:beacon_os/agenda/view/settings_agenda_room.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/spatial_kernel/spatial_module.dart';
import 'package:beacon_os/core/spatial_kernel/voice_intent_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class AgendaModule extends SpatialModule {
  AgendaModule._();
  static final AgendaModule instance = AgendaModule._();

  @override
  String get id => 'agenda';

  @override
  String get title => 'AGENDA & TASKS';

  @override
  String get shortTitle => 'Agenda';

  @override
  IconData get icon => Icons.calendar_today_rounded;

  @override
  SoundCue get sonicSignature => SoundCue.navWest;

  @override
  bool supportsFloor(int floorLevel) => floorLevel == 0 || floorLevel == 1;

  @override
  String getFloorTitle(int floorLevel) {
    if (floorLevel == 1) return 'AGENDA PREFERENCES';
    return title;
  }

  @override
  List<VoiceIntentHandler> get voiceIntents => [
        ReadTasksIntentHandler(),
        SaveTaskIntentHandler(),
        SaveMemoIntentHandler(),
        CompleteTaskIntentHandler(), // 👈 تسجيل إتمام المهام
        DeleteTaskIntentHandler(),   // 👈 تسجيل حذف المهام
      ];

  @override
  Widget buildFloorView(BuildContext context, int floorLevel) {
    return BlocProvider(
      create: (context) => AgendaCubit(
        taskRepository: context.read<TaskAgendaRepository>(),
        assistantRepository: context.read<AssistantRepository>(),
        settingsRepository: context.read<SettingsRepository>(), // 👈 حقن الإعدادات
      ),
      child: Builder(
        builder: (ctx) {
          if (floorLevel == 1) {
            return const SettingsAgendaRoom();
          }
          return const AgendaContentView();
        },
      ),
    );
  }
}