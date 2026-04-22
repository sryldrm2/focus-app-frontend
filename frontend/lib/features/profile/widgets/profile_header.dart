import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';

// ── Mock kullanıcı modeli ────────────────────────────────
class UserProfile {
  final String displayName;
  final String username;
  final String avatarEmoji;
  final int level;
  final int currentXp;
  final int nextLevelXp;
  final int streak;
  final int totalPomodoros;
  final int totalMinutes;
  final int friendCount;

  const UserProfile({
    required this.displayName,
    required this.username,
    required this.avatarEmoji,
    required this.level,
    required this.currentXp,
    required this.nextLevelXp,
    required this.streak,
    required this.totalPomodoros,
    required this.totalMinutes,
    required this.friendCount,
  });
}

final mockUserProfile = UserProfile(
  displayName: 'Esra Yılmaz',
  username: 'esrayilmaz',
  avatarEmoji: '🦋',
  level: 12,
  currentXp: 340,
  nextLevelXp: 500,
  streak: 7,
  totalPomodoros: 248,
  totalMinutes: 6200,
  friendCount: 14,
);

// ── ProfileHeader widget ─────────────────────────────────
class ProfileHeader extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onEditTap;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final xpProgress = user.currentXp / user.nextLevelXp;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profil',
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: onEditTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),

          // ── Avatar ──────────────────────────────────
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Text(
                    user.avatarEmoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  'Lv.${user.level}',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── İsim ve kullanıcı adı ────────────────────
          Text(
            user.displayName,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '@${user.username}',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),

          // ── XP Bar ──────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '⭐ ${user.currentXp} XP',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${user.nextLevelXp} XP → Lv.${user.level + 1}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: xpProgress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Hızlı istatistikler ──────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickStat(
                emoji: '🔥',
                value: '${user.streak}',
                label: 'Gün Serisi',
              ),
              _Divider(),
              _QuickStat(
                emoji: '🍅',
                value: '${user.totalPomodoros}',
                label: 'Pomodoro',
              ),
              _Divider(),
              _QuickStat(
                emoji: '👥',
                value: '${user.friendCount}',
                label: 'Arkadaş',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _QuickStat({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.3),
    );
  }
}
