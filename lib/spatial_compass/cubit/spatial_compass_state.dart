// lib/spatial_compass/cubit/spatial_compass_state.dart
import 'package:equatable/equatable.dart';

/// الاتجاهات المكانية للبوصلة
enum CompassDirection {
  center, // المركز: اللوحة الصوتية الأم
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
  });

  final CompassDirection currentDirection;
  final CompassDirection previousDirection;
  final bool isTransitioning;

  bool get isAtCenter => currentDirection == CompassDirection.center;

  SpatialCompassState copyWith({
    CompassDirection? currentDirection,
    CompassDirection? previousDirection,
    bool? isTransitioning,
  }) {
    return SpatialCompassState(
      currentDirection: currentDirection ?? this.currentDirection,
      previousDirection: previousDirection ?? this.previousDirection,
      isTransitioning: isTransitioning ?? this.isTransitioning,
    );
  }

  @override
  List<Object?> get props => [
    currentDirection,
    previousDirection,
    isTransitioning,
  ];
}
