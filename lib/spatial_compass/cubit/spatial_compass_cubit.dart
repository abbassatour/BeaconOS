// lib/spatial_compass/cubit/spatial_compass_cubit.dart
import 'dart:developer';
import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:bloc/bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class SpatialCompassCubit extends Cubit<SpatialCompassState> {
  SpatialCompassCubit({
    required LauncherRepository repository,
    HapticManager? hapticManager,
    SoundController? soundController,
  })  : _repository = repository,
        _haptics = hapticManager ?? HapticManager.instance,
        _sound = soundController ?? SoundController.instance,
        super(const SpatialCompassState());

  final LauncherRepository _repository;
  final HapticManager _haptics;
  final SoundController _sound;

  // ===========================================================================
  // 🏢 1. التحكم الرأسي بالطوابق (Z-Axis Vertical Control)
  // ===========================================================================

  Future<void> goToSettingsFloor() async {
    if (state.isSettingsFloor) return;

    await _haptics.emergencyAlarmPulse(); // نبضة حسية مميزة
    await _sound.playElevatorUp();        // صوت الصعود فقط (بدون نطق)

    emit(state.copyWith(currentFloor: 1));
  }

  Future<void> returnToGroundFloor() async {
    if (!state.isSettingsFloor) return;

    await _haptics.successNotification();
    await _sound.playElevatorDown();      // صوت النزول فقط (بدون نطق)

    emit(state.copyWith(currentFloor: 0));
  }

  void toggleFloor() {
    if (state.isSettingsFloor) {
      returnToGroundFloor();
    } else {
      goToSettingsFloor();
    }
  }

  // ===========================================================================
  // 🧭 2. التنقل الأفقي المتطابق (XY-Axis Horizontal Navigation)
  // ===========================================================================

  void handleSwipeGesture({
    required double velocityX,
    required double velocityY,
    required double deltaX,
    required double deltaY,
  }) {
    const velocityThreshold = 150.0; 
    const distanceThreshold = 20.0;  
    
    final isHorizontal = deltaX.abs() > deltaY.abs();

    if (state.isAtCenter) {
      if (isHorizontal) {
        if (velocityX < -velocityThreshold || deltaX < -distanceThreshold) {
          moveTo(CompassDirection.east);
        } else if (velocityX > velocityThreshold || deltaX > distanceThreshold) {
          moveTo(CompassDirection.west);
        }
      } else {
        if (velocityY < -velocityThreshold || deltaY < -distanceThreshold) {
          moveTo(CompassDirection.south);
        } else if (velocityY > velocityThreshold || deltaY > distanceThreshold) {
          moveTo(CompassDirection.north);
        }
      }
    } else {
      final current = state.currentDirection;
      var shouldReturn = false;

      if (current == CompassDirection.north &&
          (velocityY < -velocityThreshold || deltaY < -distanceThreshold)) {
        shouldReturn = true;
      } else if (current == CompassDirection.south &&
          (velocityY > velocityThreshold || deltaY > distanceThreshold)) {
        shouldReturn = true;
      } else if (current == CompassDirection.east &&
          (velocityX > velocityThreshold || deltaX > distanceThreshold)) {
        shouldReturn = true;
      } else if (current == CompassDirection.west &&
          (velocityX < -velocityThreshold || deltaX < -distanceThreshold)) {
        shouldReturn = true;
      }

      if (shouldReturn) {
        returnToCenter();
      }
    }
  }

  Future<void> moveTo(CompassDirection destination) async {
    if (state.currentDirection == destination) return;

    await _haptics.successNotification();

    // تشغيل الصوت المكاني المناسب فقط (بدون نطق اسم الصفحة)
    final isSettings = state.isSettingsFloor;
    switch (destination) {
      case CompassDirection.north:
        await _sound.playSwipeNorth(isSettingsFloor: isSettings);
        break;
      case CompassDirection.south:
        await _sound.playSwipeSouth(isSettingsFloor: isSettings);
        break;
      case CompassDirection.east:
        await _sound.playSwipeEast(isSettingsFloor: isSettings);
        break;
      case CompassDirection.west:
        await _sound.playSwipeWest(isSettingsFloor: isSettings);
        break;
      case CompassDirection.center:
        await _sound.playReturnCenter(isSettingsFloor: isSettings);
        break;
    }

    emit(
      state.copyWith(
        previousDirection: state.currentDirection,
        currentDirection: destination,
        isTransitioning: false,
      ),
    );
  }

  Future<void> returnToCenter() async {
    if (state.isAtCenter) return;
    await moveTo(CompassDirection.center);
  }

  // ===========================================================================
  // 🔊 3. النظام الصوتي الموجه للمكفوفين (On-Demand Contextual TTS)
  // ===========================================================================

  /// تُستدعى هذه الدالة فقط عندما ينقر المستخدم بإصبعين على الشاشة لمعرفة مكانه
  Future<void> announceCurrentLocation() async {
    final announcement = _buildQuickAnnouncementText(
      direction: state.currentDirection,
      isSettingsFloor: state.isSettingsFloor,
    );

    // إسكات أي نطق سابق فوراً، ونطق الموقع الحالي
    await _repository.stopSpeaking();
    _repository.speak(announcement);
    log('SpatialCompass: Context Requested -> "$announcement"');
  }

  String _buildQuickAnnouncementText({
    required CompassDirection direction,
    required bool isSettingsFloor,
  }) {
    if (isSettingsFloor) {
      switch (direction) {
        case CompassDirection.center: return 'Core Settings';
        case CompassDirection.north:  return 'Agenda Settings';
        case CompassDirection.south:  return 'Comms Settings';
        case CompassDirection.east:   return 'Vision Settings';
        case CompassDirection.west:   return 'Focus Settings';
      }
    } else {
      switch (direction) {
        case CompassDirection.center: return 'Cockpit';
        case CompassDirection.north:  return 'Agenda';
        case CompassDirection.south:  return 'Comms';
        case CompassDirection.east:   return 'Vision';
        case CompassDirection.west:   return 'Focus';
      }
    }
  }
}