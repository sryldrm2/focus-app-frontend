import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/pomodoro/models/pomodoro_model.dart';
import 'package:focus_app/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:focus_app/features/social/providers/workspace_provider.dart';
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
