import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/stats/models/stats_summary_model.dart';
import 'package:focus_app/features/stats/providers/stats_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/features/stats/widgets/stats_summary_card.dart';
import 'package:focus_app/features/stats/widgets/weekly_focus_chart.dart';
import 'package:focus_app/features/stats/widgets/task_completion_card.dart';
import 'package:focus_app/features/stats/widgets/priority_stat_card.dart';
import 'package:focus_app/features/stats/widgets/stats_insight_card.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(statsNotifierProvider).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsStateProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Çalışma Raporum',
          style: GoogleFonts.nunito(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.errorMessage != null
          ? _ErrorView(
              message: state.errorMessage!,
              onRetry: () => ref.read(statsNotifierProvider).loadStats(),
            )
          : state.summary == null
          ? const SizedBox.shrink()
          : _StatsContent(
              summary: state.summary!,
              onRefresh: () async {
                await ref.read(statsNotifierProvider).loadStats();
              },
            ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  final StatsSummaryModel summary;
  final Future<void> Function() onRefresh;

  const _StatsContent({required this.summary, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final maxHours = summary.weeklyFocus
        .map((e) => e.focusMinutes / 60)
        .fold<double>(1, (max, value) => value > max ? value : max);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatsSummaryCard(
                  title: 'Bu Hafta',
                  value: _formatMinutes(summary.weeklyFocusMinutes),
                  icon: Icons.timer_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                StatsSummaryCard(
                  title: 'Pomodoro',
                  value: '${summary.weeklyPomodoroCount}',
                  icon: Icons.local_fire_department_outlined,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                StatsSummaryCard(
                  title: 'Bugün',
                  value: _formatMinutes(summary.todayFocusMinutes),
                  icon: Icons.today_outlined,
                  color: AppColors.info,
                ),
                const SizedBox(width: 12),
                StatsSummaryCard(
                  title: 'Toplam XP',
                  value: summary.totalPoints.toInt().toString(),
                  icon: Icons.star_outline_rounded,
                  color: AppColors.xpColor,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                StatsSummaryCard(
                  title: 'Seri',
                  value: '${summary.currentStreak} gün',
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.error,
                ),
                const SizedBox(width: 12),
                StatsSummaryCard(
                  title: 'Bugünkü Pomo',
                  value: '${summary.todayPomodoroCount}',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 20),
            StatsInsightCard(text: summary.insight),
            const SizedBox(height: 24),
            const _SectionTitle('Haftalık Odak Grafiği'),
            const SizedBox(height: 12),
            WeeklyFocusChart(
              weeklyFocus: summary.weeklyFocus,
              maxY: maxHours.ceilToDouble(),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Görev Tamamlama'),
            const SizedBox(height: 12),
            TaskCompletionCard(summary: summary),
            const SizedBox(height: 24),
            const _SectionTitle('Öncelik Analizi'),
            const SizedBox(height: 12),
            ...summary.priorityStats.map(
              (stat) => PriorityStatCard(stat: stat),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;

    if (h == 0) return '${m}dk';
    if (m == 0) return '${h}s';
    return '${h}s ${m}dk';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                'Tekrar Dene',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
