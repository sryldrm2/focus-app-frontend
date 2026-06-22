import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/pomodoro/models/pomodoro_model.dart';
import 'package:focus_app/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:focus_app/features/pomodoro/notifiers/pomodoro_notifier.dart';
import 'package:focus_app/features/pomodoro/network/pomodoro_service.dart';
import 'package:focus_app/features/pomodoro/widgets/duration_settings_bar.dart';
import 'package:focus_app/features/pomodoro/widgets/timer_display.dart';
import 'package:focus_app/features/pomodoro/widgets/task_selector.dart';
import 'package:focus_app/features/pomodoro/widgets/session_controls.dart';
import 'package:focus_app/features/pomodoro/widgets/break_overlay.dart';
import 'package:focus_app/features/pomodoro/widgets/session_complete_sheet.dart';
import 'package:focus_app/features/pomodoro/widgets/pomodoro_models.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';
import 'package:focus_app/features/tasks/providers/task_provider.dart';
import 'package:focus_app/features/social/providers/workspace_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── AppBar ────────────────────────────────────────────────
class _PomodoroAppBar extends StatelessWidget {
  final int completedSessions;
  final TimerStatus status;

  const _PomodoroAppBar({
    required this.completedSessions,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pomodoro',
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                _statusText(),
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: List.generate(4, (i) {
              return Container(
                margin: const EdgeInsets.only(left: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < completedSessions
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.15),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            '$completedSessions/4',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _statusText() {
    switch (status) {
      case TimerStatus.idle:
        return 'Başlamaya hazır';
      case TimerStatus.running:
        return 'Odaklanma zamanı 🎯';
      case TimerStatus.paused:
        return 'Duraklatıldı';
      case TimerStatus.breakTime:
        return 'Mola zamanı ☕';
      case TimerStatus.completed:
        return 'Oturum tamamlandı!';
    }
  }
}

// ── Ana ekran ─────────────────────────────────────────────
class PomodoroScreen extends ConsumerStatefulWidget {
  final String? initialTaskId; // dashboard'dan gelince dolu olur

  const PomodoroScreen({super.key, this.initialTaskId});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen>
    with TickerProviderStateMixin {
  // Timer ayarları
  int _workMinutes = 25;
  int _breakMinutes = 5;
  int _longBreakMinutes = 15;

  int get workDuration => _workMinutes * 60;
  int get breakDuration => _breakMinutes * 60;
  int get longBreakDuration => _longBreakMinutes * 60;

  // UI State
  TimerStatus _status = TimerStatus.idle;
  int _secondsLeft = 25 * 60;
  int _completedSessions = 0;
  TaskModel? _selectedTask;
  String? _activePomoId;
  Timer? _timer;
  bool _sessionReady = false;

  // Animasyon
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.microtask(_initializeSession);
  }

  Future<void> _initializeSession() async {
    await _loadSettings();
    await ref.read(pomodoroNotifierProvider).checkOngoing();
    if (!mounted) return;

    final pomState = ref.read(pomodoroNotifierProvider).state;

    if (pomState.hasOngoing) {
      _syncOngoingSessionToUi();
      if (widget.initialTaskId != null &&
          pomState.currentSession?.taskId != widget.initialTaskId) {
        _showOngoingConflictSnackBar();
      }
      setState(() => _sessionReady = true);
      return;
    }

    if (pomState.hasLocalActiveTimer) {
      _restoreLocalTimerFromNotifier();
      if (widget.initialTaskId != null) {
        _showOngoingConflictSnackBar();
      }
      setState(() => _sessionReady = true);
      return;
    }

    if (widget.initialTaskId != null) {
      final tasks = ref.read(taskNotifierProvider).state.todayTasks;
      final task = tasks
          .where((t) => t.taskId == widget.initialTaskId)
          .firstOrNull;
      if (task != null) setState(() => _selectedTask = task);
    }

    setState(() {
      _secondsLeft = workDuration;
      _sessionReady = true;
    });
  }

  void _restoreLocalTimerFromNotifier() {
    final pomState = ref.read(pomodoroNotifierProvider).state;
    final session = pomState.currentSession;

    setState(() {
      _status = pomState.localTimerStatus;
      _activePomoId = pomState.localActivePomoId;
      if (session != null) {
        _selectedTask = _findTaskForSession(session);
        _workMinutes = session.durationMinute;
        _secondsLeft = _resolveSecondsLeft(session, pomState);
      } else if (pomState.localSecondsLeft != null) {
        _secondsLeft = pomState.localSecondsLeft!;
      }
    });

    if (_status == TimerStatus.running) {
      _tick();
    }
  }

  int _resolveSecondsLeft(
    PomodoroSessionModel session,
    PomodoroState pomState,
  ) {
    if (pomState.localActivePomoId == session.pomoId &&
        pomState.localSecondsLeft != null) {
      return pomState.localSecondsLeft!;
    }
    return session.remainingSeconds;
  }

  void _persistLocalTimer(
    TimerStatus status, {
    String? pomoId,
    int? secondsLeft,
  }) {
    ref.read(pomodoroNotifierProvider).setLocalTimer(
          status,
          pomoId: pomoId ?? _activePomoId,
          secondsLeft: secondsLeft ?? _secondsLeft,
        );
  }

  void _showOngoingConflictSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Devam eden bir pomodoro var. Önce onu tamamlayın veya iptal edin.',
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool _isDifferentTaskThanSession(PomodoroSessionModel session) {
    if (session.taskId == null) return _selectedTask != null;
    return _selectedTask?.taskId != session.taskId;
  }

  TaskModel? _findTaskForSession(PomodoroSessionModel session) {
    if (session.taskId == null) return null;
    final tasks = ref.read(taskNotifierProvider).state.todayTasks;
    return tasks.where((t) => t.taskId == session.taskId).firstOrNull;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _workMinutes = prefs.getInt('work_minutes') ?? 25;
      _breakMinutes = prefs.getInt('break_minutes') ?? 5;
      _longBreakMinutes = prefs.getInt('long_break_minutes') ?? 15;
    });
  }

  Future<void> _saveDurationSettings(int work, int breakMin, int longBreak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('work_minutes', work);
    await prefs.setInt('break_minutes', breakMin);
    await prefs.setInt('long_break_minutes', longBreak);
  }

  void _onDurationChanged(int work, int breakMin, int longBreak) {
    if (_status != TimerStatus.idle) return;

    setState(() {
      _workMinutes = work;
      _breakMinutes = breakMin;
      _longBreakMinutes = longBreak;
      _secondsLeft = workDuration;
    });
    _saveDurationSettings(work, breakMin, longBreak);
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_status == TimerStatus.running || _status == TimerStatus.paused) {
      ref.read(pomodoroNotifierProvider).setLocalTimer(
            _status,
            pomoId: _activePomoId,
            secondsLeft: _secondsLeft,
          );
    }
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _syncOngoingSessionToUi() async {
    final pomState = ref.read(pomodoroNotifierProvider).state;
    final session = pomState.currentSession;
    if (session == null || !session.isOngoing) return;

    final remaining = _resolveSecondsLeft(session, pomState);

    if (remaining <= 0) {
      await _completeSessionAndRefreshTasks();
      ref.read(pomodoroNotifierProvider).clearLocalTimer();
      setState(() {
        _status = TimerStatus.idle;
        _secondsLeft = workDuration;
        _activePomoId = null;
      });
      return;
    }

    final preservePaused = pomState.localTimerStatus == TimerStatus.paused &&
        pomState.localActivePomoId == session.pomoId;

    setState(() {
      _activePomoId = session.pomoId;
      _selectedTask = _findTaskForSession(session);
      _workMinutes = session.durationMinute;
      _secondsLeft = remaining;
      _status = preservePaused ? TimerStatus.paused : TimerStatus.running;
    });

    _persistLocalTimer(_status, pomoId: session.pomoId, secondsLeft: remaining);

    if (!preservePaused) {
      _tick();
    }
  }

  // ── Timer kontrolleri ─────────────────────────────────
  Future<void> _start() async {
    if (!_sessionReady) return;

    await ref.read(pomodoroNotifierProvider).checkOngoing();
    if (!mounted) return;

    final pomState = ref.read(pomodoroNotifierProvider).state;
    final existingSession = pomState.currentSession;

    // Backend'de devam eden session varsa asla yeni session açma.
    if (existingSession != null && existingSession.isOngoing) {
      if (_isDifferentTaskThanSession(existingSession)) {
        _syncOngoingSessionToUi();
        _showOngoingConflictSnackBar();
        return;
      }

      if (_status == TimerStatus.paused ||
          pomState.localTimerStatus == TimerStatus.paused) {
        _resume();
        return;
      }

      if (_status == TimerStatus.running) return;

      _syncOngoingSessionToUi();
      return;
    }

    if (pomState.hasLocalActiveTimer) {
      _restoreLocalTimerFromNotifier();
      if (pomState.localTimerStatus == TimerStatus.paused) {
        _resume();
      }
      return;
    }

    if (_status == TimerStatus.paused || _status == TimerStatus.running) {
      _resume();
      return;
    }

    if (_selectedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen önce bir görev seç 📚'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Backend'e oturum başlat
    final success = await ref
        .read(pomodoroNotifierProvider)
        .startSession(
          CreatePomodoroSessionDto(
            sessionType: PomodoroType.workSession,
            durationMinute: _workMinutes,
            taskId: _selectedTask!.taskId,
          ),
        );

    if (!success) {
      final error = ref.read(pomodoroNotifierProvider).state.errorMessage;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Oturum başlatılamadı.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _activePomoId =
          ref.read(pomodoroNotifierProvider).state.currentSession?.pomoId;
      _status = TimerStatus.running;
      _secondsLeft = workDuration;
    });

    _persistLocalTimer(
      TimerStatus.running,
      pomoId: _activePomoId,
      secondsLeft: workDuration,
    );
    _tick();
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _status = TimerStatus.paused);
    _persistLocalTimer(TimerStatus.paused, secondsLeft: _secondsLeft);
    // Mola sayacı artır
    ref.read(pomodoroNotifierProvider).addBreak();
  }

  void _resume() {
    final pomState = ref.read(pomodoroNotifierProvider).state;
    final session = pomState.currentSession;
    if (session != null && session.isOngoing) {
      setState(() {
        _activePomoId = session.pomoId;
        _selectedTask = _findTaskForSession(session) ?? _selectedTask;
        _workMinutes = session.durationMinute;
        _secondsLeft = _resolveSecondsLeft(session, pomState);
      });
    }

    setState(() => _status = TimerStatus.running);
    _persistLocalTimer(TimerStatus.running, secondsLeft: _secondsLeft);
    _tick();
  }

  void _skip() {
    _timer?.cancel();
    if (_status == TimerStatus.breakTime) {
      setState(() {
        _status = TimerStatus.idle;
        _secondsLeft = workDuration;
      });
    } else {
      _onWorkComplete();
    }
  }

  Future<void> _reset() async {
    _timer?.cancel();
    // Backend'e iptal gönder
    await ref.read(pomodoroNotifierProvider).cancelSession();
    setState(() {
      _status = TimerStatus.idle;
      _secondsLeft = workDuration;
      _activePomoId = null;
    });
  }

  void _tick() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        _onWorkComplete();
        return;
      }
      setState(() => _secondsLeft--);
      if (_status == TimerStatus.running) {
        _persistLocalTimer(TimerStatus.running, secondsLeft: _secondsLeft);
      }
    });
  }

  Future<void> _completeSessionAndRefreshTasks() async {
    final taskId = _selectedTask?.taskId;
    final workspaceId = _selectedTask?.workspaceId;

    await ref.read(pomodoroNotifierProvider).completeSession();

    await ref.read(taskNotifierProvider).loadTasks();
    if (workspaceId != null && workspaceId.isNotEmpty) {
      await ref
          .read(workspaceTaskNotifierProvider)
          .loadTasks(workspaceId);
    }

    if (taskId != null && mounted) {
      final refreshed = ref.read(taskNotifierProvider).state.tasks
          .where((t) => t.taskId == taskId)
          .firstOrNull;
      if (refreshed != null) _selectedTask = refreshed;
    }
  }

  Future<void> _onWorkComplete() async {
    await _completeSessionAndRefreshTasks();

    if (!mounted) return;

    setState(() {
      _completedSessions++;
      _status = TimerStatus.completed;
    });
    _showCompleteSheet();
  }

  void _showCompleteSheet() {
    final pointsEarned = ref.read(pomodoroNotifierProvider).state.pointsEarned;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SessionCompleteSheet(
        task: _selectedTask,
        completedSessions: _completedSessions,
        breakMinutes: _breakMinutes,
        longBreakMinutes: _longBreakMinutes,
        pointsEarned: pointsEarned,
        onStartBreak: _startBreak,
        onSkipBreak: () {
          if (Navigator.canPop(context)) Navigator.pop(context);
          ref.read(pomodoroNotifierProvider).clearSession();
          setState(() {
            _status = TimerStatus.idle;
            _secondsLeft = workDuration;
            _activePomoId = null;
          });
        },
      ),
    );
  }

  void _startBreak() {
    if (Navigator.canPop(context)) Navigator.pop(context);
    ref.read(pomodoroNotifierProvider).clearSession();
    final isLongBreak = _completedSessions % 4 == 0;
    setState(() {
      _status = TimerStatus.breakTime;
      _secondsLeft = isLongBreak ? longBreakDuration : breakDuration;
    });
    _tick();
  }

  void _skipBreak() {
    _timer?.cancel();
    setState(() {
      _status = TimerStatus.idle;
      _secondsLeft = workDuration;
    });
  }

  double get _progress {
    final total = _status == TimerStatus.breakTime
        ? breakDuration
        : workDuration;
    return 1 - (_secondsLeft / total);
  }

  Color get _timerColor {
    if (_status == TimerStatus.breakTime) return AppColors.success;
    if (_secondsLeft < 60) return AppColors.error;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final todayTasks = ref.watch(taskNotifierProvider).state.todayTasks;
    final hasBlocking =
        ref.watch(pomodoroNotifierProvider).state.hasBlockingSession;
    final canSelectTask = _status == TimerStatus.idle && !hasBlocking;

    if (!_sessionReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _PomodoroAppBar(
                  completedSessions: _completedSessions,
                  status: _status,
                ),
                const SizedBox(height: 20),
                DurationSettingsBar(
                  workMinutes: _workMinutes,
                  breakMinutes: _breakMinutes,
                  longBreakMinutes: _longBreakMinutes,
                  enabled: _status == TimerStatus.idle && !hasBlocking,
                  onChanged: _onDurationChanged,
                ),
                const SizedBox(height: 20),
                TaskSelector(
                  tasks: todayTasks,
                  selected: _selectedTask,
                  onSelect: (t) => setState(() => _selectedTask = t),
                  enabled: canSelectTask,
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Center(
                    child: ScaleTransition(
                      scale: _status == TimerStatus.running
                          ? _pulseAnimation
                          : const AlwaysStoppedAnimation(1.0),
                      child: TimerDisplay(
                        secondsLeft: _secondsLeft,
                        progress: _progress,
                        color: _timerColor,
                        status: _status,
                        task: _selectedTask,
                      ),
                    ),
                  ),
                ),
                SessionControls(
                  status: _status,
                  onStart: _start,
                  onPause: _pause,
                  onResume: _resume,
                  onReset: _reset,
                  onSkip: _skip,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          if (_status == TimerStatus.breakTime)
            Positioned.fill(
              child: BreakOverlay(
                secondsLeft: _secondsLeft,
                progress: _progress,
                onSkip: _skipBreak,
              ),
            ),
        ],
      ),
    );
  }
}
