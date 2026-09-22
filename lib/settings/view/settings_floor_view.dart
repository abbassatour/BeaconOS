// lib/settings/view/settings_floor_view.dart
import 'package:beacon_os/auth/view/login_page.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/core/theme/cubit/theme_cubit.dart';
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

  @override
  Widget build(BuildContext context) {
    final compassCubit = context.read<SpatialCompassCubit>();
    final repository = context.read<LauncherRepository>();
    final cloudSync = CloudSyncClient();
    final userEmail = cloudSync.currentUser?.email ?? 'Guest / Offline Vault';

    // 🌟 قراءة حالة الثيم والألوان ديناميكياً
    final themeMode = context.watch<ThemeCubit>().state;
    final isHighContrast = themeMode == AppThemeMode.highContrastOled;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: context.scaffoldBg, // يتغير ديناميكياً
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
                        Row(
                          children: [
                            Icon(
                              Icons.elevator_rounded,
                              color: colors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'FLOOR 2 • ENGINE ROOM',
                              style: TextStyle(
                                color: colors.primary,
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
                            backgroundColor: colors.surface,
                            foregroundColor: colors.onSurface,
                            elevation: 0,
                            side: BorderSide(color: colors.outline),
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
                    Text(
                      'SYSTEM SETTINGS',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pinch out or swipe DOWN ⬇️ to return to Today Cockpit.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. مختبر سرعة النطق والصوت للكفيف
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildCardContainer(
                  context: context,
                  title: 'SPEECH & TTS ENGINE',
                  icon: Icons.record_voice_over_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Speech Reading Rate',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${(_speechRate * 2).toStringAsFixed(1)}x Speed',
                            style: TextStyle(
                              color: colors.primary,
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
                        activeColor: colors.primary,
                        inactiveColor: colors.outline,
                        onChanged: (val) {
                          setState(() => _speechRate = val);
                        },
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.outline),
                            foregroundColor: colors.onSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(
                            Icons.play_circle_outline_rounded,
                            size: 18,
                            color: colors.primary,
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

            // 3. لغة الاهتزازات والتغذية الحسية
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildCardContainer(
                  context: context,
                  title: 'TACTILE HAPTICS & AUDIO CUES',
                  icon: Icons.vibration_rounded,
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Haptic Pulses',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Tactile clicks when holding or tapping.',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        activeColor: colors.primary,
                        value: _hapticsEnabled,
                        onChanged: (v) => setState(() => _hapticsEnabled = v),
                      ),
                      Divider(color: colors.outline),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Sound Feedback Cues',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Chimes for listening, success, and alerts.',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
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

            // 4. الثيم المزدوج 🌟 (التبديل بين الثيمين)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildCardContainer(
                  context: context,
                  title: 'DISPLAY & ACCESSIBILITY',
                  icon: Icons.contrast_rounded,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'High-Contrast OLED (Ice-Void)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Pure black background with cyan highlights for low vision.',
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                    ),
                    activeColor: colors.primary,
                    value: isHighContrast, // القيمة الديناميكية
                    onChanged: (v) {
                      // استدعاء تغيير الثيم الفوري!
                      context.read<ThemeCubit>().toggleTheme(isHighContrast: v);
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

            // 5. خزينة الحساب والمزامنة
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildCardContainer(
                  context: context,
                  title: 'CLOUD VAULT & ACCOUNT',
                  icon: Icons.cloud_done_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Account Email',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.scaffoldBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Encrypted',
                              style: TextStyle(
                                color: colors.primary,
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
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.error),
                            foregroundColor: colors.error,
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

            // 6. التراخيص والكفالة
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildCardContainer(
                  context: context,
                  title: 'SUBSCRIPTION & SPONSORSHIP',
                  icon: Icons.workspace_premium_rounded,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: colors.primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.star_rounded,
                            color: colors.primary,
                          ),
                        ),
                        title: Text(
                          'BeaconOS Pro & Sponsorship',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Gift unlimited vision to a blind user or unlock Pro.',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: colors.onSurfaceVariant,
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
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.04),
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
              Icon(icon, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colors.primary,
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