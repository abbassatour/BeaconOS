// lib/spatial_compass/widgets/spatial_compass_hud.dart
import 'package:beacon_os/core/spatial_kernel/spatial_topology.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SpatialCompassHud extends StatelessWidget {
  const SpatialCompassHud({
    required this.direction,
    required this.currentFloor,
    required this.onCenterTap,
    required this.onFloorToggle,
    this.isSettingsFloor = false, // للتوافق العكسي
    super.key,
  });

  final CompassDirection direction;
  final int currentFloor;
  final bool isSettingsFloor;
  final VoidCallback onCenterTap;
  final VoidCallback onFloorToggle;

  @override
  Widget build(BuildContext context) {
    final isAtCenter = direction == CompassDirection.center;
    final isElevated = currentFloor != 0;
    final colors = context.colors;

    return Positioned(
      top: 10,
      left: 18,
      right: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: isAtCenter ? null : onCenterTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isElevated ? colors.primary : colors.outline,
                    width: isElevated ? 1.5 : 1.2,
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
                    _buildMiniCompassCross(context, direction, isElevated),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _getDirectionLabel(context, direction, currentFloor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isElevated ? colors.primary : colors.onSurface,
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
                  backgroundColor: isElevated ? colors.primary : colors.surface,
                  foregroundColor: isElevated ? colors.onPrimary : colors.onSurface,
                  side: BorderSide(color: colors.outline, width: 1.2),
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(
                  isElevated ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 18,
                ),
                tooltip: isElevated
                    ? 'Descend to Ground Floor'
                    : 'Ascend to Engine Floor',
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

  Widget _buildMiniCompassCross(BuildContext context, CompassDirection activeDir, bool isElevated) {
    final colors = context.colors;
    final activeColor = isElevated ? colors.primary : colors.onSurface;
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

  String _getDirectionLabel(BuildContext context, CompassDirection dir, int floor) {
    final topology = context.read<SpatialTopology>();
    final module = topology.moduleAt(floor, dir);
    if (module == null) return dir.name.toUpperCase();

    final prefix = floor != 0 ? 'FL $floor • ' : '';
    return '$prefix${module.getFloorTitle(floor)}';
  }
}