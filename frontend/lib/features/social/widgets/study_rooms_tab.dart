import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/social/widgets/invite_friend_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/social/providers/social_providers.dart';
import 'package:focus_app/features/social/providers/workspace_provider.dart';
import 'package:focus_app/features/notifications/network/notification_hub_service.dart';
import 'package:focus_app/features/social/utils/open_create_room.dart';
import 'package:focus_app/features/social/widgets/study_room_card.dart';
import 'package:focus_app/features/social/screens/workspace_detail_screen.dart';

class StudyRoomsTab extends ConsumerStatefulWidget {
  const StudyRoomsTab({super.key});

  @override
  ConsumerState<StudyRoomsTab> createState() => _StudyRoomsTabState();
}

class _StudyRoomsTabState extends ConsumerState<StudyRoomsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workspaceNotifierProvider).init();
    });
  }

  void _showCreateRoomSheet() => showCreateRoomSheet(context);

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickFriendAndInvite(
    String workspaceId,
    String workspaceName,
  ) async {
    await ref.read(socialNotifierProvider).loadAll();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InviteFriendSheet(
        workspaceName: workspaceName,
        onInvite: (receiverId) async {
          final ok = await ref
              .read(workspaceNotifierProvider)
              .sendInvitation(workspaceId: workspaceId, receiverId: receiverId);
          if (!mounted) return;
          _showSnack(
            ok
                ? 'Davet gönderildi!'
                : ref.read(workspaceStateProvider).errorMessage ??
                      'Davet gönderilemedi.',
            isError: !ok,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final wsState = ref.watch(workspaceStateProvider);
    final rooms = wsState.myWorkspaces;
    final invitations = wsState.pendingInvitations;
    final isLoading = wsState.isLoading;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Oda Oluştur Butonu ───────────────────
              GestureDetector(
                onTap: isLoading ? null : _showCreateRoomSheet,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Yeni Oda Oluştur',
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
              const SizedBox(height: 16),

              if (invitations.isNotEmpty) ...[
                Text(
                  'Bekleyen Davetler',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                ...invitations.map(
                  (inv) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.mail_outline_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inv.workspaceName.isEmpty
                                    ? 'Çalışma odası daveti'
                                    : inv.workspaceName,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                inv.senderNickName.isEmpty
                                    ? 'Bir kullanıcı seni bu odaya davet etti.'
                                    : '${inv.senderNickName} seni bu odaya davet etti.',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final ok = await ref
                                      .read(workspaceNotifierProvider)
                                      .acceptInvitation(
                                        inv.workspaceInvitationId,
                                      );

                                  if (ok) {
                                    await ref
                                        .read(notificationHubServiceProvider)
                                        .syncWorkspaceGroups();
                                  }

                                  if (!mounted) return;

                                  _showSnack(
                                    ok
                                        ? 'Davet kabul edildi.'
                                        : ref
                                                  .read(workspaceStateProvider)
                                                  .errorMessage ??
                                              'Davet kabul edilmedi.',
                                    isError: !ok,
                                  );
                                },
                          child: Text(
                            'Kabul',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
              // ── Aktif Odalar ─────────────────────────
              Text(
                'Odalarım',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),

              if (rooms.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Text('🏠', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'Henüz oda yok',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Yeni bir oda oluştur ve arkadaşlarını davet et',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...rooms.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StudyRoomCard(
                      workspace: w,
                      onOpen: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkspaceDetailScreen(workspace: w),
                          ),
                        );
                      },
                      onInvite: () =>
                          _pickFriendAndInvite(w.workspaceId, w.workspaceName),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}
