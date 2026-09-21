// lib/spatial_compass/widgets/compass_transition_layout.dart
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:flutter/material.dart';

class CompassTransitionLayout extends StatelessWidget {
  const CompassTransitionLayout({
    required this.direction,
    required this.centerChild,
    required this.northChild,
    required this.southChild,
    required this.eastChild,
    required this.westChild,
    super.key,
  });

  final CompassDirection direction;
  final Widget centerChild;
  final Widget northChild;
  final Widget southChild;
  final Widget eastChild;
  final Widget westChild;

  Offset _getTargetOffset() {
    switch (direction) {
      case CompassDirection.center:
        return Offset.zero;
      case CompassDirection.north:
        return const Offset(0, 1); // تحريك المركز لأسفل ليظهر الشمال من أعلى
      case CompassDirection.south:
        return const Offset(0, -1); // تحريك المركز لأعلى ليظهر الجنوب
      case CompassDirection.east:
        return const Offset(-1, 0); // تحريك المركز لليسار ليظهر الشرق
      case CompassDirection.west:
        return const Offset(1, 0);  // تحريك المركز لليمين ليظهر الغرب
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetOffset = _getTargetOffset();

    return AnimatedSlide(
      offset: targetOffset,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: Stack(
        children: [
          // 🔘 المركز (Center Canvas)
          centerChild,

          // ⬆️ الشمال (North: فوق المركز بالضبط)
          FractionalTranslation(
            translation: const Offset(0, -1),
            child: northChild,
          ),

          // ⬇️ الجنوب (South: تحت المركز بالضبط)
          FractionalTranslation(
            translation: const Offset(0, 1),
            child: southChild,
          ),

          // ➡️ الشرق (East: يمين المركز)
          FractionalTranslation(
            translation: const Offset(1, 0),
            child: eastChild,
          ),

          // ⬅️ الغرب (West: يسار المركز)
          FractionalTranslation(
            translation: const Offset(-1, 0),
            child: westChild,
          ),
        ],
      ),
    );
  }
}