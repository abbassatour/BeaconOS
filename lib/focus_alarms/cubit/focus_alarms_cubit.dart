// lib/focus_alarms/cubit/focus_alarms_cubit.dart
import 'dart:async';
import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:beacon_os/focus_alarms/cubit/focus_alarms_state.dart';
import 'package:bloc/bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

class FocusAlarmsCubit extends Cubit<FocusAlarmsState> {
  FocusAlarmsCubit({
    required FocusAlarmsRepository focusRepository,
    required AssistantRepository assistantRepository, // 👈 تم الحقن المباشر هنا
    HapticManager? hapticManager,
    SoundController? soundController,
  })  : _focusRepo = focusRepository,
        _assistant = assistantRepository, // 👈 التحديث هنا
        _haptics = hapticManager ?? HapticManager.instance,
        _sound = soundController ?? SoundController.instance,
        super(const FocusAlarmsState()) {
    _initStreams();
  }

  final FocusAlarmsRepository _focusRepo;
  final AssistantRepository _assistant; // 👈 التحديث هنا
  final HapticManager _haptics;
  final SoundController _sound;

  Timer? _ticker;
  DateTime? _targetEndTime;
  StreamSubscription<List<Alarm>>? _alarmsSub;
  StreamSubscription<List<FocusSession>>? _sessionsSub;

  bool _halfwayAnnounced = false;
  bool _oneMinuteAnnounced = false;

  void _initStreams() {
    _alarmsSub = _focusRepo.watchAlarms().listen((alarmList) {
      emit(state.copyWith(alarms: alarmList));
    });

    _sessionsSub = _focusRepo.watchTodayFocusSessions().listen((sessions) {
      emit(state.copyWith(todayCompletedSessions: sessions));
    });
  }

  // ===========================================================================
  // ⏱️ التحكم بمؤقت التركيز والمذاكرة
  // ===========================================================================

  Future<void> selectDuration(int minutes) async {
    if (state.isTimerRunning) return;
    _ticker?.cancel();
    _targetEndTime = null;

    emit(
      state.copyWith(
        selectedDurationMinutes: minutes,
        remainingSeconds: minutes * 60,
        timerStatus: TimerStatus.idle,
      ),
    );

    await _sound.play(SoundCue.navCenter);
    await _haptics.successNotification();
    await _assistant.speak('$minutes minutes focus cycle selected.'); // 👈 التحديث هنا
  }

