// lib/settings/view/settings_floor_view.dart
import 'package:beacon_os/auth/view/login_page.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_cubit.dart';
import 'package:beacon_os/subscription/view/paywall_page.dart';
import 'package:cloud_sync_api/cloud_sync_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class SettingsFloorView extends StatefulWidget {
  const SettingsFloorView({super.key});

  @override
  State<SettingsFloorView> createState() => _SettingsFloorViewState();
}

class _SettingsFloorViewState extends State<SettingsFloorView> {
  double _speechRate = 0.5; // السرعة الافتراضية
  bool _hapticsEnabled = true;
  bool _soundCuesEnabled = true;
  bool _isHighContrastOled = false;

  @override
  Widget build(BuildContext context) {
    final compassCubit = context.read<SpatialCompassCubit>();
    final repository = context.read<LauncherRepository>();
    final cloudSync = CloudSyncClient();
    final userEmail = cloudSync.currentUser?.email ?? 'Guest / Offline Vault';

    return Scaffold(
      backgroundColor: AppTheme.warmPaper,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. ترويسة مصعد الطابق الثاني
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
                              Icons.elevator_rounded,
                              color: AppTheme.terracotta,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'FLOOR 2 • ENGINE ROOM',
                              style: TextStyle(
                                color: AppTheme.terracotta,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        // زر النزول السريع للطابق الأرضي
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cardSurface,
                            foregroundColor: AppTheme.carbonInk,
                            elevation: 0,
                            side: const BorderSide(color: AppTheme.softBorder),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
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
                            'Ground Floor',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: compassCubit.returnToGroundFloor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'SYSTEM SETTINGS',
                      style: TextStyle(
                        color: AppTheme.carbonInk,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Pinch out or swipe DOWN ⬇️ to return to Today Cockpit.',
                      style: TextStyle(
                        color: AppTheme.mutedInk,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. مختبر سرعة النطق والصوت للكفيف (Speech Tuning)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildCardContainer(
                  title: 'SPEECH & TTS ENGINE',
                  icon: Icons.record_voice_over_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Speech Reading Rate',
                            style: TextStyle(
                              color: AppTheme.carbonInk,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${(_speechRate * 2).toStringAsFixed(1)}x Speed',
                            style: const TextStyle(
                              color: AppTheme.terracotta,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
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
                        onChanged: (val) {
                          setState(() => _speechRate = val);
                        },
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.softBorder),
                            foregroundColor: AppTheme.carbonInk,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.play_circle_outline_rounded,
                            size: 18,
                            color: AppTheme.terracotta,
                          ),
                          label: const Text('Test Voice Sample'),
                          onPressed: () {
                            repository.speak(
                              'BeaconOS speech speed set to ${(_speechRate * 2).toStringAsFixed(1)} times. Fast and accessible.',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. لغة الاهتزازات والتغذية الحسية (Tactile Haptics)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildCardContainer(
                  title: 'TACTILE HAPTICS & AUDIO CUES',
                  icon: Icons.vibration_rounded,
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Haptic Pulses',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.carbonInk,
                          ),
                        ),
                        subtitle: const Text(
                          'Tactile clicks when holding or tapping.',
                          style: TextStyle(
                            color: AppTheme.mutedInk,
                            fontSize: 12,
                          ),
                        ),
                        activeColor: AppTheme.terracotta,
                        value: _hapticsEnabled,
                        onChanged: (v) => setState(() => _hapticsEnabled = v),
                      ),
                      const Divider(color: AppTheme.softBorder),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Sound Feedback Cues',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.carbonInk,
                          ),
                        ),
                        subtitle: const Text(
                          'Chimes for listening, success, and alerts.',
                          style: TextStyle(
                            color: AppTheme.mutedInk,
                            fontSize: 12,
                          ),
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

            // 4. الثيم المزدوج (High-Contrast OLED vs Warm Paper)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildCardContainer(
                  title: 'DISPLAY & ACCESSIBILITY',
                  icon: Icons.contrast_rounded,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'High-Contrast OLED (Ice-Void)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.carbonInk,
                      ),
                    ),
                    subtitle: const Text(
                      'Pure black background with cyan highlights for low vision.',
                      style: TextStyle(color: AppTheme.mutedInk, fontSize: 12),
                    ),
                    activeColor: AppTheme.terracotta,
                    value: _isHighContrastOled,
                    onChanged: (v) {
                      setState(() => _isHighContrastOled = v);
                      repository.speak(
                        v
                            ? 'Ice Void high contrast enabled.'
                            : 'Warm paper theme restored.',
                      );
                    },
                  ),
                ),
              ),
            ),

            // 5. خزينة الحساب والمزامنة (Cloud Vault & Auth)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildCardContainer(
                  title: 'CLOUD VAULT & ACCOUNT',
                  icon: Icons.cloud_done_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Account Email',
                            style: TextStyle(
                              color: AppTheme.mutedInk,
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warmPaper,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Encrypted',
                              style: TextStyle(
                                color: AppTheme.terracotta,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          color: AppTheme.carbonInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.errorRed),
                            foregroundColor: AppTheme.errorRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Sign Out of Vault'),
                          onPressed: () async {
                            await cloudSync.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                LoginPage.route(),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 6. التراخيص والكفالة (Monetization)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildCardContainer(
                  title: 'SUBSCRIPTION & SPONSORSHIP',
                  icon: Icons.workspace_premium_rounded,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFEDD5),
                          child: Icon(
                            Icons.star_rounded,
                            color: AppTheme.terracotta,
                          ),
                        ),
                        title: const Text(
                          'BeaconOS Pro & Sponsorship',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.carbonInk,
                          ),
                        ),
                        subtitle: const Text(
                          'Gift unlimited vision to a blind user or unlock Pro.',
                          style: TextStyle(
                            color: AppTheme.mutedInk,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppTheme.mutedInk,
                        ),
                        onTap: () =>
                            Navigator.of(context).push(PaywallPage.route()),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.softBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.carbonInk.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.terracotta),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.terracotta,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
