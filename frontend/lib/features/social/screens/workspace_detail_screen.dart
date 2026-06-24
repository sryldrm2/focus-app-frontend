import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/auth/providers/auth_providers.dart';
import 'package:focus_app/features/notifications/network/notification_hub_service.dart';
import 'package:focus_app/features/social/models/workspace_model.dart';
import 'package:focus_app/features/social/providers/workspace_provider.dart';
import 'package:focus_app/features/social/utils/workspace_realtime_sync.dart';
import 'package:focus_app/features/social/widgets/workspace_pomodoro_panel.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';
import 'package:focus_app/features/tasks/widgets/add_task_sheet.dart';
import 'package:focus_app/features/tasks/widgets/task_card.dart';

class WorkspaceDetailScreen extends ConsumerStatefulWidget {
  final WorkspaceModel workspace;
  const WorkspaceDetailScreen({super.key, required this.workspace});

  @override
  ConsumerState<WorkspaceDetailScreen> createState() =>
      _WorkspaceDetailScreenState();
}

class _WorkspaceDetailScreenState extends ConsumerState<WorkspaceDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Workspace SignalR gruplarını DB üyeliklerine göre senkronize et.
      await ref.read(notificationHubServiceProvider).syncWorkspaceGroups();

      await ref
          .read(workspaceTaskNotifierProvider)
          .loadTasks(widget.workspace.workspaceId);

      if (!mounted) return;
      applyPendingWorkspacePomodoro(ref);
    });
  }

  void _showAddTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        initialDate: DateTime.now(),
        workspaceId: widget.workspace.workspaceId,
        title: 'Oda görevi ekle',
        onAdd: (dto) => ref.read(workspaceTaskNotifierProvider).addTask(dto),
      ),
    );
  }

  void _showEditTask(TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        initialDate: DateTime.now(),
        title: 'Görevi Düzenle',
        taskToEdit: task,
        onUpdate: (taskId, dto) =>
            ref.read(workspaceTaskNotifierProvider).updateTask(taskId, dto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(workspaceTaskStateProvider);
    final notifier = ref.read(workspaceTaskNotifierProvider);
    final currentUserId = ref.watch(authNotifierProvider).state.user?.userId ?? '';
    final isRoomOwner = currentUserId.isNotEmpty &&
        currentUserId == widget.workspace.ownerId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.workspace.workspaceName,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              '${widget.workspace.memberCount}/${WorkspaceModel.maxCapacity} üye',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isRoomOwner
          ? FloatingActionButton(
              onPressed: state.isLoading ? null : _showAddTask,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.add, color: colorScheme.onPrimary),
            )
          : null,
      body: state.isLoading && state.tasks.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WorkspacePomodoroPanel(
                  workspaceId: widget.workspace.workspaceId,
                  isRoomOwner: isRoomOwner,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Oda Görevleri',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (state.tasks.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          isRoomOwner
                              ? 'Henüz oda görevi yok.\n+ ile görev ekleyin; eklenen görev otomatik aktif görev olur.'
                              : 'Henüz oda görevi yok.\nOda sahibi görev eklediğinde burada görünecek.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => notifier.loadTasks(
                        widget.workspace.workspaceId,
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: state.tasks.length,
                        itemBuilder: (_, i) {
                          final task = state.tasks[i];
                          final isActive = state.activeTaskId == task.taskId;
                          return TaskCard(
                            task: task,
                            isActiveFocus: isActive,
                            onToggle: () => notifier.toggleComplete(task),
                            onDelete: () => notifier.deleteTask(task.taskId),
                            onEdit: () => _showEditTask(task),
                            onFocus: task.isCompleted
                                ? null
                                : () => notifier.setActiveTask(task.taskId),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
