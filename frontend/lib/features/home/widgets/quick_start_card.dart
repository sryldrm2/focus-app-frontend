import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/pomodoro/utils/open_pomodoro.dart';
import 'package:focus_app/features/tasks/providers/task_provider.dart';
import 'package:focus_app/shared/widgets/section_card.dart';
import 'package:focus_app/shared/widgets/subject_chip.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickStartCard extends ConsumerWidget {
  const QuickStartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final tasks = ref.watch(taskNotifierProvider).state.quickStartTasks;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hızlı Başlat',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          if (tasks.isEmpty)
            Text(
              'Bugün için öncelikli görev bulunmuyor. Görev eklerken bugünün tarihini seçebilirsin.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tasks.map((task) {
                return SubjectChip(
                  name: task.title,
                  color: task.color,
                  onTap: () => openPomodoro(
                    context,
                    ref,
                    taskId: task.taskId,
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: AppColors.primary.withOpacity(0.3),
              ),
              onPressed: () => openPomodoro(context, ref),
              icon: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
              label: Text(
                'Başlat',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
