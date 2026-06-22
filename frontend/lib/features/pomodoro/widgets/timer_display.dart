import 'package:flutter/material.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/pomodoro/widgets/pomodoro_models.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';
import 'package:google_fonts/google_fonts.dart';

class TimerDisplay extends StatelessWidget {
  final int secondsLeft;
  final double progress;
  final Color color;
  final TimerStatus status;
  final TaskModel? task;

  const TimerDisplay({
    super.key,
    required this.secondsLeft,
    required this.progress,
    required this.color,
    required this.status,
    required this.task,
  });

  String get _timeText {
    final m = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size.width * 0.72;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Arka plan daire ──────────────────────────
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),

          // ── Progress ring ────────────────────────────
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: color.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),

          // ── İçerik ──────────────────────────────────
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Durum ikonu
              if (status == TimerStatus.breakTime)
                const Text('☕', style: TextStyle(fontSize: 32))
              else if (task != null)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task!.color,
                  ),
                )
              else
                const Text('🍅', style: TextStyle(fontSize: 28)),

              const SizedBox(height: 8),

              // Zaman
              Text(
                _timeText,
                style: GoogleFonts.nunito(
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -2,
                ),
              ),

              const SizedBox(height: 6),

              // Alt etiket
              Text(
                status == TimerStatus.breakTime
                    ? 'Mola zamanı'
                    : status == TimerStatus.idle
                        ? 'Hazır'
                        : status == TimerStatus.paused
                            ? 'Duraklatıldı'
                            : task?.title ?? 'Odaklan',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}