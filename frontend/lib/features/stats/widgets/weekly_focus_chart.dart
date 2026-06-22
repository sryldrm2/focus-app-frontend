import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/stats/models/stats_summary_model.dart';
import 'package:google_fonts/google_fonts.dart';

class WeeklyFocusChart extends StatelessWidget {
  final List<DailyFocusStat> weeklyFocus;
  final double maxY;

  const WeeklyFocusChart({
    super.key,
    required this.weeklyFocus,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                _MiniStat(value: _bestDayName(), label: 'En verimli gün'),
                const Spacer(),
                _MiniStat(
                  value: _formatMinutes(_dailyAverageMinutes()),
                  label: 'Günlük ortalama',
                  alignEnd: true,
                ),
              ],
            ),
          ),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY <= 0 ? 1 : maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final minutes = weeklyFocus[group.x.toInt()].focusMinutes;

                      return BarTooltipItem(
                        _formatMinutes(minutes),
                        GoogleFonts.dmSans(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Pzt',
                          'Sal',
                          'Çar',
                          'Per',
                          'Cum',
                          'Cmt',
                          'Paz',
                        ];

                        final index = value.toInt();

                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[index],
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: weeklyFocus.asMap().entries.map((entry) {
                  final x = entry.key;
                  final hours = entry.value.focusMinutes / 60;

                  return BarChartGroupData(
                    x: x,
                    barRods: [
                      BarChartRodData(
                        toY: hours,
                        width: 16,
                        color: hours > 0
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY <= 0 ? 1 : maxY,
                          color: const Color(0xFFF1F1F1),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
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

  String _bestDayName() {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    if (weeklyFocus.isEmpty) return '-';

    var bestIndex = 0;

    for (var i = 1; i < weeklyFocus.length; i++) {
      if (weeklyFocus[i].focusMinutes > weeklyFocus[bestIndex].focusMinutes) {
        bestIndex = i;
      }
    }

    if (weeklyFocus[bestIndex].focusMinutes == 0) return '-';

    return days[bestIndex];
  }

  int _dailyAverageMinutes() {
    if (weeklyFocus.isEmpty) return 0;

    final total = weeklyFocus.fold<int>(
      0,
      (sum, stat) => sum + stat.focusMinutes,
    );

    return (total / weeklyFocus.length).round();
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final bool alignEnd;

  const _MiniStat({
    required this.value,
    required this.label,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
