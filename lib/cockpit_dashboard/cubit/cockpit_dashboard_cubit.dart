// lib/cockpit_dashboard/cubit/cockpit_dashboard_cubit.dart
import 'dart:async';
import 'package:beacon_os/cockpit_dashboard/cubit/cockpit_dashboard_state.dart';
import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

class CockpitDashboardCubit extends Cubit<CockpitDashboardState> {
  CockpitDashboardCubit({
    required LauncherRepository repository,
    HapticManager? hapticManager,
    SoundController? soundController,
  })  : _repository = repository,
        _haptics = hapticManager ?? HapticManager.instance,
        _sound = soundController ?? SoundController.instance,
        super(const CockpitDashboardState()) {
    _initSubscriptions();
  }

  final LauncherRepository _repository;
  final HapticManager _haptics;
  final SoundController _sound;

  StreamSubscription<List<Alarm>>? _alarmsSub;
  StreamSubscription<List<Task>>? _tasksSub;
  StreamSubscription<List<VoiceMemo>>? _memosSub;
  Timer? _batteryTimer;

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

    // تحديث مستوى البطارية تلقائياً كل دقيقة
    _batteryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      refreshBattery();
    });
  }

  Future<void> refreshBattery() async {
    final result = await _repository.dispatchVoiceCommand('battery');
    emit(state.copyWith(batteryStatus: result.spokenResponse));
  }

  /// تشغيل أو إيقاف ملخص اليوم الصباحي الشامل للكفيف (Toggle Briefing)
  Future<void> playDailyBriefing() async {
    if (state.isBriefingPlaying) {
      await _repository.stopSpeaking();
      await _sound.stopAll();
      emit(state.copyWith(isBriefingPlaying: false));
      return;
    }

    await _sound.stopAll();
    await _repository.stopSpeaking();
    await _haptics.successNotification();
    await _sound.play(SoundCue.wake);

    emit(state.copyWith(isBriefingPlaying: true));

    final now = DateTime.now();
    final timeStr = DateFormat('h:mm a').format(now);
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    final buffer = StringBuffer('Good day. Today is $dateStr, $timeStr. ');

    if (state.nextAlarm != null) {
      final a = state.nextAlarm!;
      final hour12 = a.hour % 12 == 0 ? 12 : a.hour % 12;
      final period = a.hour >= 12 ? 'PM' : 'AM';
      final minuteStr = a.minute == 0 ? '' : ' and ${a.minute} minutes';
      buffer.write('Your next alarm is set for $hour12 $minuteStr $period. ');
    } else {
      buffer.write('You have no active alarms scheduled. ');
    }

    if (state.pendingTasks.isEmpty) {
      buffer.write('Your agenda is completely clear with zero pending tasks. ');
    } else {
      buffer.write(
        'You have ${state.pendingTasks.length} pending task${state.pendingTasks.length > 1 ? 's' : ''}. Top priority: ${state.pendingTasks.first.title}. ',
      );
    }

    buffer.write(state.batteryStatus);

    await _repository.speak(buffer.toString());
    emit(state.copyWith(isBriefingPlaying: false));
  }

  /// قراءة المهمة صوتياً دون تبديل حالتها
  Future<void> readTaskAloud(Task task) async {
    await _haptics.successNotification();
    final priorityText = 'Priority: ${task.priority}.';
    final dueText = task.dueDate != null
        ? 'Due: ${DateFormat('h:mm a').format(task.dueDate!)}.'
        : 'No deadline.';
    await _repository.speak('${task.title}. $priorityText $dueText');
  }

  /// تبديل حالة المهمة مع إشعار صوتي فوري
  Future<void> toggleTask(Task task) async {
    await _haptics.successNotification();
    await _repository.toggleTask(task);
    final status = task.isCompleted ? 'marked pending' : 'completed';
    await _repository.speak('Task $status: ${task.title}');
  }

  /// تبديل تفعيل المنبه مع تأكيد صوتي
  Future<void> toggleAlarm(Alarm alarm) async {
    await _haptics.successNotification();
    await _repository.toggleAlarm(alarm);
    final status = !alarm.isActive ? 'enabled' : 'disabled';
    final hourStr = alarm.hour.toString().padLeft(2, '0');
    final minStr = alarm.minute.toString().padLeft(2, '0');
    await _repository.speak('Alarm for $hourStr:$minStr $status.');
  }

  /// نطق تفاصيل المنبه القادم
  Future<void> readNextAlarmAloud(Alarm? alarm) async {
    await _haptics.successNotification();
    if (alarm == null) {
      await _repository.speak('No active alarms scheduled for today.');
    } else {
      final hour12 = alarm.hour % 12 == 0 ? 12 : alarm.hour % 12;
      final period = alarm.hour >= 12 ? 'PM' : 'AM';
      final minStr = alarm.minute == 0 ? "o'clock" : '${alarm.minute}';
      await _repository.speak(
        'Next upcoming alarm is at $hour12 $minStr $period labeled ${alarm.label}.',
      );
    }
  }

  /// قراءة المذكرة الصوتية الأخيرة
  Future<void> readMemoAloud(VoiceMemo memo) async {
    await _haptics.successNotification();
    await _repository.speak('Note titled: ${memo.title}. Content: ${memo.content}');
  }

  @override
  Future<void> close() {
    _alarmsSub?.cancel();
    _tasksSub?.cancel();
    _memosSub?.cancel();
    _batteryTimer?.cancel();
    return super.close();
  }
}