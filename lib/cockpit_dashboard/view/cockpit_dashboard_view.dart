// lib/cockpit_dashboard/view/cockpit_dashboard_view.dart
import 'package:beacon_os/cockpit_dashboard/cubit/cockpit_dashboard_cubit.dart';
import 'package:beacon_os/cockpit_dashboard/cubit/cockpit_dashboard_state.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_cubit.dart';
import 'package:beacon_os/subscription/view/paywall_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

class CockpitDashboardView extends StatelessWidget {
  const CockpitDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CockpitDashboardCubit(
        repository: context.read<LauncherRepository>(),
      ),
      child: const _CockpitDashboardContent(),
    );
  }
}

class _CockpitDashboardContent extends StatelessWidget {
  const _CockpitDashboardContent();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now).toUpperCase();
    final fullDate = DateFormat('MMMM d, yyyy').format(now);
    final compassCubit = context.read<SpatialCompassCubit>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: BlocBuilder<CockpitDashboardCubit, CockpitDashboardState>(
          builder: (context, state) {
            final cubit = context.read<CockpitDashboardCubit>();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. شريط الترويسة الرئيسي
                SliverToBoxAdapter(
                  child: Padding(
                    // زيادة الهامش العلوي لتجنب التداخل مع البوصلة (HUD)
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    backgroundColor: colors.surface,
                                    foregroundColor: colors.onSurface,
                                    side: BorderSide(color: colors.outline),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: Icon(Icons.workspace_premium_rounded, size: 16, color: colors.primary),
                                  label: const Text('PRO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                                  onPressed: () => Navigator.of(context).push(PaywallPage.route()),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  style: IconButton.styleFrom(
                                    backgroundColor: colors.surface,
                                    foregroundColor: colors.onSurface,
                                    side: BorderSide(color: colors.outline),
                                    minimumSize: const Size(32, 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                  icon: const Icon(Icons.tune_rounded, size: 18),
                                  tooltip: 'Floor 2 • Engine & Settings',
                                  onPressed: compassCubit.goToSettingsFloor,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fullDate,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.battery_charging_full_rounded, size: 16, color: colors.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(
                              state.batteryStatus,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. بطاقة الإيجاز الصوتي اليومي
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: GestureDetector(
                      onTap: cubit.playDailyBriefing,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.primary, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: colors.primary,
                              child: Icon(
                                state.isBriefingPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                                color: colors.surface,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DAILY BRIEFING',
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to hear your schedule, alarms, and battery overview.',
                                    style: TextStyle(
                                      color: colors.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. المنبه القادم
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: _buildSectionTitle(context, 'NEXT UPCOMING ALARM', Icons.access_time_rounded),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildNextAlarmCard(context, state.nextAlarm, cubit),
                  ),
                ),

                // 4. مهام اليوم
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: _buildSectionTitle(context, 'TODAY\'S PRIORITIES (${state.pendingTasks.length})', Icons.check_circle_outline_rounded),
                  ),
                ),
                if (state.pendingTasks.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        'Your day is completely clear. Swipe DOWN ⬇️ to view the full agenda.',
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = state.pendingTasks[index];
                          return _buildPriorityTaskTile(context, task, cubit);
                        },
                        childCount: state.pendingTasks.take(3).length,
                      ),
                    ),
                  ),

                // 5. الملاحظات السريعة
                if (state.latestMemo != null) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                      child: _buildSectionTitle(context, 'LATEST VOICE MEMO', Icons.notes_rounded),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildMemoSnippetCard(context, state.latestMemo!),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 28, 20, 40),
                    child: _SpatialNavigationGuideFooter(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildNextAlarmCard(BuildContext context, Alarm? alarm, CockpitDashboardCubit cubit) {
    final colors = context.colors;
    if (alarm == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline),
        ),
        child: Text(
          'No scheduled alarms for today. Swipe RIGHT ➡️ to set an alarm.',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
      );
    }

    final hourStr = alarm.hour.toString().padLeft(2, '0');
    final minuteStr = alarm.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$hourStr:$minuteStr',
                style: TextStyle(color: colors.onSurface, fontSize: 26, fontWeight: FontWeight.w900),
              ),
              Text(alarm.label, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
            ],
          ),
          Switch(
            activeColor: colors.primary,
            value: alarm.isActive,
            onChanged: (_) => cubit.toggleAlarm(alarm),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityTaskTile(BuildContext context, Task task, CockpitDashboardCubit cubit) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.circle_outlined, color: colors.primary, size: 22),
            onPressed: () => cubit.toggleTask(task),
          ),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(color: colors.onSurface, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          if (task.priority == 'high') const Text('🔴', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMemoSnippetCard(BuildContext context, VoiceMemo memo) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(memo.title, style: TextStyle(color: colors.onSurface, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            memo.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SpatialNavigationGuideFooter extends StatelessWidget {
  const _SpatialNavigationGuideFooter();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        children: [
          Text(
            'SPATIAL COCKPIT GESTURES',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('⬇️ Agenda', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.onSurface)),
              Text('⬆️ Comms', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.onSurface)),
              Text('➡️ Focus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.onSurface)),
              Text('⬅️ Vision', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.onSurface)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '🤏 Pinch with 2 fingers to enter Floor 2 (Settings)',
            style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}