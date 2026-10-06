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
    this.panOffset = Offset.zero,
    this.isSettingsFloor,
    super.key,
  });

  final CompassDirection direction;
  final int floorLevel;
  final Offset panOffset;
  final bool? isSettingsFloor;

  @override
  Widget build(BuildContext context) {
    final topology = context.read<SpatialTopology>();
    final effectiveFloor = isSettingsFloor != null
        ? (isSettingsFloor! ? 1 : 0)
        : floorLevel;

    final roomsOnFloor = topology.roomsOnFloor(effectiveFloor);
    final size = MediaQuery.of(context).size;

    return Stack(
      clipBehavior: Clip.none, // 🛡️ تمنع اختفاء أو قص الغرف أثناء التمرير خارج الشاشة
      children: roomsOnFloor.entries.map((entry) {
        final roomDir = entry.key;
        final module = entry.value;

        return _buildRoomLayer(
          key: ValueKey('floor_${effectiveFloor}_dir_${roomDir.name}'),
          context: context,
          child: module.buildFloorView(context, effectiveFloor),
          roomDir: roomDir,
          screenWidth: size.width,
          screenHeight: size.height,
        );
      }).toList(),
    );
  }

  /// ⚡️ معالجة التمركز الحقيقي للغرف والتحكم بالنقرات (Hit-Test Safe Architecture)
  Widget _buildRoomLayer({
    required Key key,
    required BuildContext context,
    required Widget child,
    required CompassDirection roomDir,
    required double screenWidth,
    required double screenHeight,
  }) {
    final isActive = direction == roomDir;
    final isCenter = roomDir == CompassDirection.center;
    final isProcessingAllowed = isActive || isCenter;

    // 🌟 حساب الإزاحة الفعلية المباشرة لكل غرفة على الشاشة
    final roomOffset = Offset(
      roomDir.translation.dx * screenWidth + panOffset.dx,
      roomDir.translation.dy * screenHeight + panOffset.dy,
    );

    return Transform.translate(
      key: key,
      offset: roomOffset,
      child: RepaintBoundary(
        child: TickerMode(
          enabled: isProcessingAllowed,
          child: IgnorePointer(
            ignoring: !isActive, // 🛡️ الغرفة غير النشطة لا تعترض النقرات أبداً
            child: ExcludeSemantics(
              excluding: !isActive,
              child: FocusScope(
                canRequestFocus: isActive,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}