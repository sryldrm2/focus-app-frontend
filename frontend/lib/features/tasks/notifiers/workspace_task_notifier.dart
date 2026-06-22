import 'package:flutter/foundation.dart';
import 'package:focus_app/core/network/token_storage.dart';
import 'package:focus_app/features/pomodoro/models/pomodoro_model.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';
import 'package:focus_app/features/tasks/network/task_service.dart';

class WorkspaceTaskState {
  final String? workspaceId;
  final String? activeTaskId;
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? errorMessage;

  const WorkspaceTaskState({
    this.workspaceId,
    this.activeTaskId,
    this.tasks = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  WorkspaceTaskState copyWith({
    String? workspaceId,
    String? activeTaskId,
    bool clearActiveTask = false,
    List<TaskModel>? tasks,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      WorkspaceTaskState(
        workspaceId: workspaceId ?? this.workspaceId,
        activeTaskId:
            clearActiveTask ? null : (activeTaskId ?? this.activeTaskId),
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

  /// Oda ekranında pomodoro için seçili görev.
  void setActiveTask(String taskId) {
    if (!_state.tasks.any((t) => t.taskId == taskId)) return;
    _emit(_state.copyWith(activeTaskId: taskId));
  }

  /// SignalR WorkspaceTaskCreated — kullanıcı ilgili oda ekranındaysa listeyi günceller.
  void handleRealtimeTaskCreated(TaskModel task) {
    final wsId = task.workspaceId;
    if (wsId == null || wsId.isEmpty) return;
    if (_state.workspaceId != wsId) return;
    if (_state.tasks.any((t) => t.taskId == task.taskId)) return;

    final nextActive = _state.activeTaskId ?? task.taskId;
    _emit(
      _state.copyWith(
        tasks: [..._state.tasks, task],
        activeTaskId: nextActive,
      ),
    );
  }

  /// SignalR WorkspacePomodoroStarted — görev bu odadaysa aktif görevi günceller.
  void handleRealtimePomodoroStarted(PomodoroSessionModel session) {
    final taskId = session.taskId;
    if (taskId == null) {
      debugPrint('[WorkspaceSync] handleRealtimePomodoroStarted: taskId null');
      return;
    }
    if (_state.workspaceId == null) {
      debugPrint(
        '[WorkspaceSync] handleRealtimePomodoroStarted: workspaceId null, pending',
      );
      return;
    }
    if (!_state.tasks.any((t) => t.taskId == taskId)) {
      debugPrint(
        '[WorkspaceSync] handleRealtimePomodoroStarted: task $taskId not in list, pending',
      );
      return;
    }

    debugPrint(
      '[WorkspaceSync] handleRealtimePomodoroStarted: task $taskId found, '
      'setting active',
    );
    _emit(_state.copyWith(activeTaskId: taskId));
  }

  String? _resolveActiveTaskId(List<TaskModel> tasks, {String? preferred}) {
    if (preferred != null && tasks.any((t) => t.taskId == preferred)) {
      return preferred;
    }

    final inProgress = tasks.where(
      (t) => t.status == TaskStatus.inProgress && !t.isCompleted,
    );
    if (inProgress.isNotEmpty) return inProgress.first.taskId;

    final pending = tasks.where((t) => !t.isCompleted);
    if (pending.isNotEmpty) return pending.first.taskId;

    return null;
  }

  Future<void> loadTasks(String workspaceId) async {
    _emit(
      _state.copyWith(
        isLoading: true,
        clearError: true,
        workspaceId: workspaceId,
      ),
    );
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Oturum bulunamadı.');
      final tasks = await _service.getWorkspaceTasks(token, workspaceId);
      final activeId = _resolveActiveTaskId(
        tasks,
        preferred:
            _state.workspaceId == workspaceId ? _state.activeTaskId : null,
      );
      _emit(
        _state.copyWith(
          tasks: tasks,
          isLoading: false,
          workspaceId: workspaceId,
          activeTaskId: activeId,
          clearActiveTask: activeId == null,
        ),
      );
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
      _emit(
        _state.copyWith(
          isLoading: false,
          tasks: [..._state.tasks, task],
          activeTaskId: task.taskId,
        ),
      );
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

  Future<bool> updateTask(String taskId, UpdateTaskDto dto) async {
    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Oturum bulunamadı.');
      final updated = await _service.updateTask(token, taskId, dto);
      _emit(
        _state.copyWith(
          isLoading: false,
          tasks: _state.tasks
              .map((t) => t.taskId == taskId ? updated : t)
              .toList(),
        ),
      );
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
    final newStatus =
        task.isCompleted ? TaskStatus.notStarted : TaskStatus.completed;
    final updatedTasks = _state.tasks
        .map(
          (t) => t.taskId == task.taskId ? t.copyWith(status: newStatus) : t,
        )
        .toList();

    _emit(
      _state.copyWith(
        tasks: updatedTasks,
        clearActiveTask:
            newStatus == TaskStatus.completed && _state.activeTaskId == task.taskId,
        activeTaskId: newStatus == TaskStatus.completed &&
                _state.activeTaskId == task.taskId
            ? _resolveActiveTaskId(updatedTasks)
            : _state.activeTaskId,
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
    final wasActive = _state.activeTaskId == taskId;
    final remaining = _state.tasks.where((t) => t.taskId != taskId).toList();
    final nextActive =
        wasActive ? _resolveActiveTaskId(remaining) : _state.activeTaskId;

    _emit(
      _state.copyWith(
        tasks: remaining,
        activeTaskId: nextActive,
        clearActiveTask: wasActive && nextActive == null,
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
