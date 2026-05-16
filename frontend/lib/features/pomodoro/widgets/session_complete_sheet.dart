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
    final isLongBreak = completedSessions % 4 == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tutamaç
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 32),

          // Kutlama İkon Alanı
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withOpacity(0.1),
                ),
              ),
              const Icon(
                Icons.celebration_rounded,
                size: 38,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Başlık
          Text(
            'Oturum Tamamlandı!',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.02,
            ),
          ),
          const SizedBox(height: 14),

          // Rozetler (Badges)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (task != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        task!.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                ),
              if (task != null) const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  '$completedSessions/4 oturum',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Reward Widget
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.xpColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.xpColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '+$pointsEarned XP Kazandın!',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Günlük hedefe yaklaştın',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Eylemler (Actions)
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    shadowColor: AppColors.success.withOpacity(0.25),
                  ),
                  onPressed: onStartBreak,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.coffee_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isLongBreak
                            ? 'Uzun Mola Başlat ($longBreakMinutes dk)'
                            : 'Mola Başlat ($breakMinutes dk)',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.textSecondary.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onSkipBreak,
                  child: Text(
                    'Molayı Geç',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}