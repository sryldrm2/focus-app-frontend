import 'package:flutter/foundation.dart';
import 'package:focus_app/core/network/token_storage.dart';
import 'package:focus_app/features/pomodoro/models/pomodoro_model.dart';
import 'package:focus_app/features/pomodoro/network/pomodoro_service.dart';

// ── State ──────────────────────────────────────────────────
class PomodoroState {
  final PomodoroSessionModel? currentSession;
  final bool isLoading;
  final String? errorMessage;
  final int pointsEarned; // son oturumdan kazanılan puan
  final int completedTodayCount;
  final double totalPoints;

  const PomodoroState({
    this.currentSession,
    this.isLoading = false,
    this.errorMessage,
    this.pointsEarned = 0,
    this.completedTodayCount = 0,
    this.totalPoints = 0,
  });

  bool get hasOngoing => currentSession != null && currentSession!.isOngoing;

  PomodoroState copyWith({
    PomodoroSessionModel? currentSession,
    bool clearSession = false,
    bool? isLoading,
    String? errorMessage,
    int? pointsEarned,
    int? completedTodayCount,
    double? totalPoints,
  }) =>
      PomodoroState(
        currentSession: clearSession ? null : currentSession ?? this.currentSession,
        isLoading:           isLoading           ?? this.isLoading,
        errorMessage:        errorMessage,
        pointsEarned:        pointsEarned        ?? this.pointsEarned,
        completedTodayCount: completedTodayCount ?? this.completedTodayCount,
        totalPoints:         totalPoints         ?? this.totalPoints,
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
      if (session != null) {
        _emit(_state.copyWith(currentSession: session));
      }
    } catch (_) {}
  }

  // ─── Oturum başlat ────────────────────────────────────
  Future<bool> startSession(CreatePomodoroSessionDto dto) async {
    _emit(_state.copyWith(isLoading: true));
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Oturum bulunamadı.');
      final session = await _service.startSession(token, dto);
      _emit(_state.copyWith(currentSession: session, isLoading: false));
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
      _emit(_state.copyWith(clearSession: true));
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
    _emit(_state.copyWith(clearSession: true));
  }
 
  // ─── Hata mesajını temizle ────────────────────────────
  void clearError() {
    _emit(_state.copyWith(errorMessage: null));
  }
}