// lib/spatial_compass/widgets/floor_layouts.dart
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:beacon_os/spatial_compass/widgets/compass_transition_layout.dart';
import 'package:flutter/material.dart';

/// المخطط الفضائي الموحد لأي طابق في النظام (يدعم الطوابق: ... -1, 0, 1, 2 ...)
class SpatialFloorLayout extends StatelessWidget {
  const SpatialFloorLayout({
    required this.direction,
    required this.floorLevel,
    super.key,
  });

  final CompassDirection direction;
  final int floorLevel;

  @override
  Widget build(BuildContext context) {
    return CompassTransitionLayout(
      direction: direction,
      floorLevel: floorLevel,
    );
  }
}

/// توافق عكسي مع الطابق الأرضي
class CoreFloorLayout extends StatelessWidget {
  const CoreFloorLayout({required this.direction, super.key});
  final CompassDirection direction;

  @override
  Widget build(BuildContext context) {
    return SpatialFloorLayout(
      direction: direction,
      floorLevel: 0,
    );
  }
}

/// توافق عكسي مع طابق الإعدادات
class SettingsFloorLayout extends StatelessWidget {
  const SettingsFloorLayout({required this.direction, super.key});
  final CompassDirection direction;

  @override
  Widget build(BuildContext context) {
    return SpatialFloorLayout(
      direction: direction,
      floorLevel: 1,
    );
  }
}