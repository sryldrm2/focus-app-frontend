import 'package:flutter/material.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';
import 'package:google_fonts/google_fonts.dart';

class SessionCompleteSheet extends StatelessWidget {
  final TaskModel? task;
  final int completedSessions;
  final int breakMinutes;
  final int longBreakMinutes;
  final int pointsEarned;
  final VoidCallback onStartBreak;
  final VoidCallback onSkipBreak;

  const SessionCompleteSheet({
    super.key,
    required this.task,
    required this.completedSessions,
    required this.breakMinutes,
    required this.longBreakMinutes,
    required this.pointsEarned,
    required this.onStartBreak,
    required this.onSkipBreak,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLongBreak = completedSessions % 4 == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tutamaç
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // Emoji + konfeti hissi
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withOpacity(0.1),
                ),
              ),
              const Text('🎉', style: TextStyle(fontSize: 48)),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            'Oturum Tamamlandı!',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Task ve oturum bilgisi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (task != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: task!.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task!.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task!.title, 
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: task!.color,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  ],
                ),
              ),
              if (task != null) const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedSessions/4 oturum',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            isLongBreak
                ? '4 oturum tamamladın! Uzun mola hak ettin 🌟'
                : 'Harika iş! Kısa bir mola ver.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // XP kazanıldı
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  '+$pointsEarned XP kazandın!',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Mola başlat butonu
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: onStartBreak,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('☕', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    isLongBreak 
                      ? 'Uzun Mola Başlat ($longBreakMinutes dk)' 
                      : 'Mola Başlat ($breakMinutes dk)',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Molayi geç
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onSkipBreak,
              child: Text(
                'Molayı Geç',
                style: GoogleFonts.dmSans(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
