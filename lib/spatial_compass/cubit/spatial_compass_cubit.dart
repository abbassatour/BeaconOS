// lib/spatial_compass/cubit/spatial_compass_cubit.dart
import 'dart:developer';
import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
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
    await _sound.play(SoundCue.elevatorUp); // 🔊 نغمة صعود المصعد

    emit(state.copyWith(currentFloor: 1));
  }

  Future<void> returnToGroundFloor() async {
    if (!state.isSettingsFloor) return;

    await _haptics.successNotification();
    await _sound.play(SoundCue.elevatorDown); // 🔊 نغمة نزول المصعد

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

    // 🎯 تحديد النغمة المكانية عبر الكتالوج المركزي (Type-Safe Pattern Matching)
    final cue = switch (destination) {
      CompassDirection.north => SoundCue.navNorth,
      CompassDirection.south => SoundCue.navSouth,
      CompassDirection.east => SoundCue.navEast,
      CompassDirection.west => SoundCue.navWest,
      CompassDirection.center => SoundCue.navCenter,
    };

    // تشغيل النغمة مع مراعاة رفع النبرة تلقائياً إذا كنا في الطابق الثاني
    await _sound.play(cue, isSettingsFloor: state.isSettingsFloor);

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

  Future<void> announceCurrentLocation() async {
    final announcement = _buildQuickAnnouncementText(
      direction: state.currentDirection,
      isSettingsFloor: state.isSettingsFloor,
    );

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