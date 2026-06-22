import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';

class Friend {
  final String id;
  final String displayName;
  final String username;
  final String avatarEmoji;
  final bool isOnline;
  final int streak;
  final int totalPomodoros;

    const Friend({
    required this.id,
    required this.displayName,
    required this.username,
    required this.avatarEmoji,
    required this.isOnline,
    required this.streak,
    required this.totalPomodoros,
  });
}

class FriendRequest {
  final String id;
  final String displayName;
  final String username;
  final String avatarEmoji;
  final String sentAt;

  const FriendRequest({
    required this.id,
    required this.displayName,
    required this.username,
    required this.avatarEmoji,
    required this.sentAt,
  });
}

final mockFriends = [
  Friend(
    id: '1',
    displayName: 'Ahmet Yılmaz',
    username: 'ahmetyilmaz',
    avatarEmoji: '🦊',
    isOnline: true,
    streak: 12,
    totalPomodoros: 248,
  ),
  Friend(
    id: '2',
    displayName: 'Zeynep Kaya',
    username: 'zeynepkaya',
    avatarEmoji: '🐻',
    isOnline: true,
    streak: 7,
    totalPomodoros: 156,
  ),
  Friend(
    id: '3',
    displayName: 'Mehmet Demir',
    username: 'mehmetdemir',
    avatarEmoji: '🐯',
    isOnline: false,
    streak: 3,
    totalPomodoros: 89,
  ),
  Friend(
    id: '4',
    displayName: 'Ayşe Çelik',
    username: 'aysecelik',
    avatarEmoji: '🦋',
    isOnline: false,
    streak: 21,
    totalPomodoros: 412,
  ),
];

final mockFriendRequests = [
  FriendRequest(
    id: '1',
    displayName: 'Can Öztürk',
    username: 'canozturk',
    avatarEmoji: '🦁',
    sentAt: '2 saat önce',
  ),
  FriendRequest(
    id: '2',
    displayName: 'Esra Yıldırım',
    username: 'esrayildirim',
    avatarEmoji: '🐼',
    sentAt: '1 gün önce',
  ),
];

class FriendCard extends StatelessWidget {
  final Friend friend;
  final VoidCallback? onTap;

  const FriendCard({
    super.key,
    required this.friend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      friend.avatarEmoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                // Online indicator
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: friend.isOnline
                          ? AppColors.success
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Bilgiler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '@${friend.username}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // İstatistikler
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 2),
                    Text(
                      '${friend.streak}',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text('🍅', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 2),
                    Text(
                      '${friend.totalPomodoros}',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
