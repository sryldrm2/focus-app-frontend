import 'package:flutter/material.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskSelector extends StatelessWidget {
  final List<TaskModel> tasks;
  final TaskModel? selected;
  final ValueChanged<TaskModel> onSelect;
  final bool enabled;

  const TaskSelector({
    super.key,
    required this.tasks,
    required this.selected,
    required this.onSelect,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Bugün için görev eklenmedi',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tasks.length,
        separatorBuilder: (_,__) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final task = tasks[i];
          final isSelected = selected?.taskId == task.taskId;

          return GestureDetector(
            onTap: enabled ? () => onSelect(task) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? task.color : colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? task.color : colorScheme.outline.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: task.color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                  ]
                : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected 
                        ? Colors.white.withOpacity(0.8)
                        : task.color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    task.title,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}