// lib/settings/rooms/settings_core_room.dart
import 'package:beacon_os/auth/view/login_page.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/core/theme/cubit/theme_cubit.dart';
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
    final repository = context.read<LauncherRepository>();
    final cloudSync = CloudSyncClient();
    final userEmail = cloudSync.currentUser?.email ?? 'Guest / Offline Mode';

    // 🌟 قراءة حالة الثيم والألوان ديناميكياً
    final themeMode = context.watch<ThemeCubit>().state;
    final isHighContrast = themeMode == AppThemeMode.highContrastOled;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: context.scaffoldBg, // خلفية متغيرة ديناميكياً
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                // 🛠️ تم زيادة الـ Padding العلوي من 16 إلى 60 لتجنب التداخل مع البوصلة العلوية
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CORE & SYSTEM',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pinch out to return to Cockpit • Swipe across for room settings',
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            // 1. الثيم المزدوج (التبديل بين الفاتح والداكن)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildCard(
                  context: context,
                  title: 'DISPLAY & ACCESSIBILITY',
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'High-Contrast OLED (Ice-Void)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface),
                    ),
                    subtitle: Text(
                      'Pure black background with cyan highlights for low vision.',
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                    ),
                    activeColor: colors.primary,
                    value: isHighContrast,
                    onChanged: (v) {
                      context.read<ThemeCubit>().toggleTheme(isHighContrast: v);
                      repository.speak(
                        v ? 'Ice Void high contrast enabled.' : 'Warm paper theme restored.',
                      );
                    },
                  ),
                ),
              ),
            ),

            // 2. سرعة النطق
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildCard(
                  context: context,
                  title: 'VOICE & TTS SPEED',
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Speech Reading Rate',
                            style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface),
                          ),
                          Text(
                            '${(_speechRate * 2).toStringAsFixed(1)}x',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _speechRate,
                        min: 0.25,
                        max: 1.0,
                        divisions: 6,
                        activeColor: colors.primary,
                        inactiveColor: colors.outline,
                        onChanged: (v) => setState(() => _speechRate = v),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.outline),
                          foregroundColor: colors.onSurface,
                        ),
                        icon: Icon(
                          Icons.play_circle_outline_rounded,
                          color: colors.primary,
                          size: 18,
                        ),
                        label: const Text('Test Voice Sample'),
                        onPressed: () => repository.speak(
                          'Speech speed set to ${(_speechRate * 2).toStringAsFixed(1)} times.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. الاهتزازات
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildCard(
                  context: context,
                  title: 'HAPTICS & FEEDBACK',
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Tactile Haptic Pulses',
                          style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface),
                        ),
                        activeColor: colors.primary,
                        value: _hapticsEnabled,
                        onChanged: (v) => setState(() => _hapticsEnabled = v),
                      ),
                      Divider(color: colors.outline),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Audio Cues & Chimes',
                          style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface),
                        ),
                        activeColor: colors.primary,
                        value: _soundCuesEnabled,
                        onChanged: (v) => setState(() => _soundCuesEnabled = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. الحساب السحابي
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildCard(
                  context: context,
                  title: 'CLOUD VAULT ACCOUNT',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colors.error),
                                foregroundColor: colors.error,
                              ),
                              icon: const Icon(Icons.logout_rounded, size: 16),
                              label: const Text('Sign Out'),
                              onPressed: () async {
                                await cloudSync.signOut();
                                if (context.mounted) {
                                  Navigator.of(context).pushReplacement(LoginPage.route());
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.surface,
                              ),
                              icon: const Icon(Icons.star_rounded, size: 16),
                              label: const Text('Pro / Sponsor'),
                              onPressed: () => Navigator.of(context).push(PaywallPage.route()),
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

  Widget _buildCard({required BuildContext context, required String title, required Widget child}) {
    final colors = context.colors;
    return Container(
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
            title,
            style: TextStyle(
              color: colors.primary,
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