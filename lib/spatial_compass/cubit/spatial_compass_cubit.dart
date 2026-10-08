// lib/spatial_compass/cubit/spatial_compass_cubit.dart
import 'dart:developer';
import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:beacon_os/core/spatial_kernel/spatial_topology.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:bloc/bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class SpatialCompassCubit extends Cubit<SpatialCompassState> {
  SpatialCompassCubit({
    required AssistantRepository assistantRepository,
    required SpatialTopology topology,
    HapticManager? hapticManager,
    SoundController? soundController,
  })  : _assistant = assistantRepository,
        _topology = topology,
        _haptics = hapticManager ?? HapticManager.instance,
        _sound = soundController ?? SoundController.instance,
        super(const SpatialCompassState());

  final AssistantRepository _assistant;
  final SpatialTopology _topology;
  final HapticManager _haptics;
  final SoundController _sound;

  // ===========================================================================
  // 🏢 1. التحكم الرأسي متعدد الطوابق (Dynamic Z-Axis Vertical Control)
  // ===========================================================================

  Future<void> ascend() async {
    final nextFloor = state.currentFloor + 1;
    final available = _topology.availableFloors;
    if (available.isNotEmpty && !available.contains(nextFloor)) return;
    await jumpToFloor(nextFloor);
  }

  Future<void> descend() async {
    final nextFloor = state.currentFloor - 1;
    final available = _topology.availableFloors;
    if (available.isNotEmpty && !available.contains(nextFloor)) return;
    await jumpToFloor(nextFloor);
  }

  Future<void> jumpToFloor(int targetFloor) async {
    if (state.currentFloor == targetFloor) return;

    final isAscending = targetFloor > state.currentFloor;
    if (isAscending) {
      // 📳 تحديث: نبضة نجاح لطيفة وناعمة بدلاً من نبضات إنذار الطوارئ
      await _haptics.successNotification();
      await _sound.play(SoundCue.elevatorUp, floorLevel: targetFloor);
    } else {
      await _haptics.successNotification();
      await _sound.play(SoundCue.elevatorDown, floorLevel: targetFloor);
    }

    emit(state.copyWith(currentFloor: targetFloor));
  }

  Future<void> goToSettingsFloor() => jumpToFloor(1);
  Future<void> returnToGroundFloor() => jumpToFloor(0);

  void toggleFloor() {
    if (state.currentFloor == 0) {
      goToSettingsFloor();
    } else {
      returnToGroundFloor();
    }
  }

  // ===========================================================================
  // 🧭 2. التنقل الأفقي بين الغرف (XY-Axis Pan)
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

    // 🌟 استدعاء المحرك النغمي الجديد ذي الطبقات المتمايزة
    await _sound.playCompassMove(
      direction: destination,
      floorLevel: state.currentFloor,
    );

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
    final module = _topology.moduleAt(state.currentFloor, state.currentDirection);
    final announcement = module?.getFloorTitle(state.currentFloor) ??
        '${state.currentDirection.name.toUpperCase()} Floor ${state.currentFloor}';

    await _assistant.stopSpeaking();
    await _assistant.speak(announcement);
    log('SpatialCompass: Context Requested -> "$announcement"');
  }
}