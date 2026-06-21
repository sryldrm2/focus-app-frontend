import 'package:focus_app/features/tasks/models/task_model.dart';

class DailyFocusStat {
  final DateTime date;
  final int completedPomodoros;
  final int focusMinutes;

  const DailyFocusStat({
    required this.date,
    required this.completedPomodoros,
    required this.focusMinutes,
  });
}

class PriorityStat {
  final int priority;
  final int total;
  final int completed;

  const PriorityStat({
    required this.priority,
    required this.total,
    required this.completed,
  });

  String get label {
    switch (priority) {
      case 1:
        return 'Yüksek';
      case 2:
        return 'Orta';
      case 3:
        return 'Düşük';
      default:
        return 'Belirsiz';
    }
  }

  double get completionRate {
    if (total == 0) return 0;
    return completed / total;
  }
}

class StatsSummaryModel {
  final List<DailyFocusStat> weeklyFocus;
  final int weeklyFocusMinutes;
  final int weeklyPomodoroCount;
  final int todayFocusMinutes;
  final int todayPomodoroCount;
  final double totalPoints;
  final int totalTasks;
  final int completedTasks;
  final List<PriorityStat> priorityStats;
  final String insight;
  final int currentStreak;

  const StatsSummaryModel({
    required this.weeklyFocus,
    required this.weeklyFocusMinutes,
    required this.weeklyPomodoroCount,
    required this.todayFocusMinutes,
    required this.todayPomodoroCount,
    required this.totalPoints,
    required this.totalTasks,
    required this.completedTasks,
    required this.priorityStats,
    required this.insight,
    required this.currentStreak,
  });

  double get taskCompletionRate {
    if (totalTasks == 0) return 0;
    return completedTasks / totalTasks;
  }
}