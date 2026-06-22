import 'package:flutter/material.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/stats/models/stats_summary_model.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskCompletionCard extends StatelessWidget {
  final StatsSummaryModel summary;

  const TaskCompletionCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final percent = (summary.taskCompletionRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$percent% tamamlandı',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.completedTasks}/${summary.totalTasks} görev tamamlandı',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: summary.taskCompletionRate,
              minHeight: 9,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}