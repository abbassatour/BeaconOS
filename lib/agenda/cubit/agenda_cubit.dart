// lib/agenda/cubit/agenda_cubit.dart
import 'dart:async';
import 'package:beacon_os/agenda/cubit/agenda_state.dart';
import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

class AgendaCubit extends Cubit<AgendaState> {
  AgendaCubit({
    required LauncherRepository repository,
    HapticManager? hapticManager,
    SoundController? soundController,
  })  : _repository = repository,
        _haptics = hapticManager ?? HapticManager.instance,
        _sound = soundController ?? SoundController.instance,
        super(const AgendaState()) {
    _initSubscriptions();
  }

  final LauncherRepository _repository;
  final HapticManager _haptics;
  final SoundController _sound;

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
    await _sound.play(SoundCue.navCenter);
    await _repository.toggleTask(task);
    final statusWord = task.isCompleted ? 'marked pending' : 'completed';
    await _repository.speak('Task $statusWord: ${task.title}');
  }

  /// نطق تفاصيل المهمة كاملة بأسلوب زمني ذكي
  Future<void> readTaskAloud(Task task) async {
    await _haptics.successNotification();
    final priorityText = 'Priority: ${task.priority}.';
    final statusText = task.isCompleted ? 'Completed.' : 'Pending.';

    String dueText = 'No deadline.';
    if (task.dueDate != null) {
      final now = DateTime.now();
      final due = task.dueDate!;
      final timeStr = DateFormat('h:mm a').format(due);

      if (due.year == now.year && due.month == now.month && due.day == now.day) {
        dueText = 'Due today at $timeStr.';
      } else {
        dueText = 'Due on ${DateFormat('EEEE, MMMM d, h:mm a').format(due)}.';
      }
    }

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
    await _sound.play(SoundCue.success);
    await _repository.createTask(
      title: title,
      dueDate: dueDate,
      priority: priority,
    );
    await _repository.speak('Task created: $title');
  }

  /// حذف مهمة مع تأكيد صوتي
  Future<void> deleteTask(Task task) async {
    await _haptics.successNotification();
    await _sound.play(SoundCue.navCenter);
    await _repository.deleteTask(task);
    await _repository.speak('Task deleted.');
  }

  /// إنشاء مذكرة سريعة جديدة
  Future<void> addNewMemo({
    required String title,
    required String content,
  }) async {
    await _haptics.successNotification();
    await _sound.play(SoundCue.success);
    await _repository.createMemo(
      title: title,
      content: content,
    );
    await _repository.speak('Note saved: $title');
  }

  /// نطق محتوى المذكرة الصوتية
  Future<void> readMemoAloud(VoiceMemo memo) async {
    await _haptics.successNotification();
    await _repository.speak(
      'Note titled: ${memo.title}. Content: ${memo.content}',
    );
  }

  /// حذف مذكرة مع تأكيد صوتي
  Future<void> deleteMemo(VoiceMemo memo) async {
    await _haptics.successNotification();
    await _sound.play(SoundCue.navCenter);
    await _repository.deleteMemo(memo.id);
    await _repository.speak('Note deleted: ${memo.title}');
  }

  @override
  Future<void> close() {
    _tasksSub?.cancel();
    _memosSub?.cancel();
    return super.close();
  }
}