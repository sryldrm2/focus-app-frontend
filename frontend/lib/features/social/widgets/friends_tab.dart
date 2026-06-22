import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/auth/providers/auth_providers.dart';
import 'package:focus_app/features/social/models/friend_models.dart';
import 'package:focus_app/features/social/providers/social_providers.dart';
import 'package:focus_app/features/social/widgets/add_friend_sheet.dart';
import 'package:focus_app/features/social/widgets/friend_card.dart';
import 'package:focus_app/features/social/widgets/friend_leaderboard_section.dart';
import 'package:focus_app/features/social/widgets/friend_request_card.dart';

class FriendsTab extends ConsumerStatefulWidget {
  const FriendsTab({super.key});

  @override
  ConsumerState<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<FriendsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(socialNotifierProvider);
      notifier.loadAll();
      notifier.loadLeaderboard();
    });
  }

  void _showAddFriendSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddFriendSheet(),
    );
  }

  /// Mevcut [FriendRequestCard] mock [FriendRequest] tipi beklediği için API modelini buna çeviriyoruz.
  FriendRequest _mapPendingToUi(FriendRequestModel r) {
    final c = r.consigner;
    final displayName = c == null
        ? r.consignerId
        : '${c.name} ${c.surname}'.trim().isEmpty
            ? c.nickname
            : '${c.name} ${c.surname}'.trim();
    final username = c?.nickname ?? r.consignerId;
    return FriendRequest(
      id: r.friendRequestId,
      displayName: displayName,
      username: username,
      avatarEmoji: '👤',
      sentAt: _formatRelative(r.createdAt),
    );
  }

  /// Gönderdiğim istekler: kartta alıcı (receiver) gösterilir.
  FriendRequest _mapSentToUi(FriendRequestModel r) {
    final recv = r.receiver;
    final displayName = recv == null
        ? r.receiverId
        : '${recv.name} ${recv.surname}'.trim().isEmpty
            ? recv.nickname
            : '${recv.name} ${recv.surname}'.trim();
    final username = recv?.nickname ?? r.receiverId;
    return FriendRequest(
      id: r.friendRequestId,
      displayName: displayName,
      username: username,
      avatarEmoji: '👤',
      sentAt: _formatRelative(r.createdAt),
    );
  }

  Friend _mapFriendshipToFriend(FriendshipModel f, String myUserId) {
    final other = f.otherUser(myUserId);
    final displayName = '${other.name} ${other.surname}'.trim().isEmpty
        ? other.nickname
        : '${other.name} ${other.surname}'.trim();
    return Friend(
      id: other.userId,
      displayName: displayName,
      username: other.nickname,
      avatarEmoji: '👤',
      isOnline: other.isOnline,
      streak: 0,
      totalPomodoros: other.totalPoints.round(),
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
    if (diff.inDays < 1) return '${diff.inHours} saat önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialStateProvider);
    final myUserId =
        ref.watch(authNotifierProvider).state.user?.userId ?? '';
    final notifier = ref.read(socialNotifierProvider);

    final pending = social.pendingRequests;
    final sent = social.sentRequests;
    final friends = social.myFriends
        .map((f) => _mapFriendshipToFriend(f, myUserId))
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await notifier.loadAll();
        await notifier.loadLeaderboard();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (social.errorMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      social.errorMessage!,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
                if (myUserId.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Arkadaş listesi için giriş yapman gerekir.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                if (social.isLoading) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],

                // ── Arkadaş Ekle ─────────────────────────
                GestureDetector(
                  onTap: _showAddFriendSheet,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Arkadaş Ekle',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                FriendLeaderboardSection(
                  entries: social.leaderboard,
                  isLoading: social.isLeaderboardLoading,
                  errorMessage: social.leaderboardError,
                  onRetry: () => notifier.loadLeaderboard(),
                ),
                const SizedBox(height: 20),

                // ── Gönderilen İstekler (bekleyen) ───────
                if (sent.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Gönderilen İstekler',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${sent.length}',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Karşı taraf kabul edene kadar burada görünür.',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...sent.map((r) {
                    final ui = _mapSentToUi(r);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.15),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(ui.avatarEmoji,
                                style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ui.displayName,
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '@${ui.username} · ${ui.sentAt}',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Bekliyor',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // ── Gelen İstekler ───────────────────────
                if (pending.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Gelen İstekler',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${pending.length}',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...pending.map((r) {
                    final ui = _mapPendingToUi(r);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FriendRequestCard(
                        request: ui,
                        onAccept: () => notifier.accept(r.friendRequestId),
                        onReject: () => notifier.reject(r.friendRequestId),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // ── Arkadaşlar ───────────────────────────
                Row(
                  children: [
                    Text(
                      'Arkadaşlar',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${friends.length}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (friends.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Text('👋', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'Henüz arkadaşın yok',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Arkadaş ekleyerek birlikte çalışabilirsin',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...friends.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FriendCard(friend: f),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
