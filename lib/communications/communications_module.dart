// lib/communications/communications_module.dart
import 'package:beacon_os/communications/cubit/communications_cubit.dart';
import 'package:beacon_os/communications/intents/comms_intents.dart';
import 'package:beacon_os/communications/view/communications_view.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/spatial_kernel/spatial_module.dart';
import 'package:beacon_os/core/spatial_kernel/voice_intent_handler.dart';
import 'package:beacon_os/communications/view/settings_comms_room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class CommunicationsModule extends SpatialModule {
  CommunicationsModule._();
  static final CommunicationsModule instance = CommunicationsModule._();

  @override
  String get id => 'communications';

  @override
  String get title => 'COMMUNICATIONS';

  @override
  String get shortTitle => 'Comms';

  @override
  IconData get icon => Icons.chat_bubble_outline_rounded;

  @override
  SoundCue get sonicSignature => SoundCue.navSouth;

  @override
  bool supportsFloor(int floorLevel) => floorLevel == 0 || floorLevel == 1;

  @override
  String getFloorTitle(int floorLevel) {
    if (floorLevel == 1) return 'SAFETY & SOS RADAR PREFERENCES';
    return title;
  }

  @override
  List<VoiceIntentHandler> get voiceIntents => [
        EmergencySosIntentHandler(),
        CallContactIntentHandler(),
      ];

  @override
  Widget buildFloorView(BuildContext context, int floorLevel) {
    return BlocProvider(
      create: (context) => CommunicationsCubit(
        commsRepository: context.read<CommsRepository>(),
        hardwareRepository: context.read<SystemHardwareRepository>(),
        assistantRepository: context.read<AssistantRepository>(), // 👈 التحديث تم هنا
      ),
      child: Builder(
        builder: (ctx) {
          if (floorLevel == 1) {
            // شاشة إعدادات الطوارئ والرادار في الطابق الثاني
            return const SettingsCommsRoom();
          }
          // شاشة جهات الاتصال والرسائل في الطابق الأرضي
          return const CommunicationsContentView();
        },
      ),
    );
  }
}