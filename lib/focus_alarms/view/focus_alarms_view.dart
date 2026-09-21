// lib/focus_alarms/view/focus_alarms_view.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/focus_alarms/cubit/focus_alarms_cubit.dart';
import 'package:beacon_os/focus_alarms/cubit/focus_alarms_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

class FocusAlarmsView extends StatelessWidget {
  const FocusAlarmsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FocusAlarmsCubit(
        repository: context.read<LauncherRepository>(),
      ),
      child: const _FocusAlarmsContent(),
    );
  }
}

class _FocusAlarmsContent extends StatelessWidget {
  const _FocusAlarmsContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmPaper,
      body: SafeArea(
        child: BlocBuilder<FocusAlarmsCubit, FocusAlarmsState>(
          builder: (context, state) {
            final cubit = context.read<FocusAlarmsCubit>();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. الترويسة التحريرية
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'FOCUS & ALARMS',
                              style: TextStyle(
                                color: AppTheme.carbonInk,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            IconButton.filledTonal(
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.softBorder,
                                foregroundColor: AppTheme.carbonInk,
                              ),
                              icon: const Icon(Icons.alarm_add_rounded),
                              tooltip: 'Add Alarm',
                              onPressed: () =>
                                  _showAddAlarmDialog(context, cubit),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Swipe RIGHT ➡️ or tap with two fingers to return to Core.',
                          style: TextStyle(
                            color: AppTheme.mutedInk,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. بطاقة دورة التركيز والمذاكرة (Study Pomodoro Dial)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: _buildTimerCard(context, state, cubit),
                  ),
                ),

                // 3. ساعة المنبهات المجدولة (Quiet Alarms Section)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: AppTheme.terracotta,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SCHEDULED ALARMS (${state.alarms.length})',
                          style: const TextStyle(
                            color: AppTheme.carbonInk,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.alarms.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        'No alarms scheduled. Tap + to set a silent system alarm.',
                        style: TextStyle(
                          color: AppTheme.mutedInk,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final alarm = state.alarms[index];
                          return _buildAlarmCard(alarm, cubit);
                        },
                        childCount: state.alarms.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimerCard(
    BuildContext context,
    FocusAlarmsState state,
    FocusAlarmsCubit cubit,
  ) {
    final minutes = (state.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (state.remainingSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.softBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.carbonInk.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STUDY CYCLE',
                style: TextStyle(
                  color: AppTheme.mutedInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warmPaper,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Today: ${state.totalFocusMinutesToday}m Focused',
                  style: const TextStyle(
                    color: AppTheme.terracotta,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // العداد الرقمي العريض
          Text(
            '$minutes:$seconds',
            style: const TextStyle(
              color: AppTheme.carbonInk,
              fontSize: 54,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),

          // خيارات فترات المذاكرة (15m / 25m / 45m / 60m)
          Wrap(
            spacing: 8,
            children: [15, 25, 45, 60].map((mins) {
              final isSelected = state.selectedDurationMinutes == mins;
              return ChoiceChip(
                label: Text('${mins}m'),
                selected: isSelected,
                selectedColor: AppTheme.terracotta,
                backgroundColor: AppTheme.warmPaper,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.carbonInk,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                onSelected: (_) => cubit.selectDuration(mins),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // أزرار التحكم اللمسية العريضة
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isTimerRunning
                        ? AppTheme.warmAmber
                        : AppTheme.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    state.isTimerRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    state.isTimerRunning ? 'Pause Session' : 'Start Focus',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: state.isTimerRunning
                      ? cubit.pauseTimer
                      : cubit.startTimer,
                ),
              ),
              if (state.timerStatus != TimerStatus.idle) ...[
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.warmPaper,
                    foregroundColor: AppTheme.mutedInk,
                    padding: const EdgeInsets.all(14),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Reset Timer',
                  onPressed: cubit.resetTimer,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmCard(Alarm alarm, FocusAlarmsCubit cubit) {
    final hourStr = alarm.hour.toString().padLeft(2, '0');
    final minuteStr = alarm.minute.toString().padLeft(2, '0');

    return Card(
      color: AppTheme.cardSurface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.softBorder, width: 1.2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          '$hourStr:$minuteStr',
          style: TextStyle(
            color: alarm.isActive ? AppTheme.carbonInk : AppTheme.mutedInk,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        subtitle: Text(
          '${alarm.label} • ${alarm.daysOfWeek}',
          style: const TextStyle(color: AppTheme.mutedInk, fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              activeColor: AppTheme.terracotta,
              value: alarm.isActive,
              onChanged: (_) => cubit.toggleAlarm(alarm),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.mutedInk,
                size: 20,
              ),
              onPressed: () => cubit.deleteAlarm(alarm),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAlarmDialog(BuildContext context, FocusAlarmsCubit cubit) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.terracotta,
              onPrimary: Colors.white,
              surface: AppTheme.cardSurface,
              onSurface: AppTheme.carbonInk,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      cubit.addAlarm(
        hour: pickedTime.hour,
        minute: pickedTime.minute,
        label: 'Mindful Alarm',
      );
    }
  }
}
