import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/social/widgets/friend_card.dart';
import 'package:focus_app/features/social/widgets/friend_request_card.dart';
import 'package:focus_app/features/social/widgets/add_friend_sheet.dart';

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  // Mock state — backend gelince burası değişecek
  List<Friend> _friends = List.from(mockFriends);
  List<FriendRequest> _requests = List.from(mockFriendRequests);

  void _acceptRequest(FriendRequest request) {
    setState(() {
      _requests.remove(request);
      _friends.add(Friend(
        id: request.id,
        displayName: request.displayName,
        username: request.username,
        avatarEmoji: request.avatarEmoji,
        isOnline: false,
        streak: 0,
        totalPomodoros: 0,
      ));
    });
  }

  void _rejectRequest(FriendRequest request) {
    setState(() => _requests.remove(request));
  }

  void _showAddFriendSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddFriendSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // ── Arkadaş Ekle Butonu ──────────────────
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

              // ── Gelen İstekler ───────────────────────
              if (_requests.isNotEmpty) ...[
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
                        '${_requests.length}',
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
                ..._requests.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FriendRequestCard(
                    request: r,
                    onAccept: () => _acceptRequest(r),
                    onReject: () => _rejectRequest(r),
                  ),
                )),
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
                    '${_friends.length}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_friends.isEmpty)
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
                ..._friends.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FriendCard(friend: f),
                )),
            ]),
          ),
        ),
      ],
    );
  }
}