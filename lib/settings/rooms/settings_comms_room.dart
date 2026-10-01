// lib/settings/rooms/settings_comms_room.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/settings/cubit/settings_cubit.dart';
import 'package:beacon_os/settings/cubit/settings_state.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class SettingsCommsRoom extends StatelessWidget {
  const SettingsCommsRoom({super.key});

  @override
  Widget build(BuildContext context) {
    final compassCubit = context.read<SpatialCompassCubit>();
    final settingsCubit = context.read<SettingsCubit>();
    final repository = context.read<LauncherRepository>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    // 🛠️ زيادة الهامش العلوي إلى 60
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.shield_rounded,
                                  color: colors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'FLOOR 2 • COMMS & SOS ENGINE',
                                  style: TextStyle(
                                    color: colors.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            // زر العودة للمركز
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.surface,
                                foregroundColor: colors.onSurface,
                                elevation: 0,
                                side: BorderSide(color: colors.outline),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.close_fullscreen_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Core',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: compassCubit.returnToCenter,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'SAFETY & RADAR',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Swipe UP ⬆️ to return to Core Engine.',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.outline, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMERGENCY SOS BEHAVIOR',
                            style: TextStyle(
                              color: colors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Auto-Dial Primary Contact',
                              style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface),
                            ),
                            subtitle: Text(
                              'Call emergency contact instantly when SOS triggers.',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: colors.error,
                            value: state.autoDialEmergency,
                            onChanged: (v) => settingsCubit.toggleAutoDialEmergency(v),
                          ),
                          Divider(color: colors.outline),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Broadcast Live GPS Coordinates',
                              style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface),
                            ),
                            subtitle: Text(
                              'Stream live position to family radar.',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: colors.error,
                            value: state.shareGpsOnSos,
                            onChanged: (v) => settingsCubit.toggleShareGpsOnSos(v),
                          ),
                          Divider(color: colors.outline),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Announce Sender on Tap',
                              style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface),
                            ),
                            subtitle: Text(
                              'Read incoming SMS and sender name with one touch.',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: colors.primary,
                            value: state.speakIncomingSms,
                            onChanged: (v) => settingsCubit.toggleSpeakIncomingSms(v),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colors.error),
                                foregroundColor: colors.error,
                              ),
                              icon: const Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                              ),
                              label: const Text('Test SOS Voice Warning'),
                              onPressed: () => repository.speak(
                                'Emergency SOS test initiated. Coordinates simulated.',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }
}