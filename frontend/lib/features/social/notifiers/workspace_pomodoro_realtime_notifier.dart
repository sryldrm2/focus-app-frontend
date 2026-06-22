import 'package:flutter/foundation.dart';
import 'package:focus_app/features/pomodoro/models/pomodoro_model.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';

class WorkspacePomodoroRealtimeState {
  final String? workspaceId;
  final PomodoroSessionModel? session;

  const WorkspacePomodoroRealtimeState({
    this.workspaceId,
    this.session,
  });

  WorkspacePomodoroRealtimeState copyWith({
    String? workspaceId,
    PomodoroSessionModel? session,
    bool clearSession = false,
  }) =>
      WorkspacePomodoroRealtimeState(
        workspaceId: workspaceId ?? this.workspaceId,
        session: clearSession ? null : (session ?? this.session),
      );
}

/// Workspace odasındaki uzaktan başlatılan pomodoro oturumlarını taşır.
/// Kişisel [PomodoroNotifier.currentSession] yalnızca oturumu başlatan kullanıcıda dolu olur;
/// diğer üyeler bu notifier üzerinden senkronize olur.
class WorkspacePomodoroRealtimeNotifier extends ChangeNotifier {
  WorkspacePomodoroRealtimeState _state = const WorkspacePomodoroRealtimeState();
  WorkspacePomodoroRealtimeState get state => _state;

  PomodoroSessionModel? _pendingSession;

  void _emit(WorkspacePomodoroRealtimeState s) {
    _state = s;
    notifyListeners();
  }

  void handleRemoteSessionStarted({
    required PomodoroSessionModel session,
    required String? viewerWorkspaceId,
    required List<TaskModel> tasks,
    String? localStarterPomoId,
  }) {
    if (!session.isOngoing) return;

    // Yalnızca oturumu başlatan kullanıcıda kişisel session ile aynı pomoId varsa atla.
    if (localStarterPomoId != null && localStarterPomoId == session.pomoId) {
      debugPrint(
        '[WorkspaceSync] handleRemoteSessionStarted: skip starter duplicate '
        'pomoId=${session.pomoId}',
      );
      return;
    }

    final taskId = session.taskId;
    if (taskId == null) return;

    final task = tasks.where((t) => t.taskId == taskId).firstOrNull;
    if (task == null) {
      _pendingSession = session;
      debugPrint(
        '[WorkspaceSync] handleRemoteSessionStarted: task $taskId pending',
      );
      return;
    }

    final workspaceId = _resolveWorkspaceId(task, viewerWorkspaceId);
    if (workspaceId == null) {
      _pendingSession = session;
      debugPrint(
        '[WorkspaceSync] handleRemoteSessionStarted: workspaceId pending '
        'taskId=$taskId',
      );
      return;
    }

    _pendingSession = null;
    applyRemoteSession(workspaceId: workspaceId, session: session);
  }

  void tryApplyPending({
    required String? viewerWorkspaceId,
    required List<TaskModel> tasks,
    String? localStarterPomoId,
  }) {
    final pending = _pendingSession;
    if (pending == null) return;

    handleRemoteSessionStarted(
      session: pending,
      viewerWorkspaceId: viewerWorkspaceId,
      tasks: tasks,
      localStarterPomoId: localStarterPomoId,
    );
  }

  String? _resolveWorkspaceId(TaskModel task, String? viewerWorkspaceId) {
    final taskWorkspaceId = task.workspaceId;
    if (taskWorkspaceId != null && taskWorkspaceId.isNotEmpty) {
      return taskWorkspaceId;
    }
    return viewerWorkspaceId;
  }

  void applyRemoteSession({
    required String workspaceId,
    required PomodoroSessionModel session,
  }) {
    if (!session.isOngoing) return;
    if (_state.session?.pomoId == session.pomoId &&
        _state.workspaceId == workspaceId) {
      return;
    }

    debugPrint(
      '[WorkspaceSync] applyRemoteSession workspaceId=$workspaceId '
      'pomoId=${session.pomoId} secondsLeft=${session.remainingSeconds}',
    );

    _emit(
      WorkspacePomodoroRealtimeState(
        workspaceId: workspaceId,
        session: session,
      ),
    );
  }

  void clear() {
    _pendingSession = null;
    _emit(const WorkspacePomodoroRealtimeState());
  }
}
