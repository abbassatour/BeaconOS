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
  })  : _repository = repository,
        _haptics = hapticManager ?? HapticManager.instance,
        super(const SpatialCompassState());

  final LauncherRepository _repository;
  final HapticManager _haptics;

  /// معالجة إيماءة التمرير السريع وتحديد المحور المهيمن (Horizontal vs Vertical)
  void handleSwipeGesture({
    required double velocityX,
    required double velocityY,
    required double deltaX,
    required double deltaY,
  }) {
    // تحديد ما إذا كان السحب قوياً بما يكفي لاعتباره إيماءة تنقل
    const velocityThreshold = 280.0;
    const distanceThreshold = 45.0;

    final isHorizontal = deltaX.abs() > deltaY.abs();

    if (state.isAtCenter) {
      // التنقل من المركز إلى أي من الاتجاهات الأربعة
      if (isHorizontal) {
        if (velocityX > velocityThreshold || deltaX > distanceThreshold) {
          // سحب لليمين ➡️ الذهاب للشرق (الذكاء الاصطناعي والرؤية)
          moveTo(CompassDirection.east);
        } else if (velocityX < -velocityThreshold || deltaX < -distanceThreshold) {
          // سحب لليسار ⬅️ الذهاب للغرب (المنبهات والمذاكرة)
          moveTo(CompassDirection.west);
        }
      } else {
        if (velocityY < -velocityThreshold || deltaY < -distanceThreshold) {
          // سحب للأعلى ⬆️ الذهاب للشمال (المهام والأجندة)
          moveTo(CompassDirection.north);
        } else if (velocityY > velocityThreshold || deltaY > distanceThreshold) {
          // سحب للأسفل ⬇️ الذهاب للجنوب (الرسائل ودليل الاتصال)
          moveTo(CompassDirection.south);
        }
      }
    } else {
      // في حال كان المستخدم في أي شاشة فرعية، السحب المعاكس يعيده للمركز
      final current = state.currentDirection;
      var shouldReturn = false;

      if (current == CompassDirection.north && (velocityY > velocityThreshold || deltaY > distanceThreshold)) {
        shouldReturn = true; // سحب للأسفل من الشمال يعود للمركز
      } else if (current == CompassDirection.south && (velocityY < -velocityThreshold || deltaY < -distanceThreshold)) {
        shouldReturn = true; // سحب للأعلى من الجنوب يعود للمركز
      } else if (current == CompassDirection.east && (velocityX < -velocityThreshold || deltaX < -distanceThreshold)) {
        shouldReturn = true; // سحب لليسار من الشرق يعود للمركز
      } else if (current == CompassDirection.west && (velocityX > velocityThreshold || deltaX > distanceThreshold)) {
        shouldReturn = true; // سحب لليمين من الغرب يعود للمركز
      }

      if (shouldReturn) {
        returnToCenter();
      }
    }
  }

  /// الانتقال إلى اتجاه محدد مع تغذية حسية وصوتية مقتضبة
  Future<void> moveTo(CompassDirection destination) async {
    if (state.currentDirection == destination) return;

    await _haptics.successNotification();

    emit(state.copyWith(
      previousDirection: state.currentDirection,
      currentDirection: destination,
      isTransitioning: true,
    ));

    // إعلان صوتي مقتضب باسم الشاشة الجديدة (Accessibility First)
    _announceDirection(destination);

    emit(state.copyWith(isTransitioning: false));
  }

  /// إيماءة الرجوع الموحدة (العودة لبهو النظام المركزي)
  Future<void> returnToCenter() async {
    if (state.isAtCenter) return;
    await moveTo(CompassDirection.center);
  }

  void _announceDirection(CompassDirection direction) {
    String announcement;
    switch (direction) {
      case CompassDirection.north:
        announcement = 'Agenda and Tasks.';
        break;
      case CompassDirection.south:
        announcement = 'Communications and Messages.';
        break;
      case CompassDirection.east:
        announcement = 'AI Spatial Vision Studio.';
        break;
      case CompassDirection.west:
        announcement = 'Focus study cycles and Alarms.';
        break;
      case CompassDirection.center:
        announcement = 'Core Canvas.';
        break;
    }

    // إيقاف أي نطق سابق وإعلان الشاشة فوراً
    _repository.speak(announcement);
    log('SpatialCompass: Transitioned to $direction -> "$announcement"');
  }
}