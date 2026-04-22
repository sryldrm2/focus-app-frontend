import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';

// ── Mock ders istatistikleri ─────────────────────────────
class SubjectStat {
  final String name;
  final String emoji;
  final Color color;
  final int totalMinutes;
  final int totalPomodoros;

  const SubjectStat({
    required this.name,
    required this.emoji,
    required this.color,
    required this.totalMinutes,
    required this.totalPomodoros,
  });
}

final mockSubjectStats = [
  SubjectStat(
    name: 'Matematik',
    emoji: '📐',
    color: Color(0xFFE74C3C),
    totalMinutes: 1250,
    totalPomodoros: 50,
  ),
  SubjectStat(
    name: 'Fizik',
    emoji: '⚡',
    color: Color(0xFF3498DB),
    totalMinutes: 875,
    totalPomodoros: 35,
  ),
  SubjectStat(
    name: 'İngilizce',
    emoji: '📖',
    color: Color(0xFF2ECC71),
    totalMinutes: 625,
    totalPomodoros: 25,
  ),
  SubjectStat(
    name: 'Kimya',
    emoji: '🧪',
    color: Color(0xFF9B59B6),
    totalMinutes: 500,
    totalPomodoros: 20,
  ),
];

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}dk';
    return '${h}sa ${m}dk';
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes = mockSubjectStats.fold(0, (sum, s) => sum + s.totalMinutes);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Text(
                'Çalışma İstatistikleri',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Toplam ${_formatMinutes(totalMinutes)}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ders bazlı istatistikler
          ...mockSubjectStats.map((s) {
            final progress = s.totalMinutes / totalMinutes;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(s.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        s.name,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${s.totalPomodoros} 🍅',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatMinutes(s.totalMinutes),
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: s.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: s.color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(s.color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Haftalık özet
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _WeeklyStat(label: 'Bu Hafta', value: '12 🍅'),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _WeeklyStat(label: 'Günlük Ort.', value: '4.2 🍅'),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _WeeklyStat(label: 'En İyi Gün', value: '8 🍅'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyStat extends StatelessWidget {
  final String label;
  final String value;

  const _WeeklyStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}