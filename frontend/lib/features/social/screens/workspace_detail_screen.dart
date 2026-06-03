import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/social/models/workspace_model.dart';
import 'package:focus_app/features/social/providers/workspace_provider.dart';
import 'package:focus_app/features/tasks/network/task_service.dart';
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
    Future.microtask(() => ref
        .read(workspaceTaskNotifierProvider)
        .loadTasks(widget.workspace.workspaceId));
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
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspaceTaskStateProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '${widget.workspace.memberCount}/${WorkspaceModel.maxCapacity} üye',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.isLoading ? null : _showAddTask,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.tasks.isEmpty
              ? Center(
                  child: Text(
                    'Henüz oda görevi yok.\n+ ile Senaryo 1: doğrudan oda görevi oluştur.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.tasks.length,
                  itemBuilder: (_, i) {
                    final task = state.tasks[i];
                    final notifier = ref.read(workspaceTaskNotifierProvider);
                    return TaskCard(
                      task: task,
                      onToggle: () => notifier.toggleComplete(task),
                      onDelete: () => notifier.deleteTask(task.taskId),
                    );
                  },
                ),
    );
  }
}