// lib/spatial_compass/widgets/floor_layouts.dart
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:beacon_os/spatial_compass/widgets/compass_transition_layout.dart';
import 'package:flutter/material.dart';

/// تصميم شاشات الطابق الأرضي الأساسية
class CoreFloorLayout extends StatelessWidget {
  const CoreFloorLayout({required this.direction, super.key});
  final CompassDirection direction;

  @override
  Widget build(BuildContext context) {
    return CompassTransitionLayout(
      direction: direction,
      isSettingsFloor: false,
    );
  }
}

/// تصميم شاشات الطابق الثاني الخاصة بالإعدادات
class SettingsFloorLayout extends StatelessWidget {
  const SettingsFloorLayout({required this.direction, super.key});
  final CompassDirection direction;

  @override
  Widget build(BuildContext context) {
    return CompassTransitionLayout(
      direction: direction,
      isSettingsFloor: true,
    );
  }
}