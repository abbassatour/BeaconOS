// lib/spatial_compass/cubit/spatial_compass_state.dart
import 'package:equatable/equatable.dart';

/// الاتجاهات المكانية الأربعة للمركز
enum CompassDirection {
  center, // المركز: قمرة اليوم
  north, // الأعلى: الأجندة والمهام
  south, // الأسفل: الرسائل والتواصل
  east, // اليمين: استوديو الرؤية والذكاء
  west, // اليسار: المذاكرة والمنبهات
}

class SpatialCompassState extends Equatable {
  const SpatialCompassState({
    this.currentDirection = CompassDirection.center,
    this.previousDirection = CompassDirection.center,
    this.isTransitioning = false,
    this.currentFloor = 0, // 0 = الطابق الأرضي، 1 = طابق الإعدادات والمحركات
  });

  final CompassDirection currentDirection;
  final CompassDirection previousDirection;
  final bool isTransitioning;
  final int currentFloor;

  bool get isAtCenter => currentDirection == CompassDirection.center;
  bool get isSettingsFloor => currentFloor == 1;

  SpatialCompassState copyWith({
    CompassDirection? currentDirection,
    CompassDirection? previousDirection,
    bool? isTransitioning,
    int? currentFloor,
  }) {
    return SpatialCompassState(
      currentDirection: currentDirection ?? this.currentDirection,
      previousDirection: previousDirection ?? this.previousDirection,
      isTransitioning: isTransitioning ?? this.isTransitioning,
      currentFloor: currentFloor ?? this.currentFloor,
    );
  }

  @override
  List<Object?> get props => [
    currentDirection,
    previousDirection,
    isTransitioning,
    currentFloor,
  ];
}
