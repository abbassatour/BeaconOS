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
        return const Offset(0, 1);
      case CompassDirection.south:
        return const Offset(0, -1);
      case CompassDirection.east:
        return const Offset(-1, 0);
      case CompassDirection.west:
        return const Offset(1, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _getTargetOffset(),
      duration: const Duration(milliseconds: 320),
      curve: Curves.fastOutSlowIn,
      child: Stack(
        children: [
          // 🔘 المركز: قمرة اليوم
          _buildRoomLayer(centerChild, Offset.zero),

          // ⬆️ الشمال: الأجندة
          _buildRoomLayer(northChild, const Offset(0, -1)),

          // ⬇️ الجنوب: التواصل
          _buildRoomLayer(southChild, const Offset(0, 1)),

          // ➡️ الشرق: الرؤية
          _buildRoomLayer(eastChild, const Offset(1, 0)),

          // ⬅️ الغرب: التركيز والمنبهات
          _buildRoomLayer(westChild, const Offset(-1, 0)),
        ],
      ),
    );
  }

  Widget _buildRoomLayer(Widget child, Offset translation) {
    return FractionalTranslation(
      translation: translation,
      child: RepaintBoundary(
        child: child,
      ),
    );
  }
}
