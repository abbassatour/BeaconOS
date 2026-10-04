// lib/communications/view/settings_comms_room.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/settings/cubit/settings_cubit.dart';
import 'package:beacon_os/settings/cubit/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsCommsRoom extends StatelessWidget {
  const SettingsCommsRoom({super.key});

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
                            Icon(Icons.shield_rounded, color: colors.error, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'SAFETY & SOS RADAR',
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
                          'Floor 1 • Emergency auto-dialing, live GPS broadcasting & SMS alerts.',
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
                            'Auto-Dial Emergency Primary Contact',
                            style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Instantly initiate direct phone call upon SOS broadcast.',
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                          ),
                          activeColor: colors.error,
                          value: state.autoDialEmergency,
                          onChanged: cubit.toggleAutoDialEmergency,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCard(
                        context,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Share Live GPS on SOS',
                            style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Generate Google Maps live coordinates link for rescue team.',
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                          ),
                          activeColor: colors.error,
                          value: state.shareGpsOnSos,
                          onChanged: cubit.toggleShareGpsOnSos,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCard(
                        context,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Speak Incoming Messages Aloud',
                            style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Read sender name and message content via high-clarity TTS.',
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                          ),
                          activeColor: colors.primary,
                          value: state.speakIncomingSms,
                          onChanged: cubit.toggleSpeakIncomingSms,
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