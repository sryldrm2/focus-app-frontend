import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/pomodoro/widgets/settings_sheet.dart';
import 'package:focus_app/features/pomodoro/widgets/timer_display.dart';
import 'package:focus_app/features/pomodoro/widgets/subject_selector.dart';
import 'package:focus_app/features/pomodoro/widgets/session_controls.dart';
import 'package:focus_app/features/pomodoro/widgets/break_overlay.dart';
import 'package:focus_app/features/pomodoro/widgets/session_complete_sheet.dart';
import 'package:focus_app/features/pomodoro/widgets/pomodoro_models.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── AppBar ───────────────────────────────────────────────
class _PomodoroAppBar extends StatelessWidget {
  final int completedSessions;
  final TimerStatus status;
  final VoidCallback onSettings;

  const _PomodoroAppBar({
    required this.completedSessions,
    required this.status,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pomodoro',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                ),
              ),
              Text(
                _statusText(),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Tamamlanan oturum sayısı
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: status == TimerStatus.idle ? onSettings : null,
            child: Icon(
              Icons.settings_outlined,
              color: status == TimerStatus.idle
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withOpacity(0.3),
              size: 22,
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

// ── Ana ekran ────────────────────────────────────────────
class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

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

  // State
  TimerStatus _status = TimerStatus.idle;
  int _secondsLeft = 25 * 60;
  int _completedSessions = 0;
  Subject? _selectedSubject;
  Timer? _timer;

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
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workMinutes = prefs.getInt('work_minutes') ?? 25;
      _breakMinutes = prefs.getInt('break_minutes') ?? 5;
      _longBreakMinutes = prefs.getInt('long_break_minutes') ?? 15;
      _secondsLeft = workDuration;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Timer kontrolleri ──────────────────────────────────
  void _start() {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen önce bir ders seç 📚'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    setState(() => _status = TimerStatus.running);
    _tick();
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _status = TimerStatus.paused);
  }

  void _resume() {
    setState(() => _status = TimerStatus.running);
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

  void _reset() {
    _timer?.cancel();
    setState(() {
      _status = TimerStatus.idle;
      _secondsLeft = workDuration;
    });
  }

  void _tick() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        _onWorkComplete();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  void _onWorkComplete() {
    setState(() {
      _completedSessions++;
      _status = TimerStatus.completed;
    });
    _showCompleteSheet();
  }

  void _showCompleteSheet() {
    if (_selectedSubject == null) return;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SessionCompleteSheet(
        subject: _selectedSubject!,
        completedSessions: _completedSessions,
        breakMinutes: _breakMinutes,
        longBreakMinutes: _longBreakMinutes,
        onStartBreak: _startBreak,
        onSkipBreak: () {
          if (Navigator.canPop(context)) Navigator.pop(context);
          setState(() {
            _status = TimerStatus.idle;
            _secondsLeft = workDuration;
          });
        },
      ),
    );
  }

  void _startBreak() {
    if (Navigator.canPop(context)) Navigator.pop(context);
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

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SettingsSheet(
        workMinutes: _workMinutes,
        breakMinutes: _breakMinutes,
        longBreakMinutes: _longBreakMinutes,
        onSave: (work, breakMin, longBreakMin) {
          setState(() {
            _workMinutes = work;
            _breakMinutes = breakMin;
            _longBreakMinutes = longBreakMin;
            _secondsLeft = workDuration;
          });
        },
      ),
    );
  }

  // ── Progress hesaplama ─────────────────────────────────
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _PomodoroAppBar(
                  completedSessions: _completedSessions,
                  status: _status,
                  onSettings: _showSettingsSheet,
                ),
                const SizedBox(height: 32),
                SubjectSelector(
                  subjects: mockSubjects,
                  selected: _selectedSubject,
                  onSelect: (s) => setState(() => _selectedSubject = s),
                  enabled: _status == TimerStatus.idle,
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
                        subject: _selectedSubject,
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

          // Mola overlay
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
