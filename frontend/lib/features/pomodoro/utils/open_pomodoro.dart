import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:go_router/go_router.dart';

const _ongoingConflictMessage =
    'Devam eden bir pomodoro var. Önce onu tamamlayın veya iptal edin.';

Future<void> openPomodoro(
  BuildContext context,
  WidgetRef ref, {
  String? taskId,
}) async {
  final notifier = ref.read(pomodoroNotifierProvider);
  await notifier.checkOngoing();
  if (!context.mounted) return;

  final state = ref.read(pomodoroNotifierProvider).state;

  if (state.hasBlockingSession) {
    if (notifier.conflictsWithTask(taskId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(_ongoingConflictMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    context.go('/pomodoro');
    return;
  }

  if (taskId != null) {
    context.go('/pomodoro', extra: taskId);
  } else {
    context.go('/pomodoro');
  }
}
