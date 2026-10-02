// lib/spatial_compass/widgets/compass_transition_layout.dart
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:beacon_os/spatial_compass/models/spatial_room.dart';
import 'package:flutter/material.dart';

class CompassTransitionLayout extends StatelessWidget {
  const CompassTransitionLayout({
    required this.direction,
    required this.isSettingsFloor,
    super.key,
  });

  final CompassDirection direction;
  final bool isSettingsFloor;

  @override
  Widget build(BuildContext context) {
    // 🌟 بناء الغرف الخمس تلقائياً وبشكل ديناميكي من السجل الموحد
    return Stack(
      children: CompassRegistry.rooms.entries.map((entry) {
        final roomDir = entry.key;
        final room = entry.value;
        final roomView = isSettingsFloor ? room.settingsView : room.groundView;

        return _buildRoomLayer(
          child: roomView,
          translation: roomDir.translation,
          roomDir: roomDir,
        );
      }).toList(),
    );
  }

  /// ⚡️ ترشيد الرندر والفرز الفضائي (Spatial Culling & GPU Optimization)
  Widget _buildRoomLayer({
    required Widget child,
    required Offset translation,
    required CompassDirection roomDir,
  }) {
    final isActive = direction == roomDir;
    final isCenter = roomDir == CompassDirection.center;
    final isProcessingAllowed = isActive || isCenter;

    return FractionalTranslation(
      translation: translation,
      child: RepaintBoundary(
        child: TickerMode(
          enabled: isProcessingAllowed,
          child: ExcludeSemantics(
            excluding: !isActive,
            child: FocusScope(
              canRequestFocus: isActive,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}