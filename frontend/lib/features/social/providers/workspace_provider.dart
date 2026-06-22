import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/social/notifiers/workspace_notifier.dart';
import 'package:focus_app/features/social/notifiers/workspace_pomodoro_realtime_notifier.dart';
import 'package:focus_app/features/tasks/notifiers/workspace_task_notifier.dart';

// ── Workspace (oda) ────────────────────────────────────────
final workspaceNotifierProvider = ChangeNotifierProvider<WorkspaceNotifier>(
  (_) => WorkspaceNotifier(),
);

final workspaceStateProvider = Provider<WorkspaceState>(
  (ref) => ref.watch(workspaceNotifierProvider).state,
);

// ── Workspace görevleri (oda içi task listesi) ───────────
final workspaceTaskNotifierProvider =
    ChangeNotifierProvider<WorkspaceTaskNotifier>(
  (_) => WorkspaceTaskNotifier(),
);

final workspaceTaskStateProvider = Provider<WorkspaceTaskState>(
  (ref) => ref.watch(workspaceTaskNotifierProvider).state,
);

// ── Workspace pomodoro gerçek zamanlı senkronizasyonu ────
final workspacePomodoroRealtimeNotifierProvider =
    ChangeNotifierProvider<WorkspacePomodoroRealtimeNotifier>(
  (_) => WorkspacePomodoroRealtimeNotifier(),
);

final workspacePomodoroRealtimeProvider =
    Provider<WorkspacePomodoroRealtimeState>(
  (ref) => ref.watch(workspacePomodoroRealtimeNotifierProvider).state,
);