import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/social/notifiers/workspace_notifier.dart';
final workspaceNotifierProvider = ChangeNotifierProvider<WorkspaceNotifier>(
  (_) => WorkspaceNotifier(),
);
final workspaceStateProvider = Provider<WorkspaceState>(
  (ref) => ref.watch(workspaceNotifierProvider).state,
);