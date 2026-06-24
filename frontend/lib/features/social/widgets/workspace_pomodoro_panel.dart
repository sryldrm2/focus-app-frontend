import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/pomodoro/models/pomodoro_model.dart';
import 'package:focus_app/features/pomodoro/network/pomodoro_service.dart';
import 'package:focus_app/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:focus_app/features/pomodoro/widgets/pomodoro_models.dart';
import 'package:focus_app/features/pomodoro/widgets/session_controls.dart';
import 'package:focus_app/features/social/notifiers/workspace_pomodoro_realtime_notifier.dart';
import 'package:focus_app/features/social/providers/workspace_provider.dart';
import 'package:focus_app/features/social/utils/workspace_realtime_sync.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';
import 'package:focus_app/features/tasks/notifiers/workspace_task_notifier.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oda içi pomodoro paneli.
///
/// Görev listesi [WorkspaceTaskNotifier.handleRealtimeTaskCreated] ile,
/// uzaktan başlatılan pomodoro ise [workspacePomodoroRealtimeProvider] ile senkronize edilir.
class WorkspacePomodoroPanel extends ConsumerStatefulWidget {
  final String workspaceId;
  final bool isRoomOwner;

  const WorkspacePomodoroPanel({
    super.key,
    required this.workspaceId,
    required this.isRoomOwner,
  });

  @override
  ConsumerState<WorkspacePomodoroPanel> createState() =>
      _WorkspacePomodoroPanelState();
}

class _WorkspacePomodoroPanelState extends ConsumerState<WorkspacePomodoroPanel> {
  int _workMinutes = 25;
  TimerStatus _status = TimerStatus.idle;
  int _secondsLeft = 25 * 60;
  Timer? _timer;
  bool _sessionReady = false;
  String? _syncedPomoId;

  int get _workDuration => _workMinutes * 60;

  String? get _activePomoId {
    final current = ref.read(pomodoroNotifierProvider).state.currentSession?.pomoId;
    return current ?? _syncedPomoId;
  }

  bool _matchesSyncedSession(String pomoId) {
    if (pomoId == _syncedPomoId) return true;
    return ref.read(pomodoroNotifierProvider).state.currentSession?.pomoId ==
        pomoId;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_initialize);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _workMinutes = prefs.getInt('work_minutes') ?? 25;

    await ref.read(pomodoroNotifierProvider).checkOngoing();
    if (!mounted) return;

    _syncFromGlobalSession();
    setState(() {
      _secondsLeft = _workDuration;
      _sessionReady = true;
    });
  }

  TaskModel? _activeTask(WorkspaceTaskState wsState) {
    final id = wsState.activeTaskId;
    if (id == null) return null;
    return wsState.tasks.where((t) => t.taskId == id).firstOrNull;
  }

  void _syncFromGlobalSession() {
    final pomState = ref.read(pomodoroNotifierProvider).state;
    final session = pomState.currentSession;
    if (session == null || !session.isOngoing) return;

    final wsState = ref.read(workspaceTaskStateProvider);
    final belongsToRoom = wsState.tasks.any((t) => t.taskId == session.taskId);
    if (!belongsToRoom) return;

    if (session.taskId != null) {
      ref.read(workspaceTaskNotifierProvider).setActiveTask(session.taskId!);
    }

    final remaining = pomState.localActivePomoId == session.pomoId &&
            pomState.localSecondsLeft != null
        ? pomState.localSecondsLeft!
        : session.remainingSeconds;

    _workMinutes = session.durationMinute;
    _secondsLeft = remaining > 0 ? remaining : _workDuration;
    _status = pomState.localTimerStatus == TimerStatus.paused
        ? TimerStatus.paused
        : TimerStatus.running;
    _syncedPomoId = session.pomoId;

    if (_status == TimerStatus.running) {
      _tick();
    }
  }

  void _syncFromRemoteSession(PomodoroSessionModel session) {
    if (!session.isOngoing) return;

    final wsState = ref.read(workspaceTaskStateProvider);
    final taskId = session.taskId;
    if (taskId == null) return;
    if (!wsState.tasks.any((t) => t.taskId == taskId)) return;

    final pomState = ref.read(pomodoroNotifierProvider).state;
    if (pomState.currentSession?.pomoId == session.pomoId &&
        (_status == TimerStatus.running || _status == TimerStatus.paused)) {
      return;
    }
    if (_syncedPomoId == session.pomoId &&
        (_status == TimerStatus.running || _status == TimerStatus.paused)) {
      return;
    }

    ref.read(workspaceTaskNotifierProvider).setActiveTask(taskId);

    _syncedPomoId = session.pomoId;
    _workMinutes = session.durationMinute;
    _secondsLeft = session.remainingSeconds;
    _status = TimerStatus.running;

    debugPrint(
      '[WorkspaceSync] panel timer started pomoId=${session.pomoId} '
      'secondsLeft=$_secondsLeft workMinutes=$_workMinutes',
    );

    ref.read(pomodoroNotifierProvider).setLocalTimer(
          TimerStatus.running,
          pomoId: session.pomoId,
          secondsLeft: _secondsLeft,
        );

    _tick();
    if (mounted) setState(() {});
  }

  void _syncFromRemotePause(String pomoId, int secondsLeft) {
    if (_syncedPomoId != null && !_matchesSyncedSession(pomoId)) return;
    if (_status == TimerStatus.paused &&
        _syncedPomoId == pomoId &&
        _secondsLeft == secondsLeft) {
      return;
    }

    _timer?.cancel();
    _syncedPomoId = pomoId;
    _secondsLeft = secondsLeft;
    _status = TimerStatus.paused;

    debugPrint(
      '[WorkspaceSync] panel paused pomoId=$pomoId secondsLeft=$secondsLeft',
    );

    _persistLocalTimer(TimerStatus.paused, secondsLeft: secondsLeft);
    if (mounted) setState(() {});
  }

  void _syncFromRemoteResume(String pomoId, int secondsLeft) {
    if (_syncedPomoId != null && !_matchesSyncedSession(pomoId)) return;
    if (_status == TimerStatus.running &&
        _syncedPomoId == pomoId &&
        _secondsLeft == secondsLeft) {
      return;
    }

    _syncedPomoId = pomoId;
    _secondsLeft = secondsLeft;
    _status = TimerStatus.running;

    debugPrint(
      '[WorkspaceSync] panel resumed pomoId=$pomoId secondsLeft=$secondsLeft',
    );

    _persistLocalTimer(TimerStatus.running, secondsLeft: secondsLeft);
    _tick();
    if (mounted) setState(() {});
  }

  void _syncFromRemoteCancel(String pomoId) {
    if (_syncedPomoId != null && !_matchesSyncedSession(pomoId)) return;
    if (_status == TimerStatus.idle) return;

    _timer?.cancel();
    _syncedPomoId = null;
    ref.read(pomodoroNotifierProvider).clearSession();

    debugPrint('[WorkspaceSync] panel cancelled pomoId=$pomoId');

    if (!mounted) return;
    setState(() {
      _status = TimerStatus.idle;
      _secondsLeft = _workDuration;
    });
  }

  void _persistLocalTimer(TimerStatus status, {int? secondsLeft}) {
    final pomState = ref.read(pomodoroNotifierProvider).state;
    final pomoId = pomState.currentSession?.pomoId ?? _syncedPomoId;
    ref.read(pomodoroNotifierProvider).setLocalTimer(
          status,
          pomoId: pomoId,
          secondsLeft: secondsLeft ?? _secondsLeft,
        );
  }

  Future<void> _start() async {
    if (!_sessionReady) return;

    if (!widget.isRoomOwner) {
      _showSnack(
        'Pomodoro\'yu yalnızca oda sahibi başlatabilir.',
        isError: true,
      );
      return;
    }

    final task = _activeTask(ref.read(workspaceTaskStateProvider));
    if (task == null || task.isCompleted) {
      _showSnack('Önce bir görev seçin.');
      return;
    }

    await ref.read(pomodoroNotifierProvider).checkOngoing();
    if (!mounted) return;

    final pomState = ref.read(pomodoroNotifierProvider).state;

    if (pomState.hasBlockingSession) {
      final sessionTaskId = pomState.currentSession?.taskId;
      if (sessionTaskId != null && sessionTaskId != task.taskId) {
        _showSnack(
          'Başka bir görev için devam eden pomodoro var.',
          isError: true,
        );
        return;
      }
      if (_status == TimerStatus.paused || pomState.localTimerStatus == TimerStatus.paused) {
        _resume();
        return;
      }
      if (_status == TimerStatus.running) return;
      _syncFromGlobalSession();
      return;
    }

    if (_status == TimerStatus.paused) {
      _resume();
      return;
    }

    final success = await ref.read(pomodoroNotifierProvider).startSession(
          CreatePomodoroSessionDto(
            sessionType: PomodoroType.workSession,
            durationMinute: _workMinutes,
            taskId: task.taskId,
          ),
        );

    if (!success) {
      final error = ref.read(pomodoroNotifierProvider).state.errorMessage;
      _showSnack(error ?? 'Oturum başlatılamadı.', isError: true);
      return;
    }

    _syncedPomoId =
        ref.read(pomodoroNotifierProvider).state.currentSession?.pomoId;

    setState(() {
      _status = TimerStatus.running;
      _secondsLeft = _workDuration;
    });
    _persistLocalTimer(TimerStatus.running, secondsLeft: _workDuration);
    _tick();
  }

  Future<void> _pause() async {
    final pomoId = _activePomoId;
    if (pomoId == null) return;

    _timer?.cancel();
    setState(() => _status = TimerStatus.paused);
    _persistLocalTimer(TimerStatus.paused, secondsLeft: _secondsLeft);

    final success = await ref
        .read(pomodoroNotifierProvider)
        .syncWorkspacePause(pomoId, _secondsLeft);
    if (!success && mounted) {
      final error = ref.read(pomodoroNotifierProvider).state.errorMessage;
      _showSnack(error ?? 'Duraklatma senkronize edilemedi.', isError: true);
    }
  }

  Future<void> _resume() async {
    final pomoId = _activePomoId;
    if (pomoId == null) return;

    final pomState = ref.read(pomodoroNotifierProvider).state;
    final session = pomState.currentSession;
    if (session != null && session.isOngoing) {
      _workMinutes = session.durationMinute;
      _secondsLeft = pomState.localSecondsLeft ?? session.remainingSeconds;
    }
    setState(() => _status = TimerStatus.running);
    _persistLocalTimer(TimerStatus.running, secondsLeft: _secondsLeft);
    _tick();

    final success = await ref
        .read(pomodoroNotifierProvider)
        .syncWorkspaceResume(pomoId, _secondsLeft);
    if (!success && mounted) {
      final error = ref.read(pomodoroNotifierProvider).state.errorMessage;
      _showSnack(error ?? 'Devam ettirme senkronize edilemedi.', isError: true);
    }
  }

  Future<void> _reset() async {
    final pomoId = _activePomoId;
    if (pomoId == null) return;

    _timer?.cancel();

    final success = await ref
        .read(pomodoroNotifierProvider)
        .syncWorkspaceCancel(pomoId);
    if (!success && mounted) {
      final error = ref.read(pomodoroNotifierProvider).state.errorMessage;
      _showSnack(error ?? 'Oturum iptal edilemedi.', isError: true);
      return;
    }

    _syncedPomoId = null;
    ref.read(workspacePomodoroRealtimeNotifierProvider).clear();

    if (!mounted) return;
    setState(() {
      _status = TimerStatus.idle;
      _secondsLeft = _workDuration;
    });
  }

  Future<void> _completeEarly() async {
    _timer?.cancel();
    await _onWorkComplete();
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

  Future<void> _onWorkComplete() async {
    final task = _activeTask(ref.read(workspaceTaskStateProvider));
    await ref.read(pomodoroNotifierProvider).completeSession();
    ref.read(pomodoroNotifierProvider).clearSession();
    _syncedPomoId = null;
    ref.read(workspacePomodoroRealtimeNotifierProvider).clear();

    await ref
        .read(workspaceTaskNotifierProvider)
        .loadTasks(widget.workspaceId);

    if (!mounted) return;

    setState(() {
      _status = TimerStatus.idle;
      _secondsLeft = _workDuration;
    });

    if (task != null) {
      _showSnack('${task.title} için pomodoro tamamlandı! 🎉');
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  double get _progress {
    if (_workDuration == 0) return 0;
    return 1 - (_secondsLeft / _workDuration);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pomodoroNotifierProvider, (previous, next) {
      final session = next.state.currentSession;
      if (session == null || !session.isOngoing) return;
      if (_status == TimerStatus.idle) {
        _syncFromGlobalSession();
        if (mounted) setState(() {});
      }
    });

    ref.listen(workspacePomodoroRealtimeProvider, (previous, next) {
      if (next.workspaceId != widget.workspaceId) return;

      switch (next.action) {
        case WorkspacePomodoroRemoteAction.started:
          if (next.session != null) _syncFromRemoteSession(next.session!);
          break;
        case WorkspacePomodoroRemoteAction.paused:
          if (next.eventPomoId != null && next.secondsLeft != null) {
            _syncFromRemotePause(next.eventPomoId!, next.secondsLeft!);
          }
          break;
        case WorkspacePomodoroRemoteAction.resumed:
          if (next.eventPomoId != null && next.secondsLeft != null) {
            _syncFromRemoteResume(next.eventPomoId!, next.secondsLeft!);
          }
          break;
        case WorkspacePomodoroRemoteAction.cancelled:
          if (next.eventPomoId != null) {
            _syncFromRemoteCancel(next.eventPomoId!);
          }
          ref.read(workspacePomodoroRealtimeNotifierProvider).clear();
          break;
        case null:
          break;
      }
    });

    ref.listen(workspaceTaskStateProvider, (previous, next) {
      if (next.workspaceId != widget.workspaceId) return;
      applyPendingWorkspacePomodoro(ref);
    });

    final wsState = ref.watch(workspaceTaskStateProvider);
    final activeTask = _activeTask(wsState);
    final isTimerActive =
        _status == TimerStatus.running || _status == TimerStatus.paused;

    if (!_sessionReady) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🍅 Oda Pomodoro',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (isTimerActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _status == TimerStatus.paused ? 'Duraklatıldı' : 'Odaklanıyor',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (activeTask == null)
            Text(
              'Aktif görev yok. Listeden bir görev seçin veya yeni görev ekleyin.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeTask.color,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeTask.title,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 7,
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(_secondsLeft),
                          style: GoogleFonts.nunito(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          '$_workMinutes dk odak',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!widget.isRoomOwner && _status == TimerStatus.idle)
              Text(
                'Pomodoro\'yu oda sahibi başlatır. Başladığında burada senkronize görünür.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              SessionControls(
                status: _status,
                onStart: _start,
                onPause: _pause,
                onResume: _resume,
                onReset: _reset,
                onSkip: _completeEarly,
              ),
          ],
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
