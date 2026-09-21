// lib/focus_alarms/cubit/focus_alarms_cubit.dart
import 'dart:async';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:beacon_os/focus_alarms/cubit/focus_alarms_state.dart';
import 'package:bloc/bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

class FocusAlarmsCubit extends Cubit<FocusAlarmsState> {
  FocusAlarmsCubit({
    required LauncherRepository repository,
    HapticManager? hapticManager,
  })  : _repository = repository,
        _haptics = hapticManager ?? HapticManager.instance,
        super(const FocusAlarmsState()) {
    _initStreams();
  }

  final LauncherRepository _repository;
  final HapticManager _haptics;

  Timer? _ticker;
  StreamSubscription<List<Alarm>>? _alarmsSub;
  StreamSubscription<List<FocusSession>>? _sessionsSub;

  void _initStreams() {
    _alarmsSub = _repository.watchAlarms().listen((alarmList) {
      emit(state.copyWith(alarms: alarmList));
    });

    _sessionsSub = _repository.watchTodayFocusSessions().listen((sessions) {
      emit(state.copyWith(todayCompletedSessions: sessions));
    });
  }

  // ==========================================
  // ⏱️ التحكم بمؤقت التركيز والمذاكرة (Study Timer)
  // ==========================================

  void selectDuration(int minutes) {
    if (state.isTimerRunning) return;
    _ticker?.cancel();
    emit(state.copyWith(
      selectedDurationMinutes: minutes,
      remainingSeconds: minutes * 60,
      timerStatus: TimerStatus.idle,
    ));
    _repository.speak('$minutes minutes focus session selected.');
  }

  Future<void> startTimer() async {
    _ticker?.cancel();
    await _haptics.successNotification();
    emit(state.copyWith(timerStatus: TimerStatus.running));
    await _repository.speak('Focus session started. Silence your mind.');

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (state.remainingSeconds > 1) {
        final nextSec = state.remainingSeconds - 1;
        emit(state.copyWith(remainingSeconds: nextSec));

        // نطق مقتضب عند انتصاف الوقت وعند الدقيقة الأخيرة
        if (nextSec == (state.selectedDurationMinutes * 30)) {
          _repository.speak('${(state.selectedDurationMinutes / 2).round()} minutes remaining.');
        } else if (nextSec == 60) {
          _repository.speak('One minute remaining.');
        }
      } else {
        await _onSessionCompleted();
      }
    });
  }

  Future<void> pauseTimer() async {
    _ticker?.cancel();
    await _haptics.successNotification();
    emit(state.copyWith(timerStatus: TimerStatus.paused));
    await _repository.speak('Timer paused.');
  }

  void resetTimer() {
    _ticker?.cancel();
    emit(state.copyWith(
      timerStatus: TimerStatus.idle,
      remainingSeconds: state.selectedDurationMinutes * 60,
    ));
  }

  Future<void> _onSessionCompleted() async {
    _ticker?.cancel();
    await _haptics.successNotification();
    await _repository.recordCompletedFocusSession(state.selectedDurationMinutes);
    emit(state.copyWith(
      timerStatus: TimerStatus.idle,
      remainingSeconds: state.selectedDurationMinutes * 60,
    ));
    await _repository.speak('Outstanding job. Focus session complete. Take a mindful breath.');
  }

  // ==========================================
  // ⏰ التحكم بساعة المنبهات (Alarms)
  // ==========================================

  Future<void> toggleAlarm(Alarm alarm) async {
    await _haptics.successNotification();
    await _repository.toggleAlarm(alarm);
    final status = !alarm.isActive ? 'enabled' : 'disabled';
    final timeStr = '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
    await _repository.speak('Alarm for $timeStr $status.');
  }

  Future<void> addAlarm({required int hour, required int minute, String label = 'Beacon Alarm'}) async {
    await _haptics.successNotification();
    await _repository.createAlarm(hour: hour, minute: minute, label: label);
    final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    await _repository.speak('Alarm set for $timeStr.');
  }

  Future<void> deleteAlarm(Alarm alarm) async {
    await _haptics.successNotification();
    await _repository.deleteAlarm(alarm.id);
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    _alarmsSub?.cancel();
    _sessionsSub?.cancel();
    return super.close();
  }
}