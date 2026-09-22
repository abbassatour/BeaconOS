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

    return Scaffold(
      backgroundColor: AppTheme.warmPaper,
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.shield_rounded,
                                  color: AppTheme.errorRed,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'FLOOR 2 • COMMS & SOS ENGINE',
                                  style: TextStyle(
                                    color: AppTheme.errorRed,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.cardSurface,
                                foregroundColor: AppTheme.carbonInk,
                                elevation: 0,
                                side: const BorderSide(color: AppTheme.softBorder),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.arrow_downward_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Comms',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: compassCubit.returnToGroundFloor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'SAFETY & RADAR',
                          style: TextStyle(
                            color: AppTheme.carbonInk,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'Emergency radar triggers and hands-free messaging rules',
                          style: TextStyle(color: AppTheme.mutedInk, fontSize: 13),
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
                        color: AppTheme.cardSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.softBorder, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EMERGENCY SOS BEHAVIOR',
                            style: TextStyle(
                              color: AppTheme.errorRed,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Auto-Dial Primary Contact',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Call emergency contact instantly when SOS triggers.',
                              style: TextStyle(
                                color: AppTheme.mutedInk,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: AppTheme.errorRed,
                            value: state.autoDialEmergency,
                            onChanged: (v) => settingsCubit.toggleAutoDialEmergency(v),
                          ),
                          const Divider(color: AppTheme.softBorder),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Broadcast Live GPS Coordinates',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Stream live position to family radar.',
                              style: TextStyle(
                                color: AppTheme.mutedInk,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: AppTheme.errorRed,
                            value: state.shareGpsOnSos,
                            onChanged: (v) => settingsCubit.toggleShareGpsOnSos(v),
                          ),
                          const Divider(color: AppTheme.softBorder),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Announce Sender on Tap',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Read incoming SMS and sender name with one touch.',
                              style: TextStyle(
                                color: AppTheme.mutedInk,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: AppTheme.terracotta,
                            value: state.speakIncomingSms,
                            onChanged: (v) => settingsCubit.toggleSpeakIncomingSms(v),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.errorRed),
                                foregroundColor: AppTheme.errorRed,
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
              ],
            );
          },
        ),
      ),
    );
  }
}