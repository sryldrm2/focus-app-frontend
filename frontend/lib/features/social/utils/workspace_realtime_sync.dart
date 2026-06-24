import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/pomodoro/models/pomodoro_model.dart';
import 'package:focus_app/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:focus_app/features/social/notifiers/workspace_pomodoro_realtime_notifier.dart';
import 'package:focus_app/features/social/providers/workspace_provider.dart';
import 'package:focus_app/features/social/models/workspace_pomodoro_sync_event.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';

/// WorkspacePomodoroStarted event'ini görev listesi ve workspace bağlamıyla işler.
void dispatchWorkspacePomodoroStarted(
  WidgetRef ref,
  PomodoroSessionModel session,
) {
  debugPrint(
    '[WorkspaceSync] dispatchWorkspacePomodoroStarted '
    'pomoId=${session.pomoId} taskId=${session.taskId}',
  );

  final wsNotifier = ref.read(workspaceTaskNotifierProvider);
  wsNotifier.handleRealtimePomodoroStarted(session);

  final wsState = wsNotifier.state;
  final localPomoId =
      ref.read(pomodoroNotifierProvider).state.currentSession?.pomoId;

  ref.read(workspacePomodoroRealtimeNotifierProvider).handleRemoteSessionStarted(
        session: session,
        viewerWorkspaceId: wsState.workspaceId,
        tasks: wsState.tasks,
        localStarterPomoId: localPomoId,
      );
}

void dispatchWorkspacePomodoroPaused(
  WidgetRef ref,
  WorkspacePomodoroSyncEvent event,
) {
  _dispatchWorkspacePomodoroSync(
    ref,
    WorkspacePomodoroRemoteAction.paused,
    event,
  );
}

void dispatchWorkspacePomodoroResumed(
  WidgetRef ref,
  WorkspacePomodoroSyncEvent event,
) {
  _dispatchWorkspacePomodoroSync(
    ref,
    WorkspacePomodoroRemoteAction.resumed,
    event,
  );
}

void dispatchWorkspacePomodoroCancelled(
  WidgetRef ref,
  WorkspacePomodoroSyncEvent event,
) {
  _dispatchWorkspacePomodoroSync(
    ref,
    WorkspacePomodoroRemoteAction.cancelled,
    event,
  );
}

void _dispatchWorkspacePomodoroSync(
  WidgetRef ref,
  WorkspacePomodoroRemoteAction action,
  WorkspacePomodoroSyncEvent event,
) {
  final wsState = ref.read(workspaceTaskNotifierProvider).state;
  ref.read(workspacePomodoroRealtimeNotifierProvider).handleRemoteSyncEvent(
        action: action,
        event: event,
        viewerWorkspaceId: wsState.workspaceId,
        tasks: wsState.tasks,
      );
}

/// WorkspaceTaskCreated sonrası bekleyen pomodoro oturumunu uygular.
void applyPendingWorkspacePomodoro(WidgetRef ref) {
  final wsNotifier = ref.read(workspaceTaskNotifierProvider);
  final wsState = wsNotifier.state;
  final localPomoId =
      ref.read(pomodoroNotifierProvider).state.currentSession?.pomoId;

  ref.read(workspacePomodoroRealtimeNotifierProvider).tryApplyPending(
        viewerWorkspaceId: wsState.workspaceId,
        tasks: wsState.tasks,
        localStarterPomoId: localPomoId,
      );
}

/// WorkspaceTaskCreated event'ini işler ve bekleyen pomodoro varsa uygular.
void dispatchWorkspaceTaskCreated(WidgetRef ref, TaskModel task) {
  final wsNotifier = ref.read(workspaceTaskNotifierProvider);
  wsNotifier.handleRealtimeTaskCreated(task);
  applyPendingWorkspacePomodoro(ref);
}
