import 'package:flutter/foundation.dart';
import 'package:focus_app/core/network/token_storage.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';
import 'package:focus_app/features/tasks/network/task_service.dart';

// ── State ──────────────────────────────────────────────────
class TaskState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? errorMessage;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  TaskState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? errorMessage,
  }) => TaskState(
    tasks: tasks ?? this.tasks,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
  );

  List<TaskModel> get todayTasks {
    final today = DateTime.now();
    return tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == today.year &&
          t.dueDate!.month == today.month &&
          t.dueDate!.day == today.day;
    }).toList();
  }

  List<TaskModel> tasksForDate(DateTime date) => tasks.where((t) {
    if (t.dueDate == null) return false;
    return t.dueDate!.year == date.year &&
        t.dueDate!.month == date.month &&
        t.dueDate!.day == date.day;
  }).toList();
}

// ── Notifier ───────────────────────────────────────────────
class TaskNotifier extends ChangeNotifier {
  final _service = TaskService();
 
  TaskState _state = const TaskState();
  TaskState get state => _state;
 
  void _emit(TaskState s) {
    _state = s;
    notifyListeners();
  }
 
  // ─── Görevleri yükle ────────────────────────────────────
  Future<void> loadTasks() async {
    _emit(_state.copyWith(isLoading: true));
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Oturum bulunamadı.');
      final tasks = await _service.getTasks(token);
      _emit(_state.copyWith(tasks: tasks, isLoading: false));
    } catch (e) {
      _emit(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
 
  // ─── Görev ekle ─────────────────────────────────────────
  Future<bool> addTask(CreateTaskDto dto) async {
    _emit(_state.copyWith(isLoading: true));
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Oturum bulunamadı.');
      final newTask = await _service.createTask(token, dto);
      _emit(_state.copyWith(
        tasks: [..._state.tasks, newTask],
        isLoading: false,
      ));
      return true;
    } catch (e) {
      _emit(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
      return false;
    }
  }
 
  // ─── Görevi tamamla / geri al ───────────────────────────
  Future<void> toggleComplete(TaskModel task) async {
    final newStatus = task.isCompleted
        ? TaskStatus.notStarted
        : TaskStatus.completed;
 
    // Optimistic update
    _emit(_state.copyWith(
      tasks: _state.tasks
          .map((t) => t.taskId == task.taskId
              ? t.copyWith(status: newStatus)
              : t)
          .toList(),
    ));
 
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Oturum bulunamadı.');
      await _service.updateTask(
        token,
        task.taskId,
        UpdateTaskDto(status: newStatus.value),
      );
    } catch (e) {
      // Hata olursa geri al
      _emit(_state.copyWith(
        tasks: _state.tasks
            .map((t) => t.taskId == task.taskId ? task : t)
            .toList(),
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
 
  // ─── Görevi sil ─────────────────────────────────────────
  Future<void> deleteTask(String taskId) async {
    final prev = List<TaskModel>.from(_state.tasks);
 
    // Optimistic update
    _emit(_state.copyWith(
      tasks: _state.tasks.where((t) => t.taskId != taskId).toList(),
    ));
 
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Oturum bulunamadı.');
      await _service.deleteTask(token, taskId);
    } catch (e) {
      // Hata olursa geri al
      _emit(_state.copyWith(
        tasks: prev,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}