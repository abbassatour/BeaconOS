// lib/spatial_vision/spatial_vision_module.dart
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/spatial_kernel/spatial_module.dart';
import 'package:beacon_os/core/spatial_kernel/voice_intent_handler.dart';
import 'package:beacon_os/spatial_vision/intents/vision_intents.dart';
import 'package:beacon_os/spatial_vision/view/settings_vision_room.dart';
import 'package:beacon_os/spatial_vision/view/spatial_vision_view.dart';
import 'package:flutter/material.dart';

class SpatialVisionModule extends SpatialModule {
  SpatialVisionModule._();
  static final SpatialVisionModule instance = SpatialVisionModule._();

  @override
  String get id => 'vision';

  @override
  String get title => 'AI VISION';

  @override
  String get shortTitle => 'Vision';

  @override
  IconData get icon => Icons.visibility_rounded;

  @override
  SoundCue get sonicSignature => SoundCue.navEast;

  @override
  bool supportsFloor(int floorLevel) => floorLevel == 0 || floorLevel == 1;

  @override
  String getFloorTitle(int floorLevel) {
    if (floorLevel == 1) return 'AI VISION TUNING';
    return title;
  }

  @override
  List<VoiceIntentHandler> get voiceIntents => [
        DescribeSceneIntentHandler(),
        ReadTextVisionIntentHandler(),
        IdentifyCurrencyIntentHandler(),
      ];

  @override
  Widget buildFloorView(BuildContext context, int floorLevel) {
    if (floorLevel == 1) {
      return const SettingsVisionRoom(
        key: ValueKey('settings_vision_room_view'),
      );
    }
    return const SpatialVisionContentView(
      key: ValueKey('spatial_vision_content_view'),
    );
  }
}