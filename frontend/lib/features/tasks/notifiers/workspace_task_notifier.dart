import 'package:flutter/foundation.dart';
import 'package:focus_app/core/network/token_storage.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';
import 'package:focus_app/features/tasks/network/task_service.dart';

class WorkspaceTaskState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? errorMessage;
  const WorkspaceTaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.errorMessage,
  });
  WorkspaceTaskState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) => WorkspaceTaskState(
    tasks: tasks ?? this.tasks,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class WorkspaceTaskNotifier extends ChangeNotifier {
  final _service = TaskService();
  WorkspaceTaskState _state = const WorkspaceTaskState();
  WorkspaceTaskState get state => _state;

  void _emit(WorkspaceTaskState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> loadTasks(String workspaceId) async {
    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Oturum bulunamadı.');
      final tasks = await _service.getWorkspaceTasks(token, workspaceId);
      _emit(_state.copyWith(tasks: tasks, isLoading: false));
    } catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<bool> addTask(CreateTaskDto dto) async {
    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Oturum bulunamadı.');
      final task = await _service.createTask(token, dto);
      _emit(_state.copyWith(isLoading: false, tasks: [..._state.tasks, task]));
      return true;
    } catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }

  Future<void> toggleComplete(TaskModel task) async {
    final newStatus = task.isCompleted
        ? TaskStatus.notStarted
        : TaskStatus.completed;
    _emit(
      _state.copyWith(
        tasks: _state.tasks
            .map(
              (t) =>
                  t.taskId == task.taskId ? t.copyWith(status: newStatus) : t,
            )
            .toList(),
      ),
    );
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Oturum bulunamadı.');
      await _service.updateTask(
        token,
        task.taskId,
        UpdateTaskDto(status: newStatus.value),
      );
    } catch (e) {
      _emit(
        _state.copyWith(
          tasks: _state.tasks
              .map((t) => t.taskId == task.taskId ? task : t)
              .toList(),
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> deleteTask(String taskId) async {
    final prev = List<TaskModel>.from(_state.tasks);
    _emit(
      _state.copyWith(
        tasks: _state.tasks.where((t) => t.taskId != taskId).toList(),
      ),
    );
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Oturum bulunamadı.');
      await _service.deleteTask(token, taskId);
    } catch (e) {
      _emit(_state.copyWith(tasks: prev));
    }
  }
}
