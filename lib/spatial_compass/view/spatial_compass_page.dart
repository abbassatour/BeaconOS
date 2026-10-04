// lib/spatial_compass/view/spatial_compass_page.dart
import 'package:beacon_os/core/physics/spatial_physics.dart';
import 'package:beacon_os/core/spatial_kernel/spatial_topology.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/settings/cubit/settings_cubit.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_cubit.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:beacon_os/spatial_compass/widgets/floor_layouts.dart';
import 'package:beacon_os/spatial_compass/widgets/spatial_compass_hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class SpatialCompassPage extends StatelessWidget {
  const SpatialCompassPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<LauncherRepository>();
    final topology = context.read<SpatialTopology>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SpatialCompassCubit(
            repository: repository,
            topology: topology,
          ),
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

class _SpatialCompassBodyState extends State<_SpatialCompassBody>
    with TickerProviderStateMixin {
  late final AnimationController _panX;
  late final AnimationController _panY;
  late final AnimationController _floorZ;

  bool _isTwoFingerPinch = false;
  Axis? _lockedAxis;

  double _initialScale = 0.0;
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
    _floorZ = AnimationController.unbounded(vsync: this, value: 0.0);

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

    // =========================================================================
    // 🤏 1. فيزياء محور العمق (Z-Axis Pinch / Zoom)
    // =========================================================================
    if (_isTwoFingerPinch || details.pointerCount >= 2) {
      _isTwoFingerPinch = true;

      final pinchDelta = (1.0 - details.scale) * 1.8;
      final rawZ = (_initialScale + pinchDelta).clamp(-0.2, 1.2);
      _floorZ.value = rawZ;

      if ((rawZ > 0.35 && _initialScale < 0.5) ||
          (rawZ < 0.65 && _initialScale >= 0.5)) {
        if (!_hapticDetentFired) {
          HapticFeedback.selectionClick();
          _hapticDetentFired = true;
        }
      } else if ((rawZ < 0.35 && _initialScale < 0.5) ||
          (rawZ > 0.65 && _initialScale >= 0.5)) {
        if (_hapticDetentFired) {
          _hapticDetentFired = false;
        }
      }
      return;
    }

    // =========================================================================
    // 🧭 2. فيزياء محور التنقل الأفقي بين الغرف (XY-Axis Pan)
    // =========================================================================
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
        if (rawVal > screenWidth) {
          isWall = true;
          wallLimit = screenWidth;
        } else if (rawVal < -screenWidth) {
          isWall = true;
          wallLimit = -screenWidth;
        }
      } else if (state.currentDirection == CompassDirection.east) {
        if (rawVal < -screenWidth) {
          isWall = true;
          wallLimit = -screenWidth;
        } else if (rawVal > 0) {
          isWall = true;
          wallLimit = 0;
        }
      } else if (state.currentDirection == CompassDirection.west) {
        if (rawVal > screenWidth) {
          isWall = true;
          wallLimit = screenWidth;
        } else if (rawVal < 0) {
          isWall = true;
          wallLimit = 0;
        }
      } else {
        isWall = true;
        wallLimit = 0.0;
      }

      if (isWall) {
        final excess = rawVal - wallLimit;
        _panX.value = wallLimit +
            SpatialPhysics.applyRubberBanding(
              delta: excess,
              limit: screenWidth,
            );
      } else {
        _panX.value = rawVal;
      }

      if (!isWall) {
        final dragDistance = (_panX.value - _startXAtGesture).abs();
        if (dragDistance > screenWidth * 0.35) {
          if (!_hapticDetentFired) {
            HapticFeedback.selectionClick();
            _hapticDetentFired = true;
          }
        } else {
          if (_hapticDetentFired) {
            HapticFeedback.selectionClick();
            _hapticDetentFired = false;
          }
        }
      }
    } else if (_lockedAxis == Axis.vertical) {
      final rawVal = _panY.value + dy;

      bool isWall = false;
      double wallLimit = 0.0;

      if (state.currentDirection == CompassDirection.center) {
        if (rawVal > screenHeight) {
          isWall = true;
          wallLimit = screenHeight;
        } else if (rawVal < -screenHeight) {
          isWall = true;
          wallLimit = -screenHeight;
        }
      } else if (state.currentDirection == CompassDirection.north) {
        if (rawVal > screenHeight) {
          isWall = true;
          wallLimit = screenHeight;
        } else if (rawVal < 0) {
          isWall = true;
          wallLimit = 0;
        }
      } else if (state.currentDirection == CompassDirection.south) {
        if (rawVal < -screenHeight) {
          isWall = true;
          wallLimit = -screenHeight;
        } else if (rawVal > 0) {
          isWall = true;
          wallLimit = 0;
        }
      } else {
        isWall = true;
        wallLimit = 0.0;
      }

      if (isWall) {
        final excess = rawVal - wallLimit;
        _panY.value = wallLimit +
            SpatialPhysics.applyRubberBanding(
              delta: excess,
              limit: screenHeight,
            );
      } else {
        _panY.value = rawVal;
      }

      if (!isWall) {
        final dragDistance = (_panY.value - _startYAtGesture).abs();
        if (dragDistance > screenHeight * 0.25) {
          if (!_hapticDetentFired) {
            HapticFeedback.selectionClick();
            _hapticDetentFired = true;
          }
        } else {
          if (_hapticDetentFired) {
            HapticFeedback.selectionClick();
            _hapticDetentFired = false;
          }
        }
      }
    }
  }

  void _onScaleEnd(ScaleEndDetails details, SpatialCompassCubit cubit) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final state = cubit.state;

    // =========================================================================
    // 🏢 إنهاء إيماءة الطابق والقفز السلس بالنوابض (Z Simulation)
    // =========================================================================
    if (_isTwoFingerPinch) {
      _isTwoFingerPinch = false;

      final targetZ = _initialScale < 0.5
          ? (_floorZ.value > 0.35 ? 1.0 : 0.0)
          : (_floorZ.value < 0.65 ? 0.0 : 1.0);

      _floorZ.animateWith(
        SpatialPhysics.createZAxisSimulation(
          start: _floorZ.value,
          end: targetZ,
          velocity: 0.0,
        ),
      );

      if (targetZ == 1.0) {
        cubit.jumpToFloor(1);
      } else {
        cubit.jumpToFloor(0);
      }
      return;
    }

    // إنهاء إيماءات الغرف الأفقية والرأسية
    if (_lockedAxis == Axis.horizontal) {
      final vx = details.velocity.pixelsPerSecond.dx;
      double targetX = _panX.value;
      CompassDirection targetDir = state.currentDirection;

      if (state.currentDirection == CompassDirection.center) {
        if (_panX.value > screenW * 0.35 || vx > 400) {
          targetX = screenW;
          targetDir = CompassDirection.west;
        } else if (_panX.value < -screenW * 0.35 || vx < -400) {
          targetX = -screenW;
          targetDir = CompassDirection.east;
        } else {
          targetX = 0.0;
        }
      } else if (state.currentDirection == CompassDirection.east) {
        if (_panX.value > -screenW * 0.65 || vx > 400) {
          targetX = 0.0;
          targetDir = CompassDirection.center;
        } else {
          targetX = -screenW;
          targetDir = CompassDirection.east;
        }
      } else if (state.currentDirection == CompassDirection.west) {
        if (_panX.value < screenW * 0.65 || vx < -400) {
          targetX = 0.0;
          targetDir = CompassDirection.center;
        } else {
          targetX = screenW;
          targetDir = CompassDirection.west;
        }
      } else {
        _snapToCurrentState(state);
        return;
      }

      _panX.animateWith(
        SpatialPhysics.createPanSimulation(
          start: _panX.value,
          end: targetX,
          velocity: vx,
        ),
      );
      _panY.animateWith(
        SpatialPhysics.createPanSimulation(
          start: _panY.value,
          end: 0.0,
          velocity: 0.0,
        ),
      );
      if (targetDir != state.currentDirection) cubit.moveTo(targetDir);
    } else if (_lockedAxis == Axis.vertical) {
      final vy = details.velocity.pixelsPerSecond.dy;
      double targetY = _panY.value;
      CompassDirection targetDir = state.currentDirection;

      if (state.currentDirection == CompassDirection.center) {
        if (_panY.value > screenH * 0.35 || vy > 400) {
          targetY = screenH;
          targetDir = CompassDirection.north;
        } else if (_panY.value < -screenH * 0.35 || vy < -400) {
          targetY = -screenH;
          targetDir = CompassDirection.south;
        } else {
          targetY = 0.0;
        }
      } else if (state.currentDirection == CompassDirection.north) {
        if (_panY.value < screenH * 0.65 || vy < -400) {
          targetY = 0.0;
          targetDir = CompassDirection.center;
        } else {
          targetY = screenH;
          targetDir = CompassDirection.north;
        }
      } else if (state.currentDirection == CompassDirection.south) {
        if (_panY.value > -screenH * 0.65 || vy > 400) {
          targetY = 0.0;
          targetDir = CompassDirection.center;
        } else {
          targetY = -screenH;
          targetDir = CompassDirection.south;
        }
      } else {
        _snapToCurrentState(state);
        return;
      }

      _panY.animateWith(
        SpatialPhysics.createPanSimulation(
          start: _panY.value,
          end: targetY,
          velocity: vy,
        ),
      );
      _panX.animateWith(
        SpatialPhysics.createPanSimulation(
          start: _panX.value,
          end: 0.0,
          velocity: 0.0,
        ),
      );
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
    double tx = 0;
    double ty = 0;

    switch (state.currentDirection) {
      case CompassDirection.center:
        break;
      case CompassDirection.east:
        tx = -w;
        break;
      case CompassDirection.west:
        tx = w;
        break;
      case CompassDirection.north:
        ty = h;
        break;
      case CompassDirection.south:
        ty = -h;
        break;
    }

    _panX.animateWith(
      SpatialPhysics.createPanSimulation(
        start: _panX.value,
        end: tx,
        velocity: 0,
      ),
    );
    _panY.animateWith(
      SpatialPhysics.createPanSimulation(
        start: _panY.value,
        end: ty,
        velocity: 0,
      ),
    );
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

        final targetZ = state.currentFloor.toDouble();
        if (_floorZ.value != targetZ) {
          _floorZ.animateWith(
            SpatialPhysics.createZAxisSimulation(
              start: _floorZ.value,
              end: targetZ,
              velocity: 0.0,
            ),
          );
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
                  final coreOpacity = (1.0 - zFloor).clamp(0.0, 1.0);

                  final settingsScale = 0.75 + (zFloor * 0.25);
                  final settingsOpacity = zFloor.clamp(0.0, 1.0);

                  return Stack(
                    children: [
                      // ⚙️ الطبقة العميقة (Floor 1: الإعدادات والمحركات)
                      // 🚀 الفرز الفضائي (Spatial Culling): إيقاف الرندر والتفاعل عند الاختفاء
                      Visibility(
                        visible: settingsOpacity > 0.02,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..translate(_panX.value, _panY.value)
                            ..scale(settingsScale, settingsScale),
                          child: Opacity(
                            opacity: settingsOpacity,
                            child: IgnorePointer(
                              ignoring: zFloor < 0.5,
                              child: SpatialFloorLayout(
                                direction: state.currentDirection,
                                floorLevel: 1,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 🏠 الطبقة السطحية (Floor 0: الغرف الأساسية وقمرة القيادة)
                      // 🚀 الفرز الفضائي (Spatial Culling): إيقاف الرندر والتفاعل عند الاختفاء
                      Visibility(
                        visible: coreOpacity > 0.02,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..translate(_panX.value, _panY.value)
                            ..scale(coreScale, coreScale),
                          child: Opacity(
                            opacity: coreOpacity,
                            child: IgnorePointer(
                              ignoring: zFloor > 0.5,
                              child: SpatialFloorLayout(
                                direction: state.currentDirection,
                                floorLevel: 0,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 🗺️ شريط الـ HUD الملاحي المتصل بالطوبولوجيا
                      SpatialCompassHud(
                        direction: state.currentDirection,
                        currentFloor: state.currentFloor,
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