// lib/spatial_compass/view/spatial_compass_page.dart
import 'dart:developer';
import 'package:beacon_os/agenda/view/agenda_view.dart';
import 'package:beacon_os/cockpit_dashboard/view/cockpit_dashboard_view.dart';
import 'package:beacon_os/communications/view/communications_view.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/focus_alarms/view/focus_alarms_view.dart';
import 'package:beacon_os/settings/cubit/settings_cubit.dart';
import 'package:beacon_os/settings/rooms/settings_agenda_room.dart';
import 'package:beacon_os/settings/rooms/settings_comms_room.dart';
import 'package:beacon_os/settings/rooms/settings_core_room.dart';
import 'package:beacon_os/settings/rooms/settings_focus_room.dart';
import 'package:beacon_os/settings/rooms/settings_vision_room.dart';
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

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SpatialCompassCubit(repository: repository),
        ),
        BlocProvider(
          create: (context) => SettingsCubit(repository: repository),
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
  Offset _scaleStartFocalPoint = Offset.zero;
  Offset _scaleEndFocalPoint = Offset.zero;
  
  // 🔥 (جديد) تتبع حركة السحب لحظة بلحظة
  Offset _dragOffset = Offset.zero; 

  double _minScale = 1.0;
  double _maxScale = 1.0;
  bool _isTwoFingerGesture = false;

  int _activePointers = 0;
  DateTime? _multiTouchStartTime;
  bool _hasTwoFingerMoved = false;

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
    if (_activePointers == 2) {
      _multiTouchStartTime = DateTime.now();
      _hasTwoFingerMoved = false;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_activePointers >= 2 && event.delta.distance > 2.5) {
      _hasTwoFingerMoved = true;
    }
  }

  void _onPointerUp(PointerUpEvent event, SpatialCompassCubit cubit) {
    if (_activePointers == 2 && _multiTouchStartTime != null) {
      final tapDuration = DateTime.now().difference(_multiTouchStartTime!);

      // النطق عند النقر السريع بإصبعين
      if (!_hasTwoFingerMoved && tapDuration.inMilliseconds < 300) {
        _multiTouchStartTime = null;
        cubit.announceCurrentLocation();
      }
    }

    _activePointers = (_activePointers - 1).clamp(0, 10);
    if (_activePointers == 0) {
      _multiTouchStartTime = null;
      _hasTwoFingerMoved = false;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
    if (_activePointers == 0) {
      _multiTouchStartTime = null;
      _hasTwoFingerMoved = false;
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
            if (state.isSettingsFloor) {
              cubit.returnToGroundFloor();
            } else if (!state.isAtCenter) {
              cubit.returnToCenter();
            }
          },
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: (e) => _onPointerUp(e, cubit),
            onPointerCancel: _onPointerCancel,
            child: Scaffold(
              backgroundColor: AppTheme.warmPaper,
              body: SafeArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onScaleStart: (details) {
                    _scaleStartFocalPoint = details.focalPoint;
                    _scaleEndFocalPoint = details.focalPoint;
                    _dragOffset = Offset.zero;
                    _minScale = 1.0;
                    _maxScale = 1.0;
                    _isTwoFingerGesture = details.pointerCount >= 2;
                  },
                  onScaleUpdate: (details) {
                    _scaleEndFocalPoint = details.focalPoint;
                    if (details.pointerCount >= 2) {
                      _isTwoFingerGesture = true;
                      if (details.scale < _minScale) _minScale = details.scale;
                      if (details.scale > _maxScale) _maxScale = details.scale;
                    } else if (!_isTwoFingerGesture) {
                      // 🔥 (السحر اللحظي): تحديث الواجهة فوراً مع حركة الإصبع
                      setState(() {
                        _dragOffset = details.focalPoint - _scaleStartFocalPoint;
                      });
                    }
                  },
                  onScaleEnd: (details) {
                    final delta = _scaleEndFocalPoint - _scaleStartFocalPoint;

                    if (_isTwoFingerGesture) {
                      final isZoomIn = _maxScale > 1.15 || delta.dy < -50;
                      final isZoomOut = _minScale < 0.88 || delta.dy > 50;

                      if (isZoomIn && !state.isSettingsFloor) {
                        cubit.goToSettingsFloor();
                      } else if (isZoomOut && state.isSettingsFloor) {
                        cubit.returnToGroundFloor();
                      }

                      _isTwoFingerGesture = false;
                      
                      // إرجاع حركة الإصبع لمكانها
                      setState(() => _dragOffset = Offset.zero);
                      return;
                    }

                    final vx = details.velocity.pixelsPerSecond.dx;
                    final vy = details.velocity.pixelsPerSecond.dy;

                    cubit.handleSwipeGesture(
                      velocityX: vx,
                      velocityY: vy,
                      deltaX: delta.dx,
                      deltaY: delta.dy,
                    );

                    // 🔥 إرجاع الشاشة بمرونة فور رفع الإصبع لبدء الانيميشن الأصلي
                    setState(() => _dragOffset = Offset.zero);
                  },
                  
                  // 🔥 التغليف الحركي (Physical Feedback)
                  child: AnimatedContainer(
                    // إذا كان الإصبع على الشاشة، تتحرك الشاشة فوراً (0ms)
                    // وإذا رُفع الإصبع، ترتد الشاشة لمكانها بسلاسة (250ms)
                    duration: _dragOffset == Offset.zero 
                        ? const Duration(milliseconds: 250) 
                        : Duration.zero,
                    curve: Curves.easeOutExpo,
                    transform: Matrix4.translationValues(
                      _dragOffset.dx * 0.45, // احتكاك بنسبة 45% لتعطي إحساس الوزن
                      _dragOffset.dy * 0.45,
                      0,
                    ),
                    child: Stack(
                      children: [
                        // طبقة الإعدادات بالخلفية
                        AnimatedScale(
                          scale: state.isSettingsFloor ? 1.0 : 0.75,
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeInOutCubic,
                          child: AnimatedOpacity(
                            opacity: state.isSettingsFloor ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeInOut,
                            child: IgnorePointer(
                              ignoring: !state.isSettingsFloor,
                              child: CompassTransitionLayout(
                                direction: state.currentDirection,
                                centerChild: const SettingsCoreRoom(),
                                northChild: const SettingsAgendaRoom(),
                                southChild: const SettingsCommsRoom(),
                                westChild: const SettingsFocusRoom(),
                                eastChild: const SettingsVisionRoom(),
                              ),
                            ),
                          ),
                        ),

                        // الطبقة الأساسية
                        AnimatedScale(
                          scale: state.isSettingsFloor ? 1.45 : 1.0,
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeInOutCubic,
                          child: AnimatedOpacity(
                            opacity: state.isSettingsFloor ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeInOut,
                            child: IgnorePointer(
                              ignoring: state.isSettingsFloor,
                              child: CompassTransitionLayout(
                                direction: state.currentDirection,
                                centerChild: const CockpitDashboardView(),
                                northChild: const AgendaView(),
                                southChild: const CommunicationsView(),
                                westChild: const FocusAlarmsView(),
                                eastChild: const SpatialVisionView(),
                              ),
                            ),
                          ),
                        ),

                        // شريط الـ HUD العائم
                        _SpatialCompassHud(
                          direction: state.currentDirection,
                          isSettingsFloor: state.isSettingsFloor,
                          onCenterTap: cubit.returnToCenter,
                          onFloorToggle: cubit.toggleFloor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpatialCompassHud extends StatelessWidget {
  const _SpatialCompassHud({
    required this.direction,
    required this.isSettingsFloor,
    required this.onCenterTap,
    required this.onFloorToggle,
  });

  final CompassDirection direction;
  final bool isSettingsFloor;
  final VoidCallback onCenterTap;
  final VoidCallback onFloorToggle;

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
                border: Border.all(
                  color: isSettingsFloor
                      ? AppTheme.terracotta
                      : AppTheme.softBorder,
                  width: isSettingsFloor ? 1.5 : 1.2,
                ),
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
                  _buildMiniCompassCross(direction, isSettingsFloor),
                  const SizedBox(width: 8),
                  Text(
                    _getDirectionLabel(direction, isSettingsFloor),
                    style: TextStyle(
                      color: isSettingsFloor
                          ? AppTheme.terracotta
                          : AppTheme.carbonInk,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: isSettingsFloor
                      ? AppTheme.terracotta
                      : AppTheme.cardSurface,
                  foregroundColor: isSettingsFloor
                      ? Colors.white
                      : AppTheme.carbonInk,
                  side: const BorderSide(
                    color: AppTheme.softBorder,
                    width: 1.2,
                  ),
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(
                  isSettingsFloor
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 18,
                ),
                tooltip: isSettingsFloor
                    ? 'Ascend to Floor 1'
                    : 'Dive to Floor 2 Settings',
                onPressed: onFloorToggle,
              ),
              if (!isAtCenter) ...[
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.cardSurface,
                    foregroundColor: AppTheme.carbonInk,
                    side: const BorderSide(
                      color: AppTheme.softBorder,
                      width: 1.2,
                    ),
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.close_fullscreen_rounded, size: 18),
                  tooltip: 'Return to Center',
                  onPressed: onCenterTap,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCompassCross(CompassDirection activeDir, bool isSettings) {
    final activeColor = isSettings ? AppTheme.terracotta : AppTheme.carbonInk;
    const inactiveColor = AppTheme.softBorder;

    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: _dot(
              activeDir == CompassDirection.north,
              activeColor,
              inactiveColor,
            ),
          ),
          Positioned(
            bottom: 0,
            child: _dot(
              activeDir == CompassDirection.south,
              activeColor,
              inactiveColor,
            ),
          ),
          Positioned(
            right: 0,
            child: _dot(
              activeDir == CompassDirection.east,
              activeColor,
              inactiveColor,
            ),
          ),
          Positioned(
            left: 0,
            child: _dot(
              activeDir == CompassDirection.west,
              activeColor,
              inactiveColor,
            ),
          ),
          Positioned(
            child: _dot(
              activeDir == CompassDirection.center,
              activeColor,
              inactiveColor,
              isCenter: true,
            ),
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

  String _getDirectionLabel(CompassDirection dir, bool isSettings) {
    final prefix = isSettings ? 'FL2 • ' : '';
    switch (dir) {
      case CompassDirection.center:
        return isSettings ? '${prefix}CORE ENGINE' : 'TODAY COCKPIT';
      case CompassDirection.north:
        return '${prefix}AGENDA SETTINGS';
      case CompassDirection.south:
        return '${prefix}COMMS & SOS';
      case CompassDirection.east:
        return '${prefix}VISION ENGINE';
      case CompassDirection.west:
        return '${prefix}FOCUS TUNING';
    }
  }
}