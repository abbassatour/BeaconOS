// lib/spatial_compass/widgets/compass_transition_layout.dart
import 'package:beacon_os/core/spatial_kernel/spatial_topology.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:beacon_os/spatial_compass/models/spatial_room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CompassTransitionLayout extends StatelessWidget {
  const CompassTransitionLayout({
    required this.direction,
    required this.floorLevel,
    this.isSettingsFloor, // للتوافق العكسي
    super.key,
  });

  final CompassDirection direction;
  final int floorLevel;
  final bool? isSettingsFloor;

  @override
  Widget build(BuildContext context) {
    final topology = context.read<SpatialTopology>();
    final effectiveFloor = isSettingsFloor != null
        ? (isSettingsFloor! ? 1 : 0)
        : floorLevel;

    final roomsOnFloor = topology.roomsOnFloor(effectiveFloor);

    return Stack(
      children: roomsOnFloor.entries.map((entry) {
        final roomDir = entry.key;
        final module = entry.value;

        return _buildRoomLayer(
          key: ValueKey('floor_${effectiveFloor}_dir_${roomDir.name}'),
          child: module.buildFloorView(context, effectiveFloor),
          translation: roomDir.translation,
          roomDir: roomDir,
        );
      }).toList(),
    );
  }

  /// ⚡️ الفرز الفضائي (Spatial Culling & GPU Optimization):
  /// تفعيل المحركات الحركية (Tickers) والتركيز البصري للغرفة النشطة والمركز فقط
  Widget _buildRoomLayer({
    required Key key,
    required Widget child,
    required Offset translation,
    required CompassDirection roomDir,
  }) {
    final isActive = direction == roomDir;
    final isCenter = roomDir == CompassDirection.center;
    final isProcessingAllowed = isActive || isCenter;

    return FractionalTranslation(
      key: key,
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