// lib/settings/rooms/settings_core_room.dart
import 'package:beacon_os/auth/view/login_page.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_cubit.dart';
import 'package:beacon_os/subscription/view/paywall_page.dart';
import 'package:cloud_sync_api/cloud_sync_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class SettingsCoreRoom extends StatefulWidget {
  const SettingsCoreRoom({super.key});

  @override
  State<SettingsCoreRoom> createState() => _SettingsCoreRoomState();
}

class _SettingsCoreRoomState extends State<SettingsCoreRoom> {
  double _speechRate = 0.5;
  bool _hapticsEnabled = true;
  bool _soundCuesEnabled = true;

  @override
  Widget build(BuildContext context) {
    final compassCubit = context.read<SpatialCompassCubit>();
    final repository = context.read<LauncherRepository>();
    final cloudSync = CloudSyncClient();
    final userEmail = cloudSync.currentUser?.email ?? 'Guest / Offline Mode';

    return Scaffold(
      backgroundColor: AppTheme.warmPaper,
      body: SafeArea(
        child: CustomScrollView(
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
                              Icons.tune_rounded,
                              color: AppTheme.terracotta,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'FLOOR 2 • CENTER ENGINE',
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
                            'Cockpit',
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
                      'CORE & SYSTEM',
                      style: TextStyle(
                        color: AppTheme.carbonInk,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Pinch out to return to Cockpit • Swipe across for room settings',
                      style: TextStyle(color: AppTheme.mutedInk, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildCard(
                  title: 'VOICE & TTS SPEED',
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Speech Reading Rate',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(_speechRate * 2).toStringAsFixed(1)}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.terracotta,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _speechRate,
                        min: 0.25,
                        max: 1.0,
                        divisions: 6,
                        activeColor: AppTheme.terracotta,
                        inactiveColor: AppTheme.softBorder,
                        onChanged: (v) => setState(() => _speechRate = v),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.softBorder),
                        ),
                        icon: const Icon(
                          Icons.play_circle_outline_rounded,
                          color: AppTheme.terracotta,
                          size: 18,
                        ),
                        label: const Text(
                          'Test Voice Sample',
                          style: TextStyle(color: AppTheme.carbonInk),
                        ),
                        onPressed: () => repository.speak(
                          'Speech speed set to ${(_speechRate * 2).toStringAsFixed(1)} times.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildCard(
                  title: 'HAPTICS & FEEDBACK',
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Tactile Haptic Pulses',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        activeColor: AppTheme.terracotta,
                        value: _hapticsEnabled,
                        onChanged: (v) => setState(() => _hapticsEnabled = v),
                      ),
                      const Divider(color: AppTheme.softBorder),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Audio Cues & Chimes',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        activeColor: AppTheme.terracotta,
                        value: _soundCuesEnabled,
                        onChanged: (v) => setState(() => _soundCuesEnabled = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildCard(
                  title: 'CLOUD VAULT ACCOUNT',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppTheme.errorRed,
                                ),
                                foregroundColor: AppTheme.errorRed,
                              ),
                              icon: const Icon(Icons.logout_rounded, size: 16),
                              label: const Text('Sign Out'),
                              onPressed: () async {
                                await cloudSync.signOut();
                                if (context.mounted) {
                                  Navigator.of(
                                    context,
                                  ).pushReplacement(LoginPage.route());
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.terracotta,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.star_rounded, size: 16),
                              label: const Text('Pro / Sponsor'),
                              onPressed: () => Navigator.of(
                                context,
                              ).push(PaywallPage.route()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.softBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.terracotta,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
