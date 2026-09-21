// lib/agenda/cubit/agenda_state.dart
import 'package:equatable/equatable.dart';
import 'package:local_vault_api/local_vault_api.dart';

enum AgendaStatus { initial, loading, success, error }

class AgendaState extends Equatable {
  const AgendaState({
    this.status = AgendaStatus.initial,
    this.tasks = const [],
    this.memos = const [],
    this.errorMessage,
  });

  final AgendaStatus status;
  final List<Task> tasks;
  final List<VoiceMemo> memos;
  final String? errorMessage;

  /// المهام قيد الإنجاز
  List<Task> get pendingTasks => tasks.where((t) => !t.isCompleted).toList();

  /// المهام المكتملة
  List<Task> get completedTasks => tasks.where((t) => t.isCompleted).toList();

  AgendaState copyWith({
    AgendaStatus? status,
    List<Task>? tasks,
    List<VoiceMemo>? memos,
    String? errorMessage,
  }) {
    return AgendaState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      memos: memos ?? this.memos,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, tasks, memos, errorMessage];
}