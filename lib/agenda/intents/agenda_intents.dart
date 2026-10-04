// lib/agenda/intents/agenda_intents.dart
import 'package:beacon_os/core/spatial_kernel/voice_intent_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

/// معالج قراءة المهام بالمسار السريع الفوري (Sub-5ms)
class ReadTasksIntentHandler extends VoiceIntentHandler {
  @override
  String get intentId => 'READ_TASKS';

  @override
  int get priority => 75;

  @override
  RegExp get fastPathPattern => RegExp(
        r'^(what are my tasks|read tasks|my tasks|list tasks|show tasks|tasks|what tasks do i have)',
        caseSensitive: false,
      );

  @override
  Future<LauncherCommandResult> execute(
    BuildContext context,
    VoiceIntentContext intentContext,
  ) async {
    final tasksRepo = context.read<TaskAgendaRepository>();
    final pending = await tasksRepo.getPendingTasks();

    if (pending.isEmpty) {
      return const LauncherCommandResult(
        intent: 'READ_TASKS',
        spokenResponse: 'Your agenda is clear with zero pending tasks.',
      );
    }

    final topTask = pending.first;
    final count = pending.length;
    final countStr = count == 1 ? 'one task' : '$count tasks';

    return LauncherCommandResult(
      intent: 'READ_TASKS',
      spokenResponse:
          'You have $countStr pending. Top priority: ${topTask.title}.',
      actionPayload: pending,
    );
  }
}

/// معالج إضافة مهمة جديدة بالمسار السريع الفوري
class SaveTaskIntentHandler extends VoiceIntentHandler {
  @override
  String get intentId => 'SAVE_TASK';

  @override
  int get priority => 65;

  @override
  RegExp get fastPathPattern => RegExp(
        r'^(?:remind me to|add task|create task|task:?)\s+(.+)',
        caseSensitive: false,
      );

  @override
  Future<LauncherCommandResult> execute(
    BuildContext context,
    VoiceIntentContext intentContext,
  ) async {
    final tasksRepo = context.read<TaskAgendaRepository>();
    String taskTitle = '';

    // 1. استخراج النص من المسار السريع إذا تطابق النمط
    final match = fastPathPattern?.firstMatch(intentContext.rawQuery);
    if (match != null && match.groupCount >= 1) {
      taskTitle = match.group(1)?.trim() ?? '';
    }

    // 2. استخراج النص من معطيات LLM إذا أتى الاستدعاء عبر المسار الذكي
    if (taskTitle.isEmpty && intentContext.llmParameters.containsKey('title')) {
      taskTitle = intentContext.llmParameters['title'] as String;
    }

    if (taskTitle.isEmpty) {
      return const LauncherCommandResult(
        intent: 'SAVE_TASK_FAILED',
        spokenResponse: 'What task would you like me to save?',
      );
    }

    String priority = 'medium';
    if (taskTitle.toLowerCase().contains('urgent') ||
        taskTitle.toLowerCase().contains('high priority')) {
      priority = 'high';
      taskTitle = taskTitle
          .replaceAll(RegExp(r'\b(urgent|high priority)\b', caseSensitive: false), '')
          .trim();
    }

    final id = await tasksRepo.createTask(
      title: taskTitle,
      priority: priority,
    );

    return LauncherCommandResult(
      intent: 'SAVE_TASK',
      spokenResponse: 'Task added: $taskTitle.',
      actionPayload: id,
    );
  }
}

/// معالج تدوين مذكرة سريعة بالمسار السريع الفوري
class SaveMemoIntentHandler extends VoiceIntentHandler {
  @override
  String get intentId => 'SAVE_MEMO';

  @override
  int get priority => 65;

  @override
  RegExp get fastPathPattern => RegExp(
        r'^(?:note:?|memo:?|take note|save note)\s+(.+)',
        caseSensitive: false,
      );

  @override
  Future<LauncherCommandResult> execute(
    BuildContext context,
    VoiceIntentContext intentContext,
  ) async {
    final tasksRepo = context.read<TaskAgendaRepository>();
    String memoContent = '';

    final match = fastPathPattern?.firstMatch(intentContext.rawQuery);
    if (match != null && match.groupCount >= 1) {
      memoContent = match.group(1)?.trim() ?? '';
    }

    if (memoContent.isEmpty && intentContext.llmParameters.containsKey('content')) {
      memoContent = intentContext.llmParameters['content'] as String;
    }

    if (memoContent.isEmpty) {
      return const LauncherCommandResult(
        intent: 'SAVE_MEMO_FAILED',
        spokenResponse: 'Please state what you would like to note down.',
      );
    }

    final id = await tasksRepo.createMemo(
      title: 'Voice Note',
      content: memoContent,
    );

    return LauncherCommandResult(
      intent: 'SAVE_MEMO',
      spokenResponse: 'Note saved: $memoContent.',
      actionPayload: id,
    );
  }
}