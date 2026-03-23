import 'package:flutter/material.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/shared/widgets/section_card.dart';
import 'package:focus_app/shared/widgets/subject_chip.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickStartCard extends StatelessWidget {
  final _subjects = const [
    {'name': 'Matematik', 'color': Color(0xFFE74C3C), 'emoji': '📐'},
    {'name': 'Fizik', 'color': Color(0xFF3498DB), 'emoji': '⚡'},
    {'name': 'İngilizce', 'color': Color(0xFF2ECC71), 'emoji': '📖'},
  ];

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Hızlı Başlat',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Adaptif öneri chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('🤖', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      '20 dk önerildi',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: const Color(0xFF9B59B6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Konu chip'leri
          Row(
            children: _subjects.map((s) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SubjectChip(
                  name: s['name'] as String,
                  color: s['color'] as Color,
                  emoji: s['emoji'] as String,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Başlat butonu
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: AppColors.primary.withOpacity(0.3),
              ),
              onPressed: () => context.go('/pomodoro'),
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
              label: Text(
                'Başlat',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

