// lib/spatial_compass/view/spatial_compass_page.dart
import 'package:beacon_os/agenda/view/agenda_view.dart';
import 'package:beacon_os/communications/view/communications_view.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/focus_alarms/view/focus_alarms_view.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_cubit.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:beacon_os/spatial_compass/widgets/compass_transition_layout.dart';
import 'package:beacon_os/spatial_vision/view/spatial_vision_view.dart';
import 'package:beacon_os/zero_ui/cubit/zero_ui_cubit.dart';
import 'package:beacon_os/zero_ui/view/zero_ui_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class SpatialCompassPage extends StatelessWidget {
  const SpatialCompassPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<LauncherRepository>();

    // 💡 توفير الـ Cubits لجميع الغرف بما فيها المركز ZeroUiCubit
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SpatialCompassCubit(
            repository: repository,
          ),
        ),
        BlocProvider(
          create: (context) => ZeroUiCubit(
            repository: repository,
          ),
        ),
      ],
      child: const _SpatialCompassBody(),
    );
  }
}

class _SpatialCompassBody extends StatefulWidget {
  const _SpatialCompassBody();

  @override
  State<_SpatialCompassBody> createState() => _SpatialCompassBodyState();
}

class _SpatialCompassBodyState extends State<_SpatialCompassBody> {
  // رصد إحداثيات السحب في الشاشة الرئيسية (Center Core)
  Offset _dragStartOffset = Offset.zero;
  Offset _dragEndOffset = Offset.zero;

