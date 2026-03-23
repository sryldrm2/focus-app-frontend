import 'package:flutter/material.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/pomodoro/widgets/pomodoro_models.dart';
import 'package:google_fonts/google_fonts.dart';

class SessionCompleteSheet extends StatelessWidget {
  final Subject subject;
  final int completedSessions;
  final int breakMinutes;
  final int longBreakMinutes;
  final VoidCallback onStartBreak;
  final VoidCallback onSkipBreak;

  const SessionCompleteSheet({
    super.key,
    required this.subject,
    required this.completedSessions,
    required this.breakMinutes,
    required this.longBreakMinutes,
    required this.onStartBreak,
    required this.onSkipBreak,
  });

  @override
  Widget build(BuildContext context) {
    final isLongBreak = completedSessions % 4 == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tutamaç
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
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
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Konu ve oturum bilgisi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: subject.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(subject.emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      subject.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: subject.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
              color: AppColors.textSecondary,
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
                  '+25 XP kazandın!',
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
                    isLongBreak ? 'Uzun Mola Başlat ($longBreakMinutes dk)' : 'Mola Başlat ($breakMinutes dk)',
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
                  color: AppColors.textSecondary,
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
