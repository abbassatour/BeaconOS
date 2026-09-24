// lib/spatial_compass/view/spatial_compass_page.dart
import 'dart:developer';
import 'package:beacon_os/agenda/view/agenda_view.dart';
import 'package:beacon_os/cockpit_dashboard/view/cockpit_dashboard_view.dart';
import 'package:beacon_os/communications/view/communications_view.dart';
import 'package:beacon_os/core/physics/spatial_physics.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/focus_alarms/view/focus_alarms_view.dart';
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
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:beacon_os/settings/cubit/settings_cubit.dart';

class SpatialCompassPage extends StatelessWidget {
  const SpatialCompassPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<LauncherRepository>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SpatialCompassCubit(repository: repository)),
        BlocProvider(create: (context) => SettingsCubit(repository: repository)),
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

class _SpatialCompassBodyState extends State<_SpatialCompassBody>
    with TickerProviderStateMixin {
  late final AnimationController _panX;
  late final AnimationController _panY;
  late final AnimationController _floorZ;

  bool _isTwoFingerPinch = false;
  Axis? _lockedAxis;
  
  double _initialScale = 1.0;
  double _startXAtGesture = 0.0;
  double _startYAtGesture = 0.0;
  bool _hapticDetentFired = false;

  int _activePointers = 0;
  DateTime? _multiTouchStartTime;
  bool _hasTwoFingerMoved = false;

  @override
  void initState() {
    super.initState();
    _panX = AnimationController.unbounded(vsync: this);
    _panY = AnimationController.unbounded(vsync: this);
    _floorZ = AnimationController(
      vsync: this,
      value: 0.0,
      lowerBound: -0.2,
      upperBound: 1.2,
    );

    _panX.addListener(_forceRender);
    _panY.addListener(_forceRender);
    _floorZ.addListener(_forceRender);
  }

  void _forceRender() => setState(() {});

  @override
  void dispose() {
    _panX.dispose();
    _panY.dispose();
    _floorZ.dispose();
    super.dispose();
  }

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
      if (!_hasTwoFingerMoved && tapDuration.inMilliseconds < 300) {
        _multiTouchStartTime = null;
        cubit.announceCurrentLocation();
      }
    }
    _activePointers = (_activePointers - 1).clamp(0, 10);
    if (_activePointers == 0) _hasTwoFingerMoved = false;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
  }

  void _onScaleStart(ScaleStartDetails details) {
    _panX.stop();
    _panY.stop();
    _floorZ.stop();

    _isTwoFingerPinch = details.pointerCount >= 2;
    _lockedAxis = null;
    _initialScale = _floorZ.value;
    _startXAtGesture = _panX.value;
    _startYAtGesture = _panY.value;
    _hapticDetentFired = false;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final state = context.read<SpatialCompassCubit>().state;

    if (_isTwoFingerPinch || details.pointerCount >= 2) {
      _isTwoFingerPinch = true;
      final scaleDelta = 1.0 - details.scale; 
      final rawZ = _initialScale + scaleDelta;
      _floorZ.value = rawZ;

      if ((rawZ > 0.4 && _initialScale < 0.5) || (rawZ < 0.6 && _initialScale > 0.5)) {
        if (!_hapticDetentFired) {
           HapticFeedback.selectionClick();
           _hapticDetentFired = true;
        }
      } else if ((rawZ < 0.4 && _initialScale < 0.5) || (rawZ > 0.6 && _initialScale > 0.5)) {
        if (_hapticDetentFired) {
           HapticFeedback.selectionClick();
           _hapticDetentFired = false;
        }
      }
      return;
    }

    final dx = details.focalPointDelta.dx;
    final dy = details.focalPointDelta.dy;

    if (_lockedAxis == null && (dx.abs() > 3 || dy.abs() > 3)) {
      _lockedAxis = dx.abs() > dy.abs() ? Axis.horizontal : Axis.vertical;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_lockedAxis == Axis.horizontal) {
      final rawVal = _panX.value + dx;
      
      bool isWall = false;
      double wallLimit = 0.0;

      if (state.currentDirection == CompassDirection.center) {
         if (rawVal > screenWidth) { isWall = true; wallLimit = screenWidth; }
         else if (rawVal < -screenWidth) { isWall = true; wallLimit = -screenWidth; }
      } else if (state.currentDirection == CompassDirection.east) {
         if (rawVal < -screenWidth) { isWall = true; wallLimit = -screenWidth; }
         else if (rawVal > 0) { isWall = true; wallLimit = 0; }
      } else if (state.currentDirection == CompassDirection.west) {
         if (rawVal > screenWidth) { isWall = true; wallLimit = screenWidth; }
         else if (rawVal < 0) { isWall = true; wallLimit = 0; }
      } else {
         isWall = true; wallLimit = 0.0; 
      }

      if (isWall) {
        final excess = rawVal - wallLimit;
        _panX.value = wallLimit + SpatialPhysics.applyRubberBanding(delta: excess, limit: screenWidth);
      } else {
        _panX.value = rawVal;
      }

      if (!isWall) {
        final dragDistance = (_panX.value - _startXAtGesture).abs();
        if (dragDistance > screenWidth * 0.35) {
          if (!_hapticDetentFired) { HapticFeedback.selectionClick(); _hapticDetentFired = true; }
        } else {
          if (_hapticDetentFired) { HapticFeedback.selectionClick(); _hapticDetentFired = false; }
        }
      }

    } else if (_lockedAxis == Axis.vertical) {
      final rawVal = _panY.value + dy;
      
      bool isWall = false;
      double wallLimit = 0.0;

      if (state.currentDirection == CompassDirection.center) {
         if (rawVal > screenHeight) { isWall = true; wallLimit = screenHeight; }
         else if (rawVal < -screenHeight) { isWall = true; wallLimit = -screenHeight; }
      } else if (state.currentDirection == CompassDirection.north) {
         if (rawVal > screenHeight) { isWall = true; wallLimit = screenHeight; }
         else if (rawVal < 0) { isWall = true; wallLimit = 0; }
      } else if (state.currentDirection == CompassDirection.south) {
         if (rawVal < -screenHeight) { isWall = true; wallLimit = -screenHeight; }
         else if (rawVal > 0) { isWall = true; wallLimit = 0; }
      } else {
         isWall = true; wallLimit = 0.0;
      }

      if (isWall) {
        final excess = rawVal - wallLimit;
        _panY.value = wallLimit + SpatialPhysics.applyRubberBanding(delta: excess, limit: screenHeight);
      } else {
        _panY.value = rawVal;
      }

      if (!isWall) {
        final dragDistance = (_panY.value - _startYAtGesture).abs();
        if (dragDistance > screenHeight * 0.25) {
          if (!_hapticDetentFired) { HapticFeedback.selectionClick(); _hapticDetentFired = true; }
        } else {
          if (_hapticDetentFired) { HapticFeedback.selectionClick(); _hapticDetentFired = false; }
        }
      }
    }
  }

  void _onScaleEnd(ScaleEndDetails details, SpatialCompassCubit cubit) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final state = cubit.state;

    if (_isTwoFingerPinch) {
      _isTwoFingerPinch = false;
      final targetZ = _floorZ.value > 0.4 ? 1.0 : 0.0;
      _floorZ.animateWith(SpatialPhysics.createZAxisSimulation(start: _floorZ.value, end: targetZ, velocity: 0.0));
      if (targetZ == 1.0) { cubit.goToSettingsFloor(); } else { cubit.returnToGroundFloor(); }
      return;
    }

    if (_lockedAxis == Axis.horizontal) {
      final vx = details.velocity.pixelsPerSecond.dx;
      double targetX = _panX.value;
      CompassDirection targetDir = state.currentDirection;

      if (state.currentDirection == CompassDirection.center) {
          if (_panX.value > screenW * 0.35 || vx > 400) {
              targetX = screenW; targetDir = CompassDirection.west;
          } else if (_panX.value < -screenW * 0.35 || vx < -400) {
              targetX = -screenW; targetDir = CompassDirection.east;
          } else {
              targetX = 0.0;
          }
      } else if (state.currentDirection == CompassDirection.east) {
          if (_panX.value > -screenW * 0.65 || vx > 400) {
              targetX = 0.0; targetDir = CompassDirection.center;
          } else {
              targetX = -screenW; targetDir = CompassDirection.east;
          }
      } else if (state.currentDirection == CompassDirection.west) {
          if (_panX.value < screenW * 0.65 || vx < -400) {
              targetX = 0.0; targetDir = CompassDirection.center;
          } else {
              targetX = screenW; targetDir = CompassDirection.west;
          }
      } else {
          _snapToCurrentState(state); return;
      }

      _panX.animateWith(SpatialPhysics.createPanSimulation(start: _panX.value, end: targetX, velocity: vx));
      _panY.animateWith(SpatialPhysics.createPanSimulation(start: _panY.value, end: 0.0, velocity: 0.0));
      if (targetDir != state.currentDirection) cubit.moveTo(targetDir);

    } else if (_lockedAxis == Axis.vertical) {
      final vy = details.velocity.pixelsPerSecond.dy;
      double targetY = _panY.value;
      CompassDirection targetDir = state.currentDirection;

      if (state.currentDirection == CompassDirection.center) {
          if (_panY.value > screenH * 0.35 || vy > 400) {
              targetY = screenH; targetDir = CompassDirection.north;
          } else if (_panY.value < -screenH * 0.35 || vy < -400) {
              targetY = -screenH; targetDir = CompassDirection.south;
          } else {
              targetY = 0.0;
          }
      } else if (state.currentDirection == CompassDirection.north) {
          if (_panY.value < screenH * 0.65 || vy < -400) {
              targetY = 0.0; targetDir = CompassDirection.center;
          } else {
              targetY = screenH; targetDir = CompassDirection.north;
          }
      } else if (state.currentDirection == CompassDirection.south) {
          if (_panY.value > -screenH * 0.65 || vy > 400) {
              targetY = 0.0; targetDir = CompassDirection.center;
          } else {
              targetY = -screenH; targetDir = CompassDirection.south;
          }
      } else {
          _snapToCurrentState(state); return;
      }

      _panY.animateWith(SpatialPhysics.createPanSimulation(start: _panY.value, end: targetY, velocity: vy));
      _panX.animateWith(SpatialPhysics.createPanSimulation(start: _panX.value, end: 0.0, velocity: 0.0));
      if (targetDir != state.currentDirection) cubit.moveTo(targetDir);

    } else {
      _snapToCurrentState(state);
    }
    
    _lockedAxis = null;
  }

  void _snapToCurrentState(SpatialCompassState state) {
    if (!mounted) return;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    double tx = 0; double ty = 0;
    
    switch(state.currentDirection) {
      case CompassDirection.center: break;
      case CompassDirection.east: tx = -w; break;
      case CompassDirection.west: tx = w; break;
      case CompassDirection.north: ty = h; break;
      case CompassDirection.south: ty = -h; break;
    }

    _panX.animateWith(SpatialPhysics.createPanSimulation(start: _panX.value, end: tx, velocity: 0));
    _panY.animateWith(SpatialPhysics.createPanSimulation(start: _panY.value, end: ty, velocity: 0));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SpatialCompassCubit>();

    return BlocListener<SpatialCompassCubit, SpatialCompassState>(
      listenWhen: (previous, current) => 
          previous.currentDirection != current.currentDirection ||
          previous.currentFloor != current.currentFloor,
      listener: (context, state) {
        if (_lockedAxis == null && !_isTwoFingerPinch) {
          _snapToCurrentState(state);
        }
        
        if (state.currentFloor == 0 && _floorZ.value != 0.0) {
          _floorZ.animateWith(SpatialPhysics.createZAxisSimulation(start: _floorZ.value, end: 0.0, velocity: 0.0));
        } else if (state.currentFloor == 1 && _floorZ.value != 1.0) {
          _floorZ.animateWith(SpatialPhysics.createZAxisSimulation(start: _floorZ.value, end: 1.0, velocity: 0.0));
        }
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        body: SafeArea(
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: (e) => _onPointerUp(e, cubit),
            onPointerCancel: _onPointerCancel,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: (d) => _onScaleEnd(d, cubit),
              child: BlocBuilder<SpatialCompassCubit, SpatialCompassState>(
                builder: (context, state) {
                  
                  final zFloor = _floorZ.value.clamp(0.0, 1.0);
                  final coreScale = 1.0 + (zFloor * 0.45); 
                  final coreOpacity = 1.0 - zFloor;
                  
                  final settingsScale = 0.75 + (zFloor * 0.25); 
                  final settingsOpacity = zFloor;

                  return Stack(
                    children: [
                      // ⚙️ الطبقة العميقة (الطابق الثاني - الإعدادات)
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translate(_panX.value, _panY.value) // 🌟 تم إضافة إحداثيات السحب هنا ليتحرك الطابق الثاني!
                          ..scale(settingsScale, settingsScale),
                        child: Opacity(
                          opacity: settingsOpacity,
                          child: IgnorePointer(
                            ignoring: zFloor < 0.5,
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

                      // 🏠 الطبقة السطحية (الطابق الأول - الغرف الأساسية)
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translate(_panX.value, _panY.value)
                          ..scale(coreScale, coreScale),
                        child: Opacity(
                          opacity: coreOpacity,
                          child: IgnorePointer(
                            ignoring: zFloor > 0.5,
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

                      // 🗺️ شريط الـ HUD العائم والمستقل تماماً عن حركة الطوابق
                      _SpatialCompassHud(
                        direction: state.currentDirection,
                        isSettingsFloor: state.isSettingsFloor,
                        onCenterTap: cubit.returnToCenter,
                        onFloorToggle: cubit.toggleFloor,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
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
    final colors = context.colors;

    return Positioned(
      top: 10,
      left: 18,
      right: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🌟 تم إضافة Expanded و Flexible لمنع خطأ الـ RenderFlex Overflow
          Expanded(
            child: GestureDetector(
              onTap: isAtCenter ? null : onCenterTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSettingsFloor ? colors.primary : colors.outline,
                    width: isSettingsFloor ? 1.5 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.onSurface.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMiniCompassCross(context, direction, isSettingsFloor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _getDirectionLabel(direction, isSettingsFloor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // 🌟 يضع النقاط "..." إذا كان النص طويلاً
                        style: TextStyle(
                          color: isSettingsFloor ? colors.primary : colors.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: isSettingsFloor ? colors.primary : colors.surface,
                  foregroundColor: isSettingsFloor ? colors.onPrimary : colors.onSurface,
                  side: BorderSide(color: colors.outline, width: 1.2),
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(
                  isSettingsFloor ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 18,
                ),
                tooltip: isSettingsFloor ? 'Ascend to Floor 1' : 'Dive to Floor 2 Settings',
                onPressed: onFloorToggle,
              ),
              if (!isAtCenter) ...[
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surface,
                    foregroundColor: colors.onSurface,
                    side: BorderSide(color: colors.outline, width: 1.2),
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

  Widget _buildMiniCompassCross(BuildContext context, CompassDirection activeDir, bool isSettings) {
    final colors = context.colors;
    final activeColor = isSettings ? colors.primary : colors.onSurface;
    final inactiveColor = colors.outline;

    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 0, child: _dot(activeDir == CompassDirection.north, activeColor, inactiveColor)),
          Positioned(bottom: 0, child: _dot(activeDir == CompassDirection.south, activeColor, inactiveColor)),
          Positioned(right: 0, child: _dot(activeDir == CompassDirection.east, activeColor, inactiveColor)),
          Positioned(left: 0, child: _dot(activeDir == CompassDirection.west, activeColor, inactiveColor)),
          Positioned(child: _dot(activeDir == CompassDirection.center, activeColor, inactiveColor, isCenter: true)),
        ],
      ),
    );
  }

  Widget _dot(bool isActive, Color activeColor, Color inactiveColor, {bool isCenter = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
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
      case CompassDirection.center: return isSettings ? '${prefix}CORE ENGINE' : 'TODAY COCKPIT';
      case CompassDirection.north:  return '${prefix}AGENDA SETTINGS';
      case CompassDirection.south:  return '${prefix}COMMS & SOS';
      case CompassDirection.east:   return '${prefix}VISION ENGINE';
      case CompassDirection.west:   return '${prefix}FOCUS TUNING';
    }
  }
}