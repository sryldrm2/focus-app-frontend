import 'package:flutter/foundation.dart';
import 'package:focus_app/core/network/token_storage.dart';
import 'package:focus_app/features/pomodoro/network/pomodoro_service.dart';
import 'package:focus_app/features/stats/models/stats_summary_model.dart';
import 'package:focus_app/features/tasks/network/task_service.dart';

class StatsState {
  final bool isLoading;
  final String? errorMessage;
  final StatsSummaryModel? summary;

  const StatsState({this.isLoading = false, this.errorMessage, this.summary});

  StatsState copyWith({
    bool? isLoading,
    String? errorMessage,
    StatsSummaryModel? summary,
  }) {
    return StatsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      summary: summary ?? this.summary,
    );
  }
}

class StatsNotifier extends ChangeNotifier {
  final _pomodoroService = PomodoroService();
  final _taskService = TaskService();

  StatsState _state = const StatsState();
  StatsState get state => _state;

  void _emit(StatsState state) {
    _state = state;
    notifyListeners();
  }

  Future<void> loadStats() async {
    _emit(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('Oturum bulunamadı.');
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = today.add(const Duration(days: 1));

      final completedSessions = await _pomodoroService.getByDateRange(
        token,
        startDate: weekStart,
        endDate: weekEnd,
      );

      final totalPoints = await _pomodoroService.getTotalPoints(token);
      final tasks = await _taskService.getTasks(token);
      final weeklyFocus = List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));

        final sessionsForDay = completedSessions.where((session) {
          final completedAt = session.completedAt;
          if (completedAt == null) return false;

          final d = completedAt.toLocal();
          return d.year == date.year &&
              d.month == date.month &&
              d.day == date.day;
        }).toList();

        final focusMinutes = sessionsForDay.fold<int>(
          0,
          (sum, session) => sum + session.durationMinute,
        );

        return DailyFocusStat(
          date: date,
          completedPomodoros: sessionsForDay.length,
          focusMinutes: focusMinutes,
        );
      });

      final todayStat = weeklyFocus.firstWhere(
        (stat) =>
            stat.date.year == today.year &&
            stat.date.month == today.month &&
            stat.date.day == today.day,
        orElse: () =>
            DailyFocusStat(date: today, completedPomodoros: 0, focusMinutes: 0),
      );

      final weeklyFocusMinutes = weeklyFocus.fold<int>(
        0,
        (sum, stat) => sum + stat.focusMinutes,
      );

      final weeklyPomodoroCount = weeklyFocus.fold<int>(
        0,
        (sum, stat) => sum + stat.completedPomodoros,
      );

      final totalTasks = tasks.length;
      final completedTasks = tasks.where((task) => task.isCompleted).length;

      final priorityStats = [1, 2, 3].map((priority) {
        final priorityTasks = tasks
            .where((task) => task.priority == priority)
            .toList();

        return PriorityStat(
          priority: priority,
          total: priorityTasks.length,
          completed: priorityTasks.where((task) => task.isCompleted).length,
        );
      }).toList();

      final currentStreak = _calculateCurrentStreak(weeklyFocus);

      final insight = _buildInsight(
        weeklyFocus: weeklyFocus,
        completedTasks: completedTasks,
        totalTasks: totalTasks,
        todayPomodoroCount: todayStat.completedPomodoros,
      );

      final summary = StatsSummaryModel(
        weeklyFocus: weeklyFocus,
        weeklyFocusMinutes: weeklyFocusMinutes,
        weeklyPomodoroCount: weeklyPomodoroCount,
        todayFocusMinutes: todayStat.focusMinutes,
        todayPomodoroCount: todayStat.completedPomodoros,
        totalPoints: totalPoints,
        totalTasks: totalTasks,
        completedTasks: completedTasks,
        priorityStats: priorityStats,
        insight: insight,
        currentStreak: currentStreak,
      );

      _emit(
        _state.copyWith(isLoading: false, summary: summary, errorMessage: null),
      );
    } catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  String _buildInsight({
    required List<DailyFocusStat> weeklyFocus,
    required int completedTasks,
    required int totalTasks,
    required int todayPomodoroCount,
  }) {
    final bestDay = weeklyFocus.reduce(
      (a, b) => a.focusMinutes >= b.focusMinutes ? a : b,
    );

    if (weeklyFocus.every((stat) => stat.focusMinutes == 0)) {
      return 'Bu hafta henüz tamamlanmış odak oturumu yok. Bugün küçük bir hedefle başlayabilirsin.';
    }

    if (todayPomodoroCount == 0) {
      return 'Bugün henüz pomodoro tamamlamadın. 1 oturumla başlamak iyi olabilir.';
    }

    if (totalTasks > 0) {
      final rate = completedTasks / totalTasks;
      if (rate >= 0.7) {
        return 'Görevlerinin büyük kısmını tamamlamışsın. Bu tempo oldukça iyi görünüyor.';
      }
    }

    return 'Bu hafta en verimli günün ${_dayName(bestDay.date)}. O gün ${bestDay.focusMinutes} dakika odaklanmışsın.';
  }

  String _dayName(DateTime date) {
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];

    return days[date.weekday - 1];
  }

  int _calculateCurrentStreak(List<DailyFocusStat> weeklyFocus) {
    var streak = 0;

    for (final stat in weeklyFocus.reversed) {
      if (stat.focusMinutes > 0) {
        streak++;
      } else {
        if (streak > 0) break;
      }
    }
    
    return streak;
  }
}