  Future<void> startTimer() async {
    _ticker?.cancel();
    _halfwayAnnounced = false;
    _oneMinuteAnnounced = false;

    await _haptics.successNotification();
    await _sound.play(SoundCue.wake);

    _targetEndTime = DateTime.now().add(Duration(seconds: state.remainingSeconds));
    emit(state.copyWith(timerStatus: TimerStatus.running));

    await _assistant.speak( // 👈 التحديث هنا
      'Focus session started for ${state.selectedDurationMinutes} minutes.',
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_targetEndTime == null) return;
      final diff = _targetEndTime!.difference(DateTime.now()).inSeconds;

      if (diff > 0) {
        emit(state.copyWith(remainingSeconds: diff));

        final halfSec = (state.selectedDurationMinutes * 60) ~/ 2;
        if (diff <= halfSec && !_halfwayAnnounced) {
          _halfwayAnnounced = true;
          await _sound.play(SoundCue.processing);
          final minsLeft = diff ~/ 60;
          await _assistant.speak('Halfway mark reached. $minsLeft minutes remaining.'); // 👈 التحديث هنا
        } else if (diff <= 60 && !_oneMinuteAnnounced) {
          _oneMinuteAnnounced = true;
          await _sound.play(SoundCue.processing);
          await _assistant.speak('One minute remaining.'); // 👈 التحديث هنا
        }
      } else {
        emit(state.copyWith(remainingSeconds: 0));
        await _onSessionCompleted();
      }
    });
  }

  Future<void> pauseTimer() async {
    _ticker?.cancel();
    _targetEndTime = null;

    await _haptics.successNotification();
    await _sound.play(SoundCue.navCenter);
    emit(state.copyWith(timerStatus: TimerStatus.paused));

    final minutes = state.remainingSeconds ~/ 60;
    await _assistant.speak('Session paused with $minutes minutes left.'); // 👈 التحديث هنا
  }

  Future<void> resetTimer() async {
    _ticker?.cancel();
    _targetEndTime = null;
    _halfwayAnnounced = false;
    _oneMinuteAnnounced = false;

    emit(
      state.copyWith(
        timerStatus: TimerStatus.idle,
        remainingSeconds: state.selectedDurationMinutes * 60,
      ),
    );

    await _haptics.successNotification();
    await _assistant.speak('Timer reset.'); // 👈 التحديث هنا
  }

  Future<void> _onSessionCompleted() async {
    _ticker?.cancel();
    _targetEndTime = null;

    await _sound.play(SoundCue.success);
    await _haptics.emergencyAlarmPulse();

    await _focusRepo.recordCompletedFocusSession(
      state.selectedDurationMinutes,
    );

    await _assistant.speak( // 👈 التحديث هنا
      'Session completed! You completed ${state.selectedDurationMinutes} minutes of focus.',
    );

    emit(
      state.copyWith(
        timerStatus: TimerStatus.idle,
        remainingSeconds: state.selectedDurationMinutes * 60,
      ),
    );
  }

  // ===========================================================================
  // ⏰ التحكم بساعة المنبهات
  // ===========================================================================

  Future<void> toggleAlarm(Alarm alarm) async {
    await _haptics.successNotification();
    await _focusRepo.toggleAlarm(alarm);

    final status = !alarm.isActive ? 'enabled' : 'disabled';
    final timeStr = _format12HourTime(alarm.hour, alarm.minute);
    await _assistant.speak('Alarm for $timeStr $status.'); // 👈 التحديث هنا
  }

  Future<void> addAlarm({
    required int hour,
    required int minute,
    String label = 'Mindful Alarm',
  }) async {
    await _haptics.successNotification();
    await _focusRepo.createAlarm(hour: hour, minute: minute, label: label);

    final timeStr = _format12HourTime(hour, minute);
    final relative = getRelativeAlarmTimeString(hour, minute);
    await _assistant.speak('Alarm set for $timeStr. Rings $relative.'); // 👈 التحديث هنا
  }

  Future<void> deleteAlarm(Alarm alarm) async {
    await _haptics.successNotification();
    await _focusRepo.deleteAlarm(alarm.id);

    final timeStr = _format12HourTime(alarm.hour, alarm.minute);
    await _assistant.speak('Alarm for $timeStr deleted.'); // 👈 التحديث هنا
  }

  Future<void> readAlarmDetailsAloud(Alarm alarm) async {
    await _haptics.successNotification();

    final timeStr = _format12HourTime(alarm.hour, alarm.minute);
    if (!alarm.isActive) {
      await _assistant.speak('Alarm for $timeStr is currently turned off.'); // 👈 التحديث هنا
      return;
    }

    final relative = getRelativeAlarmTimeString(alarm.hour, alarm.minute);
    await _assistant.speak('Alarm for $timeStr is active and rings $relative.'); // 👈 التحديث هنا
  }

  String _format12HourTime(int hour, int minute) {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour >= 12 ? 'PM' : 'AM';
    final minStr = minute == 0 ? "o'clock" : minute.toString().padLeft(2, '0');
    return '$hour12 $minStr $period';
  }

  String getRelativeAlarmTimeString(int hour, int minute) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    var alarmMinutes = hour * 60 + minute;

    var diffMinutes = alarmMinutes - currentMinutes;
    if (diffMinutes <= 0) {
      diffMinutes += 24 * 60;
    }

    final hours = diffMinutes ~/ 60;
    final mins = diffMinutes % 60;

    if (hours == 0) {
      return 'in $mins minutes';
    } else if (mins == 0) {
      return 'in $hours hours';
    } else {
      return 'in $hours hours and $mins minutes';
    }
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    _alarmsSub?.cancel();
    _sessionsSub?.cancel();
    return super.close();
  }
}