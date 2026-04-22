import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';

// ── Mock rozet modeli ────────────────────────────────────
class Badge {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final Color color;
  final bool isUnlocked;

  const Badge({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.color,
    required this.isUnlocked,
  });
}

final mockBadges = [
  Badge(
    id: '1',
    emoji: '🔥',
    name: 'Ateşli Başlangıç',
    description: '7 gün üst üste çalış',
    color: Color(0xFFE85D04),
    isUnlocked: true,
  ),
  Badge(
    id: '2',
    emoji: '🍅',
    name: 'Pomodoro Ustası',
    description: '100 pomodoro tamamla',
    color: Color(0xFFE74C3C),
    isUnlocked: true,
  ),
  Badge(
    id: '3',
    emoji: '⚡',
    name: 'Hız Rekoru',
    description: 'Günde 8 pomodoro tamamla',
    color: Color(0xFFF39C12),
    isUnlocked: true,
  ),
  Badge(
    id: '4',
    emoji: '🧠',
    name: 'Çok Yönlü',
    description: '5 farklı derste çalış',
    color: Color(0xFF9B59B6),
    isUnlocked: false,
  ),
  Badge(
    id: '5',
    emoji: '👥',
    name: 'Sosyal Kelebek',
    description: '10 arkadaş edin',
    color: Color(0xFF3498DB),
    isUnlocked: false,
  ),
  Badge(
    id: '6',
    emoji: '🏆',
    name: 'Şampiyon',
    description: 'Liderlik tablosunda 1. ol',
    color: Color(0xFFFFD700),
    isUnlocked: false,
  ),
];

class BadgesSection extends StatelessWidget {
  const BadgesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final unlockedCount = mockBadges.where((b) => b.isUnlocked).length;

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
          Row(
            children: [
              Text(
                'Rozetler',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.xpColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unlockedCount/${mockBadges.length}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.xpColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemCount: mockBadges.length,
            itemBuilder: (_, i) => _BadgeItem(badge: mockBadges[i]),
          ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final Badge badge;

  const _BadgeItem({required this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(badge.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  badge.name,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  badge.description,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!badge.isUnlocked) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '🔒 Henüz kazanılmadı',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: badge.isUnlocked
              ? badge.color.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: badge.isUnlocked
                ? badge.color.withOpacity(0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColorFiltered(
              colorFilter: badge.isUnlocked
                  ? const ColorFilter.mode(
                      Colors.transparent,
                      BlendMode.multiply,
                    )
                  : const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0,      0,      0,      1, 0,
                    ]),
              child: Text(
                badge.emoji,
                style: TextStyle(
                  fontSize: 28,
                  color: badge.isUnlocked ? null : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                badge.name,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: badge.isUnlocked
                      ? AppColors.textPrimary
                      : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!badge.isUnlocked)
              const Text('🔒', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}