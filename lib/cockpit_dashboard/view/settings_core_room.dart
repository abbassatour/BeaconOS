// lib/cockpit_dashboard/view/settings_core_room.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/core/theme/cubit/theme_cubit.dart';
import 'package:beacon_os/settings/cubit/settings_cubit.dart';
import 'package:beacon_os/settings/cubit/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsCoreRoom extends StatelessWidget {
  const SettingsCoreRoom({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            final cubit = context.read<SettingsCubit>();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune_rounded, color: colors.primary, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'CORE ENGINE PREFERENCES',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Floor 1 • Sound, Haptics, and Display tuning.',
                          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildCard(
                        context,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'High Contrast OLED Theme',
                            style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Ultra-pure pitch black with neon cyan and yellow.',
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                          ),
                          activeColor: colors.primary,
                          value: state.isHighContrast,
                          onChanged: (val) {
                            cubit.toggleHighContrast(val);
                            context.read<ThemeCubit>().toggleTheme(isHighContrast: val);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCard(
                        context,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Tactile Haptic Feedback',
                            style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Physical vibrations when moving between rooms and tapping canvas.',
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                          ),
                          activeColor: colors.primary,
                          value: state.hapticsEnabled,
                          onChanged: cubit.toggleHaptics,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCard(
                        context,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Spatial Audio Cues',
                            style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Chimes and spatial frequencies when panning compass coordinates.',
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                          ),
                          activeColor: colors.primary,
                          value: state.soundCuesEnabled,
                          onChanged: cubit.toggleSoundCues,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCard(
                        context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Voice Reading Speed',
                                  style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${(state.speechRate * 2).toStringAsFixed(1)}x',
                                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              min: 0.3,
                              max: 1.0,
                              divisions: 14,
                              activeColor: colors.primary,
                              inactiveColor: colors.outline,
                              value: state.speechRate.clamp(0.3, 1.0),
                              onChanged: cubit.setSpeechRate,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline, width: 1.2),
      ),
      child: child,
    );
  }
}