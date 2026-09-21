// lib/focus_alarms/cubit/focus_alarms_state.dart
import 'package:equatable/equatable.dart';
import 'package:local_vault_api/local_vault_api.dart';

enum TimerStatus { idle, running, paused, breakTime }

class FocusAlarmsState extends Equatable {
  const FocusAlarmsState({
    this.timerStatus = TimerStatus.idle,
    this.selectedDurationMinutes = 25,
    this.remainingSeconds = 25 * 60,
    this.alarms = const [],
    this.todayCompletedSessions = const [],
  });

  final TimerStatus timerStatus;
  final int selectedDurationMinutes;
  final int remainingSeconds;
  final List<Alarm> alarms;
  final List<FocusSession> todayCompletedSessions;

  bool get isTimerRunning => timerStatus == TimerStatus.running;

  /// إجمالي دقائق التركيز المنجزة اليوم
  int get totalFocusMinutesToday =>
      todayCompletedSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

  double get progress =>
      1.0 - (remainingSeconds / (selectedDurationMinutes * 60));

  FocusAlarmsState copyWith({
    TimerStatus? timerStatus,
    int? selectedDurationMinutes,
    int? remainingSeconds,
    List<Alarm>? alarms,
    List<FocusSession>? todayCompletedSessions,
  }) {
    return FocusAlarmsState(
      timerStatus: timerStatus ?? this.timerStatus,
      selectedDurationMinutes: selectedDurationMinutes ?? this.selectedDurationMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      alarms: alarms ?? this.alarms,
      todayCompletedSessions: todayCompletedSessions ?? this.todayCompletedSessions,
    );
  }

  @override
  List<Object?> get props => [
        timerStatus,
        selectedDurationMinutes,
        remainingSeconds,
        alarms,
        todayCompletedSessions,
      ];
}