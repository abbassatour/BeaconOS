// lib/communications/communications_module.dart
import 'package:beacon_os/communications/intents/comms_intents.dart';
import 'package:beacon_os/communications/view/communications_view.dart';
import 'package:beacon_os/communications/view/settings_comms_room.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/spatial_kernel/spatial_module.dart';
import 'package:beacon_os/core/spatial_kernel/voice_intent_handler.dart';
import 'package:flutter/material.dart';

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
        SaveContactIntentHandler(),   // 👈 مسجل حديثاً لـ SAVE_CONTACT
        DeleteContactIntentHandler(), // 👈 مسجل حديثاً لـ DELETE_CONTACT
        SyncContactsIntentHandler(),
      ];

  @override
  Widget buildFloorView(BuildContext context, int floorLevel) {
    if (floorLevel == 1) {
      return const SettingsCommsRoom(
        key: ValueKey('settings_comms_room_view'),
      );
    }
    return const CommunicationsContentView(
      key: ValueKey('communications_content_view'),
    );
  }
}