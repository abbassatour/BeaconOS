// lib/spatial_compass/widgets/floor_layouts.dart
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:beacon_os/spatial_compass/widgets/compass_transition_layout.dart';
import 'package:flutter/material.dart';

/// المخطط الفضائي الموحد لأي طابق في النظام (يدعم الطوابق: ... -1, 0, 1, 2 ...)
/// مغلف بـ [RepaintBoundary] لضمان عزل الكاش الرسومي على كرت الشاشة (GPU Raster Cache)
/// ومنع إعادة رسم الغرف أثناء تحولات المنظور ثلاثي الأبعاد.
class SpatialFloorLayout extends StatelessWidget {
  const SpatialFloorLayout({
    required this.direction,
    required this.floorLevel,
    this.panOffset = Offset.zero,
    super.key,
  });

  final CompassDirection direction;
  final int floorLevel;
  final Offset panOffset;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CompassTransitionLayout(
        key: ValueKey('compass_transition_floor_$floorLevel'),
        direction: direction,
        floorLevel: floorLevel,
        panOffset: panOffset,
      ),
    );
  }
}

/// توافق عكسي مع الطابق الأرضي
class CoreFloorLayout extends StatelessWidget {
  const CoreFloorLayout({
    required this.direction,
    this.panOffset = Offset.zero,
    super.key,
  });

  final CompassDirection direction;
  final Offset panOffset;

  @override
  Widget build(BuildContext context) {
    return SpatialFloorLayout(
      direction: direction,
      floorLevel: 0,
      panOffset: panOffset,
    );
  }
}

/// توافق عكسي مع طابق الإعدادات
class SettingsFloorLayout extends StatelessWidget {
  const SettingsFloorLayout({
    required this.direction,
    this.panOffset = Offset.zero,
    super.key,
  });

  final CompassDirection direction;
  final Offset panOffset;

  @override
  Widget build(BuildContext context) {
    return SpatialFloorLayout(
      direction: direction,
      floorLevel: 1,
      panOffset: panOffset,
    );
  }
}