  // كاشف اللمس المتعدد (Two-Finger Tap) للعودة الفورية للمركز
  int _activePointers = 0;
  DateTime? _multiTouchStartTime;

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
    if (_activePointers == 2) {
      _multiTouchStartTime = DateTime.now();
    }
  }

  void _onPointerUp(PointerUpEvent event, SpatialCompassCubit cubit) {
    if (_activePointers == 2 && _multiTouchStartTime != null) {
      final tapDuration = DateTime.now().difference(_multiTouchStartTime!);
      // إذا كانت نقرة سريعة بإصبعين (أقل من 350ms) -> عد فوراً للمركز
      if (tapDuration.inMilliseconds < 350) {
        _multiTouchStartTime = null; // حماية ضد التكرار العرضي
        cubit.returnToCenter();
      }
    }
    _activePointers = (_activePointers - 1).clamp(0, 10);
    if (_activePointers == 0) {
      _multiTouchStartTime = null;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
    if (_activePointers == 0) {
      _multiTouchStartTime = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SpatialCompassCubit>();

    return BlocBuilder<SpatialCompassCubit, SpatialCompassState>(
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            // زر الرجوع في أندرويد يعيد دائماً إلى المركز أولاً
            if (!state.isAtCenter) {
              cubit.returnToCenter();
            }
          },
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: (e) => _onPointerUp(e, cubit),
            onPointerCancel: _onPointerCancel,
            child: Scaffold(
              backgroundColor: _resolveBackgroundColor(state.currentDirection),
              body: SafeArea(
                child: Stack(
                  children: [
                    // 1. المسطح الحركي الفضائي ثنائي الأبعاد
                    _buildGestureLayer(context, state, cubit),

                    // 2. كبسولة البوصلة الفضائية العائمة والمتكيفة بصرياً
                    _SpatialCompassHud(
                      direction: state.currentDirection,
                      onCenterTap: cubit.returnToCenter,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _resolveBackgroundColor(CompassDirection dir) {
    switch (dir) {
      case CompassDirection.north:
      case CompassDirection.south:
      case CompassDirection.west:
        return AppTheme.warmPaper; // ثيم الورق التحريري الهادئ
      case CompassDirection.center:
      case CompassDirection.east:
        return AppTheme.pureBlack; // ثيم الـ OLED الداكن عالي التباين
    }
  }

  Widget _buildGestureLayer(
    BuildContext context,
    SpatialCompassState state,
    SpatialCompassCubit cubit,
  ) {
    final content = CompassTransitionLayout(
      direction: state.currentDirection,
      centerChild: const ZeroUiView(),
      northChild: const AgendaView(),           // ⬅️ الشمال: قمرة الأجندة والمهام
      southChild: const CommunicationsView(),   // ⬅️ الجنوب: التواصل والتراسل الصامت
      westChild: const FocusAlarmsView(),       // ⬅️ الغرب: مؤقت المذاكرة والمنبهات
      eastChild: const SpatialVisionView(),     // ⬅️ الشرق: استوديو الرؤية المكانية
    );

    // إذا كنا في المركز، نفعل السحب التوجيهي الحر بجميع الزوايا
    if (state.isAtCenter) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (d) => _dragStartOffset = d.localPosition,
        onVerticalDragStart: (d) => _dragStartOffset = d.localPosition,
        onHorizontalDragUpdate: (d) => _dragEndOffset = d.localPosition,
        onVerticalDragUpdate: (d) => _dragEndOffset = d.localPosition,
        onHorizontalDragEnd: (d) => _dispatchDrag(cubit, d.primaryVelocity ?? 0, 0),
        onVerticalDragEnd: (d) => _dispatchDrag(cubit, 0, d.primaryVelocity ?? 0),
        child: content,
      );
    }

    // داخل الغرف الفرعية، نترك القوائم التحريرية تتحرك وتتمرر بدون منافسة لمسية
    return content;
  }

  void _dispatchDrag(SpatialCompassCubit cubit, double vx, double vy) {
    final delta = _dragEndOffset - _dragStartOffset;
    cubit.handleSwipeGesture(
      velocityX: vx,
      velocityY: vy,
      deltaX: delta.dx,
      deltaY: delta.dy,
    );
  }

  Widget _buildRoomPlaceholder({
    required String title,
    required IconData icon,
    required Color color,
    required String directionHint,
  }) {
    return Container(
      color: AppTheme.pureBlack,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 76, color: color),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              directionHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              'Or tap with two fingers anywhere to return to Core.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white30, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// كبسولة البوصلة الفضائية الصامتة والمتكيفة مع الثيم المزدوج (Dual-Theme Spatial HUD)
class _SpatialCompassHud extends StatelessWidget {
  const _SpatialCompassHud({
    required this.direction,
    required this.onCenterTap,
  });

  final CompassDirection direction;
  final VoidCallback onCenterTap;

  @override
  Widget build(BuildContext context) {
    final isAtCenter = direction == CompassDirection.center;
    final isWarmPaperRoom = direction == CompassDirection.north ||
        direction == CompassDirection.south ||
        direction == CompassDirection.west;

    // ألوان تتكيف تلقائياً لتكون مقروءة وراقية سواء في الثيم الليلي أو الثيم الورقي
    final bgColor = isWarmPaperRoom
        ? AppTheme.cardSurface.withValues(alpha: 0.94)
        : AppTheme.deepSlate.withValues(alpha: 0.88);

    final borderColor = isWarmPaperRoom
        ? AppTheme.softBorder
        : (isAtCenter ? AppTheme.subtleGray : AppTheme.iceBlue.withValues(alpha: 0.5));

    final textColor = isWarmPaperRoom
        ? AppTheme.carbonInk
        : (isAtCenter ? Colors.white70 : AppTheme.iceBlue);

    final activeDotColor = isWarmPaperRoom ? AppTheme.terracotta : AppTheme.iceBlue;

    return Positioned(
      top: 10,
      left: 18,
      right: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // كبسولة البوصلة الهندسية (5 نقاط)
          GestureDetector(
            onTap: isAtCenter ? null : onCenterTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isWarmPaperRoom ? 0.05 : 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniCompassCross(direction, activeDotColor, isWarmPaperRoom),
                  const SizedBox(width: 8),
                  Text(
                    _getDirectionLabel(direction),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // زر العودة الفوري للمركز (يظهر فقط في الغرف الفرعية)
          if (!isAtCenter)
            IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: textColor,
                side: BorderSide(color: borderColor, width: 1.2),
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.close_fullscreen_rounded, size: 18),
              tooltip: 'Return to Center',
              onPressed: onCenterTap,
            ),
        ],
      ),
    );
  }

  Widget _buildMiniCompassCross(
    CompassDirection activeDir,
    Color activeColor,
    bool isLight,
  ) {
    final inactiveColor = isLight ? AppTheme.softBorder : Colors.white24;

    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // شمال (North)
          Positioned(top: 0, child: _dot(activeDir == CompassDirection.north, activeColor, inactiveColor)),
          // جنوب (South)
          Positioned(bottom: 0, child: _dot(activeDir == CompassDirection.south, activeColor, inactiveColor)),
          // شرق (East)
          Positioned(right: 0, child: _dot(activeDir == CompassDirection.east, activeColor, inactiveColor)),
          // غرب (West)
          Positioned(left: 0, child: _dot(activeDir == CompassDirection.west, activeColor, inactiveColor)),
          // مركز (Center)
          Positioned(child: _dot(activeDir == CompassDirection.center, activeColor, inactiveColor, isCenter: true)),
        ],
      ),
    );
  }

  Widget _dot(bool isActive, Color activeColor, Color inactiveColor, {bool isCenter = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? (isCenter ? 5 : 4) : 3,
      height: isActive ? (isCenter ? 5 : 4) : 3,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? activeColor : inactiveColor,
      ),
    );
  }

  String _getDirectionLabel(CompassDirection dir) {
    switch (dir) {
      case CompassDirection.center:
        return 'CORE';
      case CompassDirection.north:
        return 'NORTH • AGENDA';
      case CompassDirection.south:
        return 'SOUTH • COMMS';
      case CompassDirection.east:
        return 'EAST • VISION';
      case CompassDirection.west:
        return 'WEST • FOCUS';
    }
  }
}