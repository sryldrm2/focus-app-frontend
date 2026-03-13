import 'package:flutter/material.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/shared/widgets/section_card.dart';
import 'package:google_fonts/google_fonts.dart';

class TodayPlanItem {
  final String subject;
  final Color color;
  final int plannedMinutes;
  final int actualMinutes;

  const TodayPlanItem({
    required this.subject,
    required this.color,
    required this.plannedMinutes,
    required this.actualMinutes,
  });

  double get progress => actualMinutes / plannedMinutes;
}



// ── Mock veriler ─────────────────────────────────────────
final _mockPlanItems = [
  TodayPlanItem(subject: 'Matematik', color: const Color(0xFFE74C3C), plannedMinutes: 60, actualMinutes: 45),
  TodayPlanItem(subject: 'Fizik', color: const Color(0xFF3498DB), plannedMinutes: 45, actualMinutes: 20),
  TodayPlanItem(subject: 'İngilizce', color: const Color(0xFF2ECC71), plannedMinutes: 30, actualMinutes: 30),
];

class TodayPlanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Bugünkü Plan',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8EF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '%73 uyum',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._mockPlanItems.map((item) => PlanItemRow(item: item)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {},
            child: Text(
              'Planı Görüntüle →',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      )
    );
  }
}

class PlanItemRow extends StatelessWidget {
  final TodayPlanItem item;
  const PlanItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.subject,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${item.actualMinutes}/${item.plannedMinutes} dk',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    backgroundColor: item.color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(item.color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            item.progress >= 1.0
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: item.progress >= 1.0 ? AppColors.success : Colors.grey.shade300,
            size: 18,
          ),
        ],
      ),
    );
  }
}