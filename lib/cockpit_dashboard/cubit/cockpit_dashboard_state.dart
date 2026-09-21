// lib/cockpit_dashboard/cubit/cockpit_dashboard_state.dart
import 'package:equatable/equatable.dart';
import 'package:local_vault_api/local_vault_api.dart';

enum CockpitStatus { initial, loading, success, error }

class CockpitDashboardState extends Equatable {
  const CockpitDashboardState({
    this.status = CockpitStatus.initial,
    this.alarms = const [],
    this.tasks = const [],
    this.memos = const [],
    this.batteryStatus = 'Checking battery...',
    this.isBriefingPlaying = false,
    this.errorMessage,
  });

  final CockpitStatus status;
  final List<Alarm> alarms;
  final List<Task> tasks;
  final List<VoiceMemo> memos;
  final String batteryStatus;
  final bool isBriefingPlaying;
  final String? errorMessage;

  /// المهام قيد الإنجاز اليوم مرتبة حسب الأولوية
  List<Task> get pendingTasks => tasks.where((t) => !t.isCompleted).toList();

  /// المنبه النشط القادم الأقرب
  Alarm? get nextAlarm {
    final active = alarms.where((a) => a.isActive).toList();
    if (active.isEmpty) return null;
    final now = DateTime.now();
    active.sort((a, b) {
      final aDiff = (a.hour * 60 + a.minute) - (now.hour * 60 + now.minute);
      final bDiff = (b.hour * 60 + b.minute) - (now.hour * 60 + now.minute);
      return aDiff.compareTo(bDiff);
    });
    return active.first;
  }

  /// أحدث مذكرة أو ملاحظة تم تدوينها
  VoiceMemo? get latestMemo => memos.isNotEmpty ? memos.first : null;

  CockpitDashboardState copyWith({
    CockpitStatus? status,
    List<Alarm>? alarms,
    List<Task>? tasks,
    List<VoiceMemo>? memos,
    String? batteryStatus,
    bool? isBriefingPlaying,
    String? errorMessage,
  }) {
    return CockpitDashboardState(
      status: status ?? this.status,
      alarms: alarms ?? this.alarms,
      tasks: tasks ?? this.tasks,
      memos: memos ?? this.memos,
      batteryStatus: batteryStatus ?? this.batteryStatus,
      isBriefingPlaying: isBriefingPlaying ?? this.isBriefingPlaying,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    alarms,
    tasks,
    memos,
    batteryStatus,
    isBriefingPlaying,
    errorMessage,
  ];
}
