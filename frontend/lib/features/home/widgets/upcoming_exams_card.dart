import 'package:flutter/material.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/shared/widgets/section_card.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Mock veri modelleri ──────────────────────────────────
class UpcomingExam {
  final String title;
  final String subject;
  final Color color;
  final int daysLeft;

  const UpcomingExam({
    required this.title,
    required this.subject,
    required this.color,
    required this.daysLeft,
  });
}

final _mockExams = [
  UpcomingExam(title: 'Matematik Sınavı', subject: 'Matematik', color: const Color(0xFFE74C3C), daysLeft: 3),
  UpcomingExam(title: 'Fizik Quiz', subject: 'Fizik', color: const Color(0xFF3498DB), daysLeft: 7),
];

class UpcomingExamsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Yaklaşan Sınavlar',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Tümünü Gör →',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._mockExams.map((exam) => _ExamRow(exam: exam)),
        ],
      ),
    );
  }
}

class _ExamRow extends StatelessWidget {
  final UpcomingExam exam;
  const _ExamRow({required this.exam});

  Color get _chipColor {
    if (exam.daysLeft <= 2) return AppColors.error;
    if (exam.daysLeft <= 5) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: exam.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.title,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  exam.subject,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _chipColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${exam.daysLeft} gün kaldı',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: _chipColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }
}