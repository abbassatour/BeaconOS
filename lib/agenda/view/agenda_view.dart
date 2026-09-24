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
    final colors = context.colors;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: BlocBuilder<AgendaCubit, AgendaState>(
          builder: (context, state) {
            final cubit = context.read<AgendaCubit>();

            if (state.status == AgendaStatus.loading) {
              return Center(
                child: CircularProgressIndicator(color: colors.primary),
              );
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. ترويسة الغرفة التحريرية
                SliverToBoxAdapter(
                  child: Padding(
                    // زيادة الهامش لتجنب شريط البوصلة
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'AGENDA & TASKS',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            IconButton.filledTonal(
                              style: IconButton.styleFrom(
                                backgroundColor: colors.surface,
                                foregroundColor: colors.onSurface,
                                side: BorderSide(color: colors.outline),
                              ),
                              icon: const Icon(Icons.add_task_rounded),
                              tooltip: 'Add Task',
                              onPressed: () => _showAddTaskDialog(context, cubit),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Swipe DOWN ⬇️ or double-tap with two fingers to return to Core.',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 13,
                          ),
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
                        Icon(
                          Icons.radio_button_unchecked_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PENDING TASKS (${state.pendingTasks.length})',
                          style: TextStyle(
                            color: colors.onSurface,
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        'Your day is completely clear. No pending tasks.',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 14,
                        ),
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
                          return _buildTaskCard(context, task, cubit);
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
                          Icon(
                            Icons.mic_none_rounded,
                            color: colors.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'VOICE & AI NOTES (${state.memos.length})',
                            style: TextStyle(
                              color: colors.onSurface,
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
                          return _buildMemoCard(context, memo, cubit);
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
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: colors.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'COMPLETED (${state.completedTasks.length})',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
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
                          return _buildTaskCard(context, task, cubit);
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

  Widget _buildTaskCard(BuildContext context, Task task, AgendaCubit cubit) {
    final colors = context.colors;
    final isDone = task.isCompleted;
    Color priorityColor = colors.onSurfaceVariant;
    if (task.priority == 'high') priorityColor = colors.error;
    if (task.priority == 'medium') priorityColor = colors.secondary;

    return Card(
      color: colors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDone ? colors.outline : priorityColor.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: IconButton(
          icon: Icon(
            isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: isDone ? colors.onSurfaceVariant : priorityColor,
            size: 26,
          ),
          onPressed: () => cubit.toggleTask(task),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            color: isDone ? colors.onSurfaceVariant : colors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: task.dueDate != null
            ? Text(
                'Due: ${DateFormat('EEE, MMM d • h:mm a').format(task.dueDate!)}',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              )
            : null,
        trailing: IconButton(
          icon: Icon(Icons.volume_up_rounded, color: colors.primary),
          onPressed: () => cubit.readTaskAloud(task),
        ),
      ),
    );
  }

  Widget _buildMemoCard(BuildContext context, VoiceMemo memo, AgendaCubit cubit) {
    final colors = context.colors;

    return Card(
      color: colors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline, width: 1.2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colors.secondary.withValues(alpha: 0.15),
          child: Icon(Icons.notes_rounded, color: colors.secondary),
        ),
        title: Text(
          memo.title,
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          memo.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
        trailing: Icon(
          Icons.touch_app_rounded,
          color: colors.secondary,
        ),
        onTap: () => cubit.readMemoAloud(memo),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, AgendaCubit cubit) {
    final colors = context.colors;
    final titleController = TextEditingController();
    String priority = 'medium';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.outline, width: 1.5),
          ),
          title: Text(
            'New Task',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                style: TextStyle(color: colors.onSurface),
                decoration: InputDecoration(
                  labelText: 'Task title...',
                  labelStyle: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: priority,
                dropdownColor: colors.surface,
                style: TextStyle(color: colors.onSurface),
                decoration: InputDecoration(
                  labelText: 'Priority',
                  labelStyle: TextStyle(color: colors.onSurfaceVariant),
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
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final text = titleController.text.trim();
                if (text.isNotEmpty) {
                  cubit.addNewTask(title: text, priority: priority);
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text(
                'Create Task',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}