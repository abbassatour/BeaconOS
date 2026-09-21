// lib/agenda/cubit/agenda_cubit.dart
import 'dart:async';
import 'package:beacon_os/agenda/cubit/agenda_state.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:bloc/bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

class AgendaCubit extends Cubit<AgendaState> {
  AgendaCubit({
    required LauncherRepository repository,
    HapticManager? hapticManager,
  }) : _repository = repository,
       _haptics = hapticManager ?? HapticManager.instance,
       super(const AgendaState()) {
    _initSubscriptions();
  }

  final LauncherRepository _repository;
  final HapticManager _haptics;
  StreamSubscription<List<Task>>? _tasksSub;
  StreamSubscription<List<VoiceMemo>>? _memosSub;

  void _initSubscriptions() {
    emit(state.copyWith(status: AgendaStatus.loading));

    _tasksSub = _repository.watchTasks().listen((taskList) {
      emit(
        state.copyWith(
          status: AgendaStatus.success,
          tasks: taskList,
        ),
      );
    });

    _memosSub = _repository.watchMemos().listen((memoList) {
      emit(
        state.copyWith(
          status: AgendaStatus.success,
          memos: memoList,
        ),
      );
    });
  }

  /// تبديل حالة المهمة ونطق التأكيد للكفيف
  Future<void> toggleTask(Task task) async {
    await _haptics.successNotification();
    await _repository.toggleTask(task);
    final statusWord = task.isCompleted ? 'marked pending' : 'completed';
    await _repository.speak('Task $statusWord: ${task.title}');
  }

  /// نطق تفاصيل المهمة كاملة عند النقر
  Future<void> readTaskAloud(Task task) async {
    await _haptics.successNotification();
    final priorityText = 'Priority ${task.priority}.';
    final dueText = task.dueDate != null
        ? 'Due on ${task.dueDate!.month}/${task.dueDate!.day}.'
        : 'No deadline.';
    final statusText = task.isCompleted ? 'Completed.' : 'Pending.';
    await _repository.speak(
      '${task.title}. $priorityText $dueText $statusText',
    );
  }

  /// إضافة مهمة جديدة وتأكيدها صوتياً وسحابياً
  Future<void> addNewTask({
    required String title,
    DateTime? dueDate,
    String priority = 'medium',
  }) async {
    await _haptics.successNotification();
    await _repository.createTask(
      title: title,
      dueDate: dueDate,
      priority: priority,
    );
    await _repository.speak('Task created: $title');
  }

  /// حذف مهمة
  Future<void> deleteTask(Task task) async {
    await _haptics.successNotification();
    await _repository.deleteTask(task);
    await _repository.speak('Task deleted.');
  }

  /// نطق محتوى المذكرة الصوتية
  Future<void> readMemoAloud(VoiceMemo memo) async {
    await _haptics.successNotification();
    await _repository.speak(
      'Note titled: ${memo.title}. Content: ${memo.content}',
    );
  }

  /// حذف مذكرة
  Future<void> deleteMemo(VoiceMemo memo) async {
    await _haptics.successNotification();
    await _repository.deleteMemo(memo.id);
  }

  @override
  Future<void> close() {
    _tasksSub?.cancel();
    _memosSub?.cancel();
    return super.close();
  }
}
