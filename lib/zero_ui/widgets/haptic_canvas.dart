// lib/zero_ui/widgets/haptic_canvas.dart
import 'dart:async';
import 'package:flutter/material.dart';

class HapticCanvas extends StatefulWidget {
  const HapticCanvas({
    required this.child,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onTripleTap,
    super.key,
  });

  final Widget child;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onTripleTap;

  @override
  State<HapticCanvas> createState() => _HapticCanvasState();
}

class _HapticCanvasState extends State<HapticCanvas> {
  int _tapCount = 0;
  Timer? _tapResetTimer;

  void _registerTap() {
    _tapCount++;
    _tapResetTimer?.cancel();

    if (_tapCount == 3) {
      _tapCount = 0;
      widget.onTripleTap?.call();
      return;
    }

    _tapResetTimer = Timer(const Duration(milliseconds: 400), () {
      _tapCount = 0;
    });
  }

  @override
  void dispose() {
    _tapResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _registerTap(),
      onLongPressStart: (_) => widget.onLongPressStart?.call(),
      onLongPressEnd: (_) => widget.onLongPressEnd?.call(),
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -300) {
          widget.onSwipeUp?.call();
        } else if (velocity > 300) {
          widget.onSwipeDown?.call();
        }
      },
      child: SizedBox.expand(
        child: widget.child,
      ),
    );
  }
}