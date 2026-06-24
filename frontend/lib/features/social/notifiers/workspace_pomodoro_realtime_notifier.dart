import 'package:flutter/foundation.dart';
import 'package:focus_app/features/pomodoro/models/pomodoro_model.dart';
import 'package:focus_app/features/social/models/workspace_pomodoro_sync_event.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';

enum WorkspacePomodoroRemoteAction {
  started,
  paused,
  resumed,
  cancelled,
}

class WorkspacePomodoroRealtimeState {
  final String? workspaceId;
  final PomodoroSessionModel? session;
  final WorkspacePomodoroRemoteAction? action;
  final String? eventPomoId;
  final int? secondsLeft;
  final int syncTick;

  const WorkspacePomodoroRealtimeState({
    this.workspaceId,
    this.session,
    this.action,
    this.eventPomoId,
    this.secondsLeft,
    this.syncTick = 0,
  });

  WorkspacePomodoroRealtimeState copyWith({
    String? workspaceId,
    PomodoroSessionModel? session,
    bool clearSession = false,
    WorkspacePomodoroRemoteAction? action,
    String? eventPomoId,
    int? secondsLeft,
    int? syncTick,
  }) =>
      WorkspacePomodoroRealtimeState(
        workspaceId: workspaceId ?? this.workspaceId,
        session: clearSession ? null : (session ?? this.session),
        action: action ?? this.action,
        eventPomoId: eventPomoId ?? this.eventPomoId,
        secondsLeft: secondsLeft ?? this.secondsLeft,
        syncTick: syncTick ?? this.syncTick,
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

  void handleRemoteSyncEvent({
    required WorkspacePomodoroRemoteAction action,
    required WorkspacePomodoroSyncEvent event,
    required String? viewerWorkspaceId,
    required List<TaskModel> tasks,
  }) {
    final workspaceId = _resolveWorkspaceIdForEvent(
      event,
      viewerWorkspaceId,
      tasks,
    );
    if (workspaceId == null) {
      debugPrint(
        '[WorkspaceSync] handleRemoteSyncEvent: workspace unresolved '
        'action=$action pomoId=${event.pomoId}',
      );
      return;
    }

    debugPrint(
      '[WorkspaceSync] handleRemoteSyncEvent action=$action '
      'pomoId=${event.pomoId} secondsLeft=${event.secondsLeft}',
    );

    _emit(
      _state.copyWith(
        workspaceId: workspaceId,
        action: action,
        eventPomoId: event.pomoId,
        secondsLeft: event.secondsLeft,
        clearSession: action == WorkspacePomodoroRemoteAction.cancelled,
        syncTick: _state.syncTick + 1,
      ),
    );
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

  String? _resolveWorkspaceIdForEvent(
    WorkspacePomodoroSyncEvent event,
    String? viewerWorkspaceId,
    List<TaskModel> tasks,
  ) {
    final taskId = event.taskId;
    if (taskId != null) {
      final task = tasks.where((t) => t.taskId == taskId).firstOrNull;
      final fromTask = task != null
          ? _resolveWorkspaceId(task, viewerWorkspaceId)
          : null;
      if (fromTask != null) return fromTask;
    }
    return viewerWorkspaceId;
  }

  void applyRemoteSession({
    required String workspaceId,
    required PomodoroSessionModel session,
  }) {
    if (!session.isOngoing) return;
    if (_state.session?.pomoId == session.pomoId &&
        _state.workspaceId == workspaceId &&
        _state.action == WorkspacePomodoroRemoteAction.started) {
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
        action: WorkspacePomodoroRemoteAction.started,
        eventPomoId: session.pomoId,
        secondsLeft: session.remainingSeconds,
        syncTick: _state.syncTick + 1,
      ),
    );
  }

  void clear() {
    _pendingSession = null;
    _emit(const WorkspacePomodoroRealtimeState());
  }
}
