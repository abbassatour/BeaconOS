// lib/agenda/view/agenda_view.dart
import 'package:beacon_os/agenda/cubit/agenda_cubit.dart';
import 'package:beacon_os/agenda/cubit/agenda_state.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

class AgendaView extends StatelessWidget {
  const AgendaView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AgendaCubit(
        repository: context.read<LauncherRepository>(),
      ),
      child: const _AgendaContent(),
    );
  }
}

class _AgendaContent extends StatelessWidget {
  const _AgendaContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmPaper,
      body: SafeArea(
        child: BlocBuilder<AgendaCubit, AgendaState>(
          builder: (context, state) {
            final cubit = context.read<AgendaCubit>();

            if (state.status == AgendaStatus.loading) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.terracotta));
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. ترويسة الغرفة التحريرية
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'AGENDA & TASKS',
                              style: TextStyle(
                                color: AppTheme.carbonInk,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            IconButton.filledTonal(
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.softBorder,
                                foregroundColor: AppTheme.carbonInk,
                              ),
                              icon: const Icon(Icons.add_task_rounded),
                              tooltip: 'Add Task',
                              onPressed: () => _showAddTaskDialog(context, cubit),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Swipe DOWN ⬇️ or double-tap with two fingers to return to Core.',
                          style: TextStyle(color: AppTheme.mutedInk, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. المهام قيد الانتظار (Pending Tasks)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_unchecked_rounded, color: AppTheme.terracotta, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'PENDING TASKS (${state.pendingTasks.length})',
                          style: const TextStyle(
                            color: AppTheme.carbonInk,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.pendingTasks.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Text(
                        'Your day is completely clear. No pending tasks.',
                        style: TextStyle(color: AppTheme.mutedInk, fontSize: 14),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = state.pendingTasks[index];
                          return _buildTaskCard(task, cubit);
                        },
                        childCount: state.pendingTasks.length,
                      ),
                    ),
                  ),

                // 3. بنك المذكرات والملاحظات الصوتية (Voice Memos)
                if (state.memos.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.mic_none_rounded, color: AppTheme.warmAmber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'VOICE & AI NOTES (${state.memos.length})',
                            style: const TextStyle(
                              color: AppTheme.carbonInk,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final memo = state.memos[index];
                          return _buildMemoCard(memo, cubit);
                        },
                        childCount: state.memos.length,
                      ),
                    ),
                  ),
                ],

                // 4. المهام المكتملة (Completed Tasks)
                if (state.completedTasks.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppTheme.mutedInk, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'COMPLETED (${state.completedTasks.length})',
                            style: const TextStyle(
                              color: AppTheme.mutedInk,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = state.completedTasks[index];
                          return _buildTaskCard(task, cubit);
                        },
                        childCount: state.completedTasks.length,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, AgendaCubit cubit) {
    final isDone = task.isCompleted;
    Color priorityColor = AppTheme.mutedInk;
    if (task.priority == 'high') priorityColor = AppTheme.errorRed;
    if (task.priority == 'medium') priorityColor = AppTheme.warmAmber;

    return Card(
      color: AppTheme.cardSurface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDone ? AppTheme.softBorder : priorityColor.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: IconButton(
          icon: Icon(
            isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: isDone ? AppTheme.mutedInk : priorityColor,
            size: 26,
          ),
          onPressed: () => cubit.toggleTask(task),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            color: isDone ? AppTheme.mutedInk : AppTheme.carbonInk,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: task.dueDate != null
            ? Text(
                'Due: ${DateFormat('EEE, MMM d • h:mm a').format(task.dueDate!)}',
                style: const TextStyle(color: AppTheme.mutedInk, fontSize: 12),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.volume_up_rounded, color: AppTheme.terracotta),
          onPressed: () => cubit.readTaskAloud(task),
        ),
      ),
    );
  }

  Widget _buildMemoCard(VoiceMemo memo, AgendaCubit cubit) {
    return Card(
      color: AppTheme.cardSurface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.softBorder, width: 1.2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFEF3C7),
          child: Icon(Icons.notes_rounded, color: AppTheme.warmAmber),
        ),
        title: Text(
          memo.title,
          style: const TextStyle(
            color: AppTheme.carbonInk,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          memo.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.mutedInk, fontSize: 13),
        ),
        trailing: const Icon(Icons.touch_app_rounded, color: AppTheme.warmAmber),
        onTap: () => cubit.readMemoAloud(memo),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, AgendaCubit cubit) {
    final titleController = TextEditingController();
    String priority = 'medium';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.softBorder, width: 1.5),
          ),
          title: const Text(
            'New Task',
            style: TextStyle(color: AppTheme.carbonInk, fontWeight: FontWeight.w900, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Task title...',
                  labelStyle: TextStyle(color: AppTheme.mutedInk),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  labelStyle: TextStyle(color: AppTheme.mutedInk),
                ),
                items: const [
                  DropdownMenuItem(value: 'high', child: Text('High Priority 🔴')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium Priority 🟡')),
                  DropdownMenuItem(value: 'low', child: Text('Low Priority ⚪')),
                ],
                onChanged: (val) => setDialogState(() => priority = val ?? 'medium'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedInk)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.terracotta,
                foregroundColor: AppTheme.cardSurface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final text = titleController.text.trim();
                if (text.isNotEmpty) {
                  cubit.addNewTask(title: text, priority: priority);
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Create Task', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}