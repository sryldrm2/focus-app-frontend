import 'package:flutter/material.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';
import 'package:google_fonts/google_fonts.dart';
 
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
 
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });
 
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.taskId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Renkli sol çizgi
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: task.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
 
            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: task.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.description,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatusChip(status: task.status),
                      if (task.priority != null) ...[
                        const SizedBox(width: 6),
                        _PriorityChip(priority: task.priority!),
                      ],
                      if (task.dueDate != null) ...[
                        const SizedBox(width: 6),
                        _DateChip(date: task.dueDate!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
 
            // Tamamlama butonu
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isCompleted
                      ? AppColors.success
                      : Colors.transparent,
                  border: Border.all(
                    color: task.isCompleted
                        ? AppColors.success
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── Küçük chip'ler ─────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final TaskStatus status;
  const _StatusChip({required this.status});
 
  Color get _color {
    switch (status) {
      case TaskStatus.completed:  return AppColors.success;
      case TaskStatus.inProgress: return AppColors.primary;
      case TaskStatus.cancelled:  return AppColors.error;
      case TaskStatus.onHold:     return AppColors.warning;
      case TaskStatus.notStarted: return AppColors.textSecondary;
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
 
class _PriorityChip extends StatelessWidget {
  final int priority;
  const _PriorityChip({required this.priority});
 
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag_outlined, size: 11, color: AppColors.textSecondary),
        const SizedBox(width: 2),
        Text(
          'P$priority',
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
 
class _DateChip extends StatelessWidget {
  final DateTime date;
  const _DateChip({required this.date});
 
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today_outlined,
            size: 11, color: AppColors.textSecondary),
        const SizedBox(width: 2),
        Text(
          '${date.day}/${date.month}',
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}