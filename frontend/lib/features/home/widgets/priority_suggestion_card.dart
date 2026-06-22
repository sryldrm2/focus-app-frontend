import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';
import 'package:focus_app/features/tasks/providers/task_provider.dart';
import 'package:focus_app/shared/widgets/section_card.dart';
import 'package:focus_app/features/pomodoro/utils/open_pomodoro.dart';
import 'package:google_fonts/google_fonts.dart';

class PrioritySuggestionCard extends ConsumerWidget {
  const PrioritySuggestionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(taskNotifierProvider).state;

    final tasks = state.todayTasks
        .where((task) => !task.isCompleted)
        .toList()
      ..sort((a, b) {
        final aPriority = a.priority ?? 99;
        final bPriority = b.priority ?? 99;

        final priorityCompare = aPriority.compareTo(bPriority);
        if (priorityCompare != 0) return priorityCompare;

        final aDue = a.dueDate ?? DateTime(9999);
        final bDue = b.dueDate ?? DateTime(9999);

        return aDue.compareTo(bDue);
      });

    if (tasks.isEmpty) {
      return SectionCard(
        child: Row(
          children: [
            _iconBox(Icons.lightbulb_outline_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bugün için öncelikli görev bulunmuyor. Yeni görev ekleyerek gününü planlayabilirsin.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  height: 1.4,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final suggestedTask = tasks.first;

    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(Icons.auto_awesome_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Öncelikli Öneri',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Öncelik sırasına göre önce "${suggestedTask.title}" görevine odaklanabilirsin.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _PriorityChip(priority: suggestedTask.priority),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => openPomodoro(
                        context,
                        ref,
                        taskId: suggestedTask.taskId,
                      ),
                      child: Text(
                        'Başla →',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final int? priority;

  const _PriorityChip({required this.priority});

  String get label {
    switch (priority) {
      case 1:
        return 'Yüksek öncelik';
      case 2:
        return 'Orta öncelik';
      case 3:
        return 'Düşük öncelik';
      default:
        return 'Öncelik yok';
    }
  }

  Color color(BuildContext context) {
    switch (priority) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.success;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = color(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: chipColor,
        ),
      ),
    );
  }
}