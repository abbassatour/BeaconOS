// lib/cockpit_dashboard/cubit/cockpit_dashboard_cubit.dart
import 'dart:async';
import 'package:beacon_os/cockpit_dashboard/cubit/cockpit_dashboard_state.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

class CockpitDashboardCubit extends Cubit<CockpitDashboardState> {
  CockpitDashboardCubit({
    required LauncherRepository repository,
    HapticManager? hapticManager,
  })  : _repository = repository,
        _haptics = hapticManager ?? HapticManager.instance,
        super(const CockpitDashboardState()) {
    _initSubscriptions();
  }

  final LauncherRepository _repository;
  final HapticManager _haptics;

  StreamSubscription<List<Alarm>>? _alarmsSub;
  StreamSubscription<List<Task>>? _tasksSub;
  StreamSubscription<List<VoiceMemo>>? _memosSub;

  void _initSubscriptions() {
    emit(state.copyWith(status: CockpitStatus.loading));

    _alarmsSub = _repository.watchAlarms().listen((alarms) {
      emit(state.copyWith(alarms: alarms, status: CockpitStatus.success));
    });

    _tasksSub = _repository.watchTasks().listen((tasks) {
      emit(state.copyWith(tasks: tasks, status: CockpitStatus.success));
    });

    _memosSub = _repository.watchMemos().listen((memos) {
      emit(state.copyWith(memos: memos, status: CockpitStatus.success));
    });

    refreshBattery();
  }

  Future<void> refreshBattery() async {
    final result = await _repository.dispatchVoiceCommand('battery');
    emit(state.copyWith(batteryStatus: result.spokenResponse));
  }

  /// نطق ملخص اليوم الصباحي الشامل للكفيف
  Future<void> playDailyBriefing() async {
    await _haptics.successNotification();
    emit(state.copyWith(isBriefingPlaying: true));

    final now = DateTime.now();
    final timeStr = DateFormat('h:mm a').format(now);
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    final buffer = StringBuffer('Good day. Today is $dateStr, $timeStr. ');

    if (state.nextAlarm != null) {
      final a = state.nextAlarm!;
      final alarmTime =
          '${a.hour.toString().padLeft(2, '0')}:${a.minute.toString().padLeft(2, '0')}';
      buffer.write('Your next alarm is set for $alarmTime. ');
    } else {
      buffer.write('You have no active alarms scheduled. ');
    }

    if (state.pendingTasks.isEmpty) {
      buffer.write('Your agenda is clear with zero pending tasks. ');
    } else {
      buffer.write(
        'You have ${state.pendingTasks.length} pending task${state.pendingTasks.length > 1 ? 's' : ''}. First task: ${state.pendingTasks.first.title}. ',
      );
    }

    buffer.write(state.batteryStatus);

    await _repository.speak(buffer.toString());
    emit(state.copyWith(isBriefingPlaying: false));
  }

  Future<void> toggleTask(Task task) async {
    await _haptics.successNotification();
    await _repository.toggleTask(task);
  }

  Future<void> toggleAlarm(Alarm alarm) async {
    await _haptics.successNotification();
    await _repository.toggleAlarm(alarm);
  }

  @override
  Future<void> close() {
    _alarmsSub?.cancel();
    _tasksSub?.cancel();
    _memosSub?.cancel();
    return super.close();
  }
}