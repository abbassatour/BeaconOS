// lib/spatial_compass/view/spatial_compass_page.dart
import 'package:beacon_os/agenda/view/agenda_view.dart';
import 'package:beacon_os/cockpit_dashboard/view/cockpit_dashboard_view.dart';
import 'package:beacon_os/communications/view/communications_view.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/focus_alarms/view/focus_alarms_view.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_cubit.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:beacon_os/spatial_compass/widgets/compass_transition_layout.dart';
import 'package:beacon_os/spatial_vision/view/spatial_vision_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class SpatialCompassPage extends StatelessWidget {
  const SpatialCompassPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<LauncherRepository>();

    return BlocProvider(
      create: (context) => SpatialCompassCubit(repository: repository),
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
  Offset _dragStartOffset = Offset.zero;
  Offset _dragEndOffset = Offset.zero;
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
      if (tapDuration.inMilliseconds < 350) {
        _multiTouchStartTime = null;
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
            if (!state.isAtCenter) {
              cubit.returnToCenter();
            }
          },
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: (e) => _onPointerUp(e, cubit),
            onPointerCancel: _onPointerCancel,
            child: Scaffold(
              backgroundColor: AppTheme.warmPaper,
              body: SafeArea(
                child: Stack(
                  children: [
                    _buildGestureLayer(context, state, cubit),
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

  Widget _buildGestureLayer(
    BuildContext context,
    SpatialCompassState state,
    SpatialCompassCubit cubit,
  ) {
    final content = CompassTransitionLayout(
      direction: state.currentDirection,
      centerChild: const CockpitDashboardView(), // ⬅️ قمرة اليوم أصبحت المركز الجديد!
      northChild: const AgendaView(),
      southChild: const CommunicationsView(),
      westChild: const FocusAlarmsView(),
      eastChild: const SpatialVisionView(),
    );

    if (state.isAtCenter) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (d) => _dragStartOffset = d.localPosition,
        onVerticalDragStart: (d) => _dragStartOffset = d.localPosition,
        onHorizontalDragUpdate: (d) => _dragEndOffset = d.localPosition,
        onVerticalDragUpdate: (d) => _dragEndOffset = d.localPosition,
        onHorizontalDragEnd: (d) =>
            _dispatchDrag(cubit, d.primaryVelocity ?? 0, 0),
        onVerticalDragEnd: (d) =>
            _dispatchDrag(cubit, 0, d.primaryVelocity ?? 0),
        child: content,
      );
    }

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
}

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

    return Positioned(
      top: 10,
      left: 18,
      right: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: isAtCenter ? null : onCenterTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.softBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.carbonInk.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniCompassCross(direction),
                  const SizedBox(width: 8),
                  Text(
                    _getDirectionLabel(direction),
                    style: const TextStyle(
                      color: AppTheme.carbonInk,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isAtCenter)
            IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.cardSurface,
                foregroundColor: AppTheme.carbonInk,
                side: const BorderSide(color: AppTheme.softBorder, width: 1.2),
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

  Widget _buildMiniCompassCross(CompassDirection activeDir) {
    const activeColor = AppTheme.terracotta;
    const inactiveColor = AppTheme.softBorder;

    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: _dot(activeDir == CompassDirection.north, activeColor, inactiveColor),
          ),
          Positioned(
            bottom: 0,
            child: _dot(activeDir == CompassDirection.south, activeColor, inactiveColor),
          ),
          Positioned(
            right: 0,
            child: _dot(activeDir == CompassDirection.east, activeColor, inactiveColor),
          ),
          Positioned(
            left: 0,
            child: _dot(activeDir == CompassDirection.west, activeColor, inactiveColor),
          ),
          Positioned(
            child: _dot(activeDir == CompassDirection.center, activeColor, inactiveColor, isCenter: true),
          ),
        ],
      ),
    );
  }

  Widget _dot(
    bool isActive,
    Color activeColor,
    Color inactiveColor, {
    bool isCenter = false,
  }) {
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
        return 'TODAY COCKPIT';
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