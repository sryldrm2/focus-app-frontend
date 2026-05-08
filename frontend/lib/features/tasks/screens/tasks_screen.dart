import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/tasks/network/task_service.dart';
import 'package:focus_app/features/tasks/providers/task_provider.dart';
import 'package:focus_app/features/tasks/widgets/add_task_sheet.dart';
import 'package:focus_app/features/tasks/widgets/date_selector.dart';
import 'package:focus_app/features/tasks/widgets/empty_state.dart';
import 'package:focus_app/features/tasks/widgets/task_card.dart';
import 'package:google_fonts/google_fonts.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(taskNotifierProvider).loadTasks());
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        initialDate: _selectedDate,
        onAdd: (dto) => ref.read(taskNotifierProvider).addTask(dto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskNotifierProvider).state;
    final tasks = state.tasksForDate(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Görevlerim',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
              size: 28,
            ),
            onPressed: _showAddSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          DateSelector(
            selectedDate: _selectedDate,
            onDateChanged: (d) => setState(() => _selectedDate = d),
          ),
          if (state.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (state.errorMessage != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      style: GoogleFonts.dmSans(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(taskNotifierProvider).loadTasks(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Tekrar Dene',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (tasks.isEmpty)
            Expanded(child: TasksEmptyState(onAdd: _showAddSheet))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: tasks.length,
                itemBuilder: (_, i) => TaskCard(
                  task: tasks[i],
                  onToggle: () =>
                      ref.read(taskNotifierProvider).toggleComplete(tasks[i]),
                  onDelete: () => ref
                      .read(taskNotifierProvider)
                      .deleteTask(tasks[i].taskId),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Görev Ekle',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
