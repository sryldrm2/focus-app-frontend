import 'package:flutter/material.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/pomodoro/widgets/pomodoro_models.dart';

class SessionControls extends StatelessWidget {
  final TimerStatus status;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;
  final VoidCallback onSkip;

  const SessionControls({
    super.key,
    required this.status,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Sıfırla / Geç butonu ─────────────────────
          if (status != TimerStatus.idle) ...[
            _CircleButton(
              icon: status == TimerStatus.breakTime
                  ? Icons.skip_next_rounded
                  : Icons.refresh_rounded,
              color: colorScheme.surfaceContainerHighest,
              iconColor: colorScheme.onSurfaceVariant,
              size: 52,
              onTap: status == TimerStatus.breakTime ? onSkip : onReset,
            ),
            const SizedBox(width: 20),
          ],
          // ── Ana buton (Başlat / Duraklat / Devam) ───
          _MainButton(status: status, onStart: onStart, onPause: onPause, onResume: onResume),
          // ── Geç butonu (çalışırken) ──────────────────
          if (status == TimerStatus.running || status == TimerStatus.paused) ...[
            const SizedBox(width: 20),
            _CircleButton(
              icon: Icons.skip_next_rounded,
              color: colorScheme.surfaceContainerHighest,
              iconColor: colorScheme.onSurfaceVariant,
              size: 52,
              onTap: onSkip,
            ),
          ] else if (status == TimerStatus.idle) ...[
            const SizedBox(width: 0),
          ],
        ],
      ),
    );
  }
}

// ── Ana buton ────────────────────────────────────────────
class _MainButton extends StatelessWidget {
  final TimerStatus status;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _MainButton({
    required this.status,
    required this.onStart,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRunning = status == TimerStatus.running;
    final isIdle = status == TimerStatus.idle;

    return GestureDetector(
      onTap: isRunning ? onPause : isIdle ? onStart : onResume,
      child: AnimatedContainer(
        duration: const Duration(microseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRunning ? colorScheme.surface : AppColors.primary,
          border: isRunning
              ? Border.all(color: AppColors.primary, width: 2.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(isRunning ? 0.1 : 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: isRunning ? AppColors.primary : colorScheme.onPrimary,
          size: 36,
        ),
      ),
    );
  }
}

// ── Yuvarlak küçük buton ─────────────────────────────────
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final double size;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: Icon(icon, color: iconColor, size: size * 0.45),
      ),
    );
  }
}