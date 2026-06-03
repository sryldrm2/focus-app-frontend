import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/auth/providers/auth_providers.dart';
import 'package:focus_app/features/social/models/friend_models.dart';
import 'package:focus_app/features/social/providers/social_providers.dart';
import 'package:focus_app/features/social/providers/workspace_provider.dart';
import 'package:focus_app/features/social/widgets/create_room_sheet.dart';
import 'package:focus_app/features/social/widgets/study_room_card.dart';

class StudyRoomsTab extends ConsumerStatefulWidget {
  const StudyRoomsTab({super.key});

  @override
  ConsumerState<StudyRoomsTab> createState() => _StudyRoomsTabState();
}

class _StudyRoomsTabState extends ConsumerState<StudyRoomsTab> {
  final _invitationIdController = TextEditingController();

  @override
  void dispose() {
    _invitationIdController.dispose();
    super.dispose();
  }

  void _showCreateRoomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateRoomSheet(),
    );
  }

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

  Future<void> _pickFriendAndInvite(String workspaceId) async {
    await ref.read(socialNotifierProvider).loadAll();
    if (!mounted) return;

    final friends = ref.read(socialStateProvider).myFriends;
    final myUserId = ref.read(authNotifierProvider).state.user?.userId ?? '';

    if (friends.isEmpty) {
      _showSnack('Davet için önce arkadaş eklemen gerekiyor.', isError: true);
      return;
    }

    final picked = await showModalBottomSheet<FriendshipModel>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Arkadaşını davet et',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...friends.map((f) {
                final other = f.otherUser(myUserId);
                return ListTile(
                  title: Text(other.nickname),
                  subtitle: Text('${other.name} ${other.surname}'.trim()),
                  onTap: () => Navigator.pop(ctx, f),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (picked == null || !mounted) return;

    final receiverId = picked.otherUser(myUserId).userId;
    final ok = await ref
        .read(workspaceNotifierProvider)
        .sendInvitation(workspaceId: workspaceId, receiverId: receiverId);

    if (!mounted) return;

    if (ok) {
      final invId = ref.read(workspaceStateProvider).lastInvitationId;
      _showSnack(
        'Davet gönderildi${invId != null ? ' (ID: ${invId.substring(0, 8)}…)' : ''}',
      );
    } else {
      final msg = ref.read(workspaceStateProvider).errorMessage;
      _showSnack(msg ?? 'Davet gönderilemedi.', isError: true);
    }
  }

  Future<void> _acceptInvitation() async {
    final id = _invitationIdController.text.trim();
    if (id.isEmpty) {
      _showSnack('Davet ID gir.', isError: true);
      return;
    }

    final ok = await ref.read(workspaceNotifierProvider).acceptInvitation(id);
    if (!mounted) return;

    if (ok) {
      _invitationIdController.clear();
      _showSnack('Davet kabul edildi.');
    } else {
      final msg = ref.read(workspaceStateProvider).errorMessage;
      _showSnack(msg ?? 'Davet kabul edilmedi.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wsState = ref.watch(workspaceStateProvider);
    final rooms = wsState.myWorkspaces;
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

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Davet kabul et',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _invitationIdController,
                      decoration: InputDecoration(
                        hintText: 'workspaceInvitationId',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: isLoading ? null : _acceptInvitation,
                        child: const Text('Kabul Et'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Aktif Odalar ─────────────────────────
              Text(
                'Odalarım',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Yeni bir oda oluştur ve arkadaşlarını davet et',
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
                ...rooms.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StudyRoomCard(
                      workspace: w,
                      onInvite: () => _pickFriendAndInvite(w.workspaceId),
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
