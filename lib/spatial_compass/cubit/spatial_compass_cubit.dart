// lib/spatial_compass/cubit/spatial_compass_cubit.dart
import 'dart:developer';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:bloc/bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class SpatialCompassCubit extends Cubit<SpatialCompassState> {
  SpatialCompassCubit({
    required LauncherRepository repository,
    HapticManager? hapticManager,
  }) : _repository = repository,
       _haptics = hapticManager ?? HapticManager.instance,
       super(const SpatialCompassState());

  final LauncherRepository _repository;
  final HapticManager _haptics;

  // ===========================================================================
  // 🏢 1. التحكم الرأسي بالطوابق (Z-Axis Vertical Control)
  // ===========================================================================

  /// الصعود للطابق الثاني مع البقاء في نفس الاتجاه الأفقي المتطابق
  Future<void> goToSettingsFloor() async {
    if (state.isSettingsFloor) return;

    await _haptics.emergencyAlarmPulse(); // نبضة مصعد حسية مميزة
    emit(state.copyWith(currentFloor: 1));

    // إعلان صوتي فوري للغرفة المقابلة في الطابق الثاني
    _announceLocation(
      direction: state.currentDirection,
      isSettingsFloor: true,
    );
  }

  /// النزول للطابق الأرضي إلى نفس الغرفة المقابلة
  Future<void> returnToGroundFloor() async {
    if (!state.isSettingsFloor) return;

    await _haptics.successNotification();
    emit(state.copyWith(currentFloor: 0));

    // إعلان صوتي فوري للغرفة الأساسية في الطابق الأرضي
    _announceLocation(
      direction: state.currentDirection,
      isSettingsFloor: false,
    );
  }

  /// تبديل الطابق الرأسي (زر أو إيماءة المصعد)
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

  /// معالجة إيماءات السحب بالأصبع الواحد (تعمل بنفس التطابق في كلا الطابقين)
  void handleSwipeGesture({
    required double velocityX,
    required double velocityY,
    required double deltaX,
    required double deltaY,
  }) {
    const velocityThreshold = 250.0;
    const distanceThreshold = 40.0;
    final isHorizontal = deltaX.abs() > deltaY.abs();

    if (state.isAtCenter) {
      if (isHorizontal) {
        // سحب لليسار ⬅️ = الانتقال شرقاً (غرفة الرؤية / إعدادات الرؤية)
        if (velocityX < -velocityThreshold || deltaX < -distanceThreshold) {
          moveTo(CompassDirection.east);
        }
        // سحب لليمين ➡️ = الانتقال غرباً (غرفة التركيز والمنبهات / إعدادات التركيز)
        else if (velocityX > velocityThreshold || deltaX > distanceThreshold) {
          moveTo(CompassDirection.west);
        }
      } else {
        // سحب للأعلى ⬆️ = الانتقال جنوباً (غرفة التواصل والرسائل / إعدادات الطوارئ)
        if (velocityY < -velocityThreshold || deltaY < -distanceThreshold) {
          moveTo(CompassDirection.south);
        }
        // سحب للأسفل ⬇️ = الانتقال شمالاً (غرفة الأجندة / إعدادات المهام)
        else if (velocityY > velocityThreshold || deltaY > distanceThreshold) {
          moveTo(CompassDirection.north);
        }
      }
    } else {
      // العودة للمركز الحالي عبر السحب في الاتجاه المعاكس
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

  /// الانتقال إلى اتجاه محدد داخل نفس الطابق
  Future<void> moveTo(CompassDirection destination) async {
    if (state.currentDirection == destination) return;

    await _haptics.successNotification();

    emit(
      state.copyWith(
        previousDirection: state.currentDirection,
        currentDirection: destination,
        isTransitioning: false,
      ),
    );

    _announceLocation(
      direction: destination,
      isSettingsFloor: state.isSettingsFloor,
    );
  }

  /// العودة لمركز الطابق الحالي
  Future<void> returnToCenter() async {
    if (state.isAtCenter) return;
    await moveTo(CompassDirection.center);
  }

  // ===========================================================================
  // 🔊 3. النظام الصوتي الموجه للمكفوفين (Spatial Audio Announcements)
  // ===========================================================================

  void _announceLocation({
    required CompassDirection direction,
    required bool isSettingsFloor,
  }) {
    final announcement = _buildAnnouncementText(
      direction: direction,
      isSettingsFloor: isSettingsFloor,
    );

    _repository.speak(announcement);
    log('SpatialCompass: Announced -> "$announcement"');
  }

  String _buildAnnouncementText({
    required CompassDirection direction,
    required bool isSettingsFloor,
  }) {
    if (isSettingsFloor) {
      // إعلانات الطابق الثاني (غرف المحركات والإعدادات)
      switch (direction) {
        case CompassDirection.center:
          return 'Floor Two: System Core and Preferences.';
        case CompassDirection.north:
          return 'Floor Two: Agenda and Task Preferences.';
        case CompassDirection.south:
          return 'Floor Two: Emergency Radar and Communications Settings.';
        case CompassDirection.east:
          return 'Floor Two: AI Vision Engine and Inspector Settings.';
        case CompassDirection.west:
          return 'Floor Two: Focus Intervals and Alarm Tuning.';
      }
    } else {
      // إعلانات الطابق الأرضي (غرف الحياة اليومية والعمليات)
      switch (direction) {
        case CompassDirection.center:
          return 'Today Cockpit.';
        case CompassDirection.north:
          return 'Agenda and Tasks.';
        case CompassDirection.south:
          return 'Communications and Messages.';
        case CompassDirection.east:
          return 'AI Spatial Vision Studio.';
        case CompassDirection.west:
          return 'Focus study cycles and Alarms.';
      }
    }
  }
}
