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
                    // 🛠️ زيادة الهامش العلوي إلى 60 لمنع التداخل مع البوصلة
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
                                  Icons.edit_calendar_rounded,
                                  color: colors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'FLOOR 2 • AGENDA ENGINE',
                                  style: TextStyle(
                                    color: colors.primary,
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
                          'AGENDA PREFERENCES',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Swipe DOWN ⬇️ to return to Core Engine.',
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
                            'DEFAULT TASK PRIORITY',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: state.defaultPriority,
                            dropdownColor: colors.surface,
                            style: TextStyle(color: colors.onSurface),
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
                            title: Text(
                              'Auto-Archive Completed Tasks',
                              style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface),
                            ),
                            subtitle: Text(
                              'Keep the visual and speech list clean.',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: colors.primary,
                            value: state.autoArchiveCompleted,
                            onChanged: (v) => settingsCubit.toggleAutoArchive(v),
                          ),
                          Divider(color: colors.outline),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Speak Deadlines Aloud',
                              style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface),
                            ),
                            subtitle: Text(
                              'Always announce due date when reading tasks.',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: colors.primary,
                            value: state.speakDueDatesAloud,
                            onChanged: (v) => settingsCubit.toggleSpeakDueDates(v),
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