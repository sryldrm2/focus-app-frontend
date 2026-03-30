import 'package:flutter/material.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/features/pomodoro/widgets/pomodoro_models.dart';

class TimerDisplay extends StatelessWidget {
  final int secondsLeft;
  final double progress;
  final Color color;
  final TimerStatus status;
  final Subject? subject;

  const TimerDisplay({
    super.key,
    required this.secondsLeft,
    required this.progress,
    required this.color,
    required this.status,
    required this.subject,
  });

  String get _timeText {
    final m = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
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
              color: Colors.white,
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
              else if (subject != null)
                Text(subject!.emoji, style: const TextStyle(fontSize: 28))
              else
                const Text('🍅', style: TextStyle(fontSize: 28)),

              const SizedBox(height: 8),

              // Zaman
              Text(
                _timeText,
                style: GoogleFonts.nunito(
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
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
                            : subject?.name ?? 'Odaklan',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}