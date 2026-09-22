// lib/settings/rooms/settings_agenda_room.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/settings/cubit/settings_cubit.dart';
import 'package:beacon_os/settings/cubit/settings_state.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsAgendaRoom extends StatelessWidget {
  const SettingsAgendaRoom({super.key});

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
                                  Icons.edit_calendar_rounded,
                                  color: AppTheme.terracotta,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'FLOOR 2 • AGENDA ENGINE',
                                  style: TextStyle(
                                    color: AppTheme.terracotta,
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
                                'Agenda',
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
                          'AGENDA PREFERENCES',
                          style: TextStyle(
                            color: AppTheme.carbonInk,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'Configure how voice tasks and notes are structured',
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
                            'DEFAULT TASK PRIORITY',
                            style: TextStyle(
                              color: AppTheme.terracotta,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: state.defaultPriority,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'high',
                                child: Text('High Priority 🔴'),
                              ),
                              DropdownMenuItem(
                                value: 'medium',
                                child: Text('Medium Priority 🟡'),
                              ),
                              DropdownMenuItem(
                                value: 'low',
                                child: Text('Low Priority ⚪'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                settingsCubit.setDefaultPriority(val);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Auto-Archive Completed Tasks',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Keep the visual and speech list clean.',
                              style: TextStyle(
                                color: AppTheme.mutedInk,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: AppTheme.terracotta,
                            value: state.autoArchiveCompleted,
                            onChanged: (v) => settingsCubit.toggleAutoArchive(v),
                          ),
                          const Divider(color: AppTheme.softBorder),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Speak Deadlines Aloud',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Always announce due date when reading tasks.',
                              style: TextStyle(
                                color: AppTheme.mutedInk,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: AppTheme.terracotta,
                            value: state.speakDueDatesAloud,
                            onChanged: (v) => settingsCubit.toggleSpeakDueDates(v),
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