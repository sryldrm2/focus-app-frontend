import 'package:flutter/foundation.dart';
import 'package:focus_app/core/network/token_storage.dart';
import 'package:focus_app/features/pomodoro/models/pomodoro_model.dart';
import 'package:focus_app/features/pomodoro/network/pomodoro_service.dart';
import 'package:focus_app/features/pomodoro/widgets/pomodoro_models.dart';

// ── State ──────────────────────────────────────────────────
class PomodoroState {
  final PomodoroSessionModel? currentSession;
  final TimerStatus localTimerStatus;
  final String? localActivePomoId;
  final int? localSecondsLeft;
  final bool isLoading;
  final String? errorMessage;
  final int pointsEarned; // son oturumdan kazanılan puan
  final int completedTodayCount;
  final double totalPoints;

  const PomodoroState({
    this.currentSession,
    this.localTimerStatus = TimerStatus.idle,
    this.localActivePomoId,
    this.localSecondsLeft,
    this.isLoading = false,
    this.errorMessage,
    this.pointsEarned = 0,
    this.completedTodayCount = 0,
    this.totalPoints = 0,
  });

  bool get hasOngoing => currentSession != null && currentSession!.isOngoing;

  bool get hasLocalActiveTimer =>
      localTimerStatus == TimerStatus.running ||
      localTimerStatus == TimerStatus.paused;

  bool get hasBlockingSession => hasOngoing || hasLocalActiveTimer;

  PomodoroState copyWith({
    PomodoroSessionModel? currentSession,
    bool clearSession = false,
    TimerStatus? localTimerStatus,
    String? localActivePomoId,
    int? localSecondsLeft,
    bool clearLocalTimer = false,
    bool? isLoading,
    String? errorMessage,
    int? pointsEarned,
    int? completedTodayCount,
    double? totalPoints,
  }) =>
      PomodoroState(
        currentSession: clearSession ? null : currentSession ?? this.currentSession,
        localTimerStatus: clearLocalTimer
            ? TimerStatus.idle
            : localTimerStatus ?? this.localTimerStatus,
        localActivePomoId: clearLocalTimer
            ? null
            : localActivePomoId ?? this.localActivePomoId,
        localSecondsLeft:
            clearLocalTimer ? null : localSecondsLeft ?? this.localSecondsLeft,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        pointsEarned: pointsEarned ?? this.pointsEarned,
        completedTodayCount: completedTodayCount ?? this.completedTodayCount,
        totalPoints: totalPoints ?? this.totalPoints,
      );
}

// ── Notifier ───────────────────────────────────────────────
class PomodoroNotifier extends ChangeNotifier {
  final _service = PomodoroService();

  PomodoroState _state = const PomodoroState();
  PomodoroState get state => _state;

  void _emit(PomodoroState s) {
    _state = s;
    notifyListeners();
  }

  // ─── Bugünkü istatistikleri yükle ────────────────────
  Future<void> loadTodayStats() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      final today = DateTime.now();
      final results = await Future.wait([
        _service.getCompleted(token),
        _service.getTotalPoints(token),
      ]);

      final completed = results[0] as List<dynamic>;
      final points = results[1] as double;

      // Bugün tamamlananları filtrele
      final todayCompleted = (completed as List).where((s) {
        if (s.completedAt == null) return false;
        final d = s.completedAt!.toLocal();
        return d.year == today.year &&
            d.month == today.month &&
            d.day == today.day;
      }).length;

      _emit(_state.copyWith(
        completedTodayCount: todayCompleted,
        totalPoints: points,
      ));
    } catch (_) {}
  }

  // ─── Uygulama açılınca ongoing session var mı? ────────
  Future<void> checkOngoing() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;
      final session = await _service.getOngoing(token);
      if (session != null && session.isOngoing) {
        _emit(_state.copyWith(currentSession: session, errorMessage: null));
      } else if (!_state.hasLocalActiveTimer) {
        _emit(_state.copyWith(clearSession: true, errorMessage: null));
      }
    } catch (_) {}
  }

  void setLocalTimer(
    TimerStatus status, {
    String? pomoId,
    int? secondsLeft,
  }) {
    _emit(_state.copyWith(
      localTimerStatus: status,
      localActivePomoId: pomoId,
      localSecondsLeft: secondsLeft ?? _state.localSecondsLeft,
    ));
  }

  void clearLocalTimer() {
    _emit(_state.copyWith(clearLocalTimer: true));
  }

  bool conflictsWithTask(String? taskId) {
    if (!_state.hasBlockingSession) return false;
    final sessionTaskId = _state.currentSession?.taskId;
    if (sessionTaskId != null) return taskId != sessionTaskId;
    return taskId != null;
  }

  // ─── Oturum başlat ────────────────────────────────────
  Future<bool> startSession(CreatePomodoroSessionDto dto) async {
    await checkOngoing();
    if (_state.hasBlockingSession) {
      _emit(_state.copyWith(
        errorMessage:
            'Devam eden bir pomodoro var. Önce onu tamamlayın veya iptal edin.',
      ));
      return false;
    }

    _emit(_state.copyWith(isLoading: true));
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Oturum bulunamadı.');
      final session = await _service.startSession(token, dto);
      _emit(_state.copyWith(
        currentSession: session,
        isLoading: false,
        localTimerStatus: TimerStatus.running,
        localActivePomoId: session.pomoId,
        localSecondsLeft: session.durationMinute * 60,
      ));
      return true;
    } catch (e) {
      _emit(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception', ''),
      ));
      return false;
    }
  }

  // ─── Oturumu tamamla ──────────────────────────────────
  Future<bool> completeSession() async {
    final pomoId = _state.currentSession?.pomoId;
    if (pomoId == null) return false;
 
    _emit(_state.copyWith(isLoading: true));
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Oturum bulunamadı.');
      final completed = await _service.completeSession(token, pomoId);
      _emit(_state.copyWith(
        currentSession: completed,
        isLoading: false,
        pointsEarned: completed.pointsEarned,
        completedTodayCount: _state.completedTodayCount + 1,
        totalPoints: _state.totalPoints + completed.pointsEarned,
      ));
      return true;
    } catch (e) {
      _emit(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
      return false;
    }
  }

  // ─── Oturumu iptal et ─────────────────────────────────
  Future<void> cancelSession() async {
    final pomoId = _state.currentSession?.pomoId;
    if (pomoId == null) return;
 
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;
      await _service.cancelSession(token, pomoId);
      _emit(_state.copyWith(clearSession: true, clearLocalTimer: true));
    } catch (e) {
      _emit(_state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  // ─── Mola (break count artır) ─────────────────────────
  Future<void> addBreak() async {
    final pomoId = _state.currentSession?.pomoId;
    if (pomoId == null) return;
 
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;
      await _service.addBreak(token, pomoId);
    } catch (_) {}
  }

  // ─── Session bitti, state'i temizle ───────────────────
  void clearSession() {
    _emit(_state.copyWith(clearSession: true, clearLocalTimer: true));
  }
 
  // ─── Hata mesajını temizle ────────────────────────────
  void clearError() {
    _emit(_state.copyWith(errorMessage: null));
  }
}