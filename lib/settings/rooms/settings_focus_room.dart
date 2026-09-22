// lib/settings/rooms/settings_focus_room.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/settings/cubit/settings_cubit.dart';
import 'package:beacon_os/settings/cubit/settings_state.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsFocusRoom extends StatelessWidget {
  const SettingsFocusRoom({super.key});

  @override
  Widget build(BuildContext context) {
    final compassCubit = context.read<SpatialCompassCubit>();
    final settingsCubit = context.read<SettingsCubit>();

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
                                  Icons.hourglass_top_rounded,
                                  color: AppTheme.warmAmber,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'FLOOR 2 • FOCUS ENGINE',
                                  style: TextStyle(
                                    color: AppTheme.warmAmber,
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
                                'Focus',
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
                          'FOCUS & ALARMS TUNING',
                          style: TextStyle(
                            color: AppTheme.carbonInk,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'Customize study intervals, reminders, and silent alarms',
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
                            'STUDY TIMER ANNOUNCEMENTS',
                            style: TextStyle(
                              color: AppTheme.warmAmber,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Halfway Voice Reminder',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Quietly announce remaining minutes at midpoint.',
                              style: TextStyle(
                                color: AppTheme.mutedInk,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: AppTheme.warmAmber,
                            value: state.voiceChimeHalfway,
                            onChanged: (v) => settingsCubit.toggleVoiceChimeHalfway(v),
                          ),
                          const Divider(color: AppTheme.softBorder),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Haptic Surge on Complete',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Gentle triple pulse when study session ends.',
                              style: TextStyle(
                                color: AppTheme.mutedInk,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: AppTheme.warmAmber,
                            value: state.vibrateOnSessionFinish,
                            onChanged: (v) => settingsCubit.toggleVibrateOnFinish(v),
                          ),
                          const Divider(color: AppTheme.softBorder),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Sync with Android AlarmClock',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Set genuine Android system alarms without UI popup.',
                              style: TextStyle(
                                color: AppTheme.mutedInk,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: AppTheme.warmAmber,
                            value: state.syncAlarmsWithAndroidClock,
                            onChanged: (v) => settingsCubit.toggleSyncAlarmsWithAndroid(v),
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