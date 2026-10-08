// lib/core/physics/spatial_physics.dart
import 'package:flutter/physics.dart';

/// محرك الفيزياء الحركية الفضائية (Spatial Motion Physics Engine)
/// يعتمد على نوابض Runge-Kutta بدلاً من المنحنيات الزمنية الثابتة.
class SpatialPhysics {
  SpatialPhysics._();

  // ===========================================================================
  // 📐 1. تكوينات النوابض (Spring Descriptions)
  // ===========================================================================

  /// نابض الانتقال الأفقي والرأسي (XY-Axis Pan) للغرف
  static const SpringDescription panSpring = SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 26.8, 
  );

  /// 🌟 نابض الانتقال الرأسي في العمق (Z-Axis Spread/Pinch) للطوابق
  /// تم تحسينه بنسبة تخميد ζ ≈ 0.80 ليمنح انتقالاً زبدياً سلساً بلا قساوة أو بطء
  static const SpringDescription zAxisSpring = SpringDescription(
    mass: 1.0,
    stiffness: 260.0,
    damping: 26.0,
  );

  // ===========================================================================
  // 🚀 2. مولدات المحاكاة (Simulation Generators)
  // ===========================================================================

  /// يولد محاكاة حركية بانسيابية للانتقال بين الغرف بناءً على سرعة الإفلات
  static SpringSimulation createPanSimulation({
    required double start,
    required double end,
    required double velocity,
  }) {
    return SpringSimulation(
      panSpring,
      start,
      end,
      velocity,
    );
  }

  /// يولد محاكاة حركية لانتقالات الغوص في الطوابق (Z-Axis)
  static SpringSimulation createZAxisSimulation({
    required double start,
    required double end,
    required double velocity,
  }) {
    return SpringSimulation(
      zAxisSpring,
      start,
      end,
      velocity,
    );
  }

  // ===========================================================================
  // ✋ 3. حسابات الاحتكاك والمطاطية (Rubber-banding)
  // ===========================================================================

  static double applyRubberBanding({
    required double delta,
    required double limit,
    double stiffness = 0.55,
  }) {
    if (delta == 0) return 0.0;
    final absDelta = delta.abs();
    final rubberDelta = limit * (1.0 - (1.0 / ((absDelta * stiffness / limit) + 1.0)));
    return delta < 0 ? -rubberDelta : rubberDelta;
  }
}