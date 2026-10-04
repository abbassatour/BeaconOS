// lib/spatial_compass/models/spatial_room.dart
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:flutter/widgets.dart';

extension CompassDirectionSpatialX on CompassDirection {
  /// الإزاحة الفضائية لكل غرفة بالنسبة للمركز داخل مصفوفة التحويلات
  Offset get translation {
    switch (this) {
      case CompassDirection.center:
        return Offset.zero;
      case CompassDirection.north:
        return const Offset(0, -1);
      case CompassDirection.south:
        return const Offset(0, 1);
      case CompassDirection.east:
        return const Offset(1, 0);
      case CompassDirection.west:
        return const Offset(-1, 0);
    }
  }

  /// رمز السهم التعبيري الدال على الاتجاه
  String get arrowSymbol {
    switch (this) {
      case CompassDirection.center:
        return '⏺️';
      case CompassDirection.north:
        return '⬆️';
      case CompassDirection.south:
        return '⬇️';
      case CompassDirection.east:
        return '➡️';
      case CompassDirection.west:
        return '⬅️';
    }
  }

  /// التلميح الحركي لكيفية العودة للمركز بحسب موقع المستخدم الحالي
  String get returnGestureHint {
    switch (this) {
      case CompassDirection.center:
        return 'At Center';
      case CompassDirection.north:
        return 'Swipe DOWN ⬇️';
      case CompassDirection.south:
        return 'Swipe UP ⬆️';
      case CompassDirection.east:
        return 'Swipe LEFT ⬅️';
      case CompassDirection.west:
        return 'Swipe RIGHT ➡️';
    }
  }
}