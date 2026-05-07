import 'package:flutter/material.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';
import 'package:focus_app/features/tasks/widgets/add_task_sheet.dart';
import 'package:focus_app/features/tasks/widgets/date_selector.dart';
import 'package:focus_app/features/tasks/widgets/empty_state.dart';
import 'package:focus_app/features/tasks/widgets/task_card.dart';
import 'package:google_fonts/google_fonts.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  DateTime _selectedDate = DateTime.now();

  // Mock state — provider eklenince burası kaldırılacak
  final List<TaskModel> _tasks = List.from(mockTasks);

  List<TaskModel> get _tasksForDate => _tasks.where((t) {
        if (t.dueDate == null) return false;
        return t.dueDate!.year == _selectedDate.year &&
            t.dueDate!.month == _selectedDate.month &&
            t.dueDate!.day == _selectedDate.day;
      }).toList();

  void _toggleComplete(TaskModel task) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.taskId == task.taskId);
      if (index == -1) return;
      final newStatus = task.isCompleted
          ? TaskStatus.notStarted
          : TaskStatus.completed;
      _tasks[index] = task.copyWith(status: newStatus);
    });
  }

  void _deleteTask(String taskId) {
    setState(() => _tasks.removeWhere((t) => t.taskId == taskId));
  }

  void _addTask(TaskModel task) {
    setState(() => _tasks.add(task));
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        initialDate: _selectedDate,
        onAdd: _addTask,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _tasksForDate;

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
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.primary, size: 28),
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
          Expanded(
            child: tasks.isEmpty
                ? TasksEmptyState(onAdd: _showAddSheet)
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: tasks.length,
                    itemBuilder: (_, i) => TaskCard(
                      task: tasks[i],
                      onToggle: () => _toggleComplete(tasks[i]),
                      onDelete: () => _deleteTask(tasks[i].taskId),
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
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}