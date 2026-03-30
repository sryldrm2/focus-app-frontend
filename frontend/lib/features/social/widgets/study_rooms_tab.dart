import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/social/widgets/study_room_card.dart';
import 'package:focus_app/features/social/widgets/create_room_sheet.dart';

class StudyRoomsTab extends StatefulWidget {
  const StudyRoomsTab({super.key});

  @override
  State<StudyRoomsTab> createState() => _StudyRoomsTabState();
}

class _StudyRoomsTabState extends State<StudyRoomsTab> {
  List<StudyRoom> _rooms = List.from(mockStudyRooms);

  void _showCreateRoomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateRoomSheet(
        onCreate: (name, subject, emoji, color, maxParticipants) {
          setState(() {
            _rooms.add(StudyRoom(
              id: DateTime.now().toString(),
              name: name,
              subject: subject,
              subjectEmoji: emoji,
              subjectColor: color,
              participantCount: 1,
              maxParticipants: maxParticipants,
              isActive: true,
              participants: [],
            ));
          });
        },
      ),
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

              // ── Oda Oluştur Butonu ───────────────────
              GestureDetector(
                onTap: _showCreateRoomSheet,
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
              const SizedBox(height: 20),

              // ── Aktif Odalar ─────────────────────────
              Text(
                'Aktif Odalar',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              if (_rooms.isEmpty)
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
                          'Yeni bir oda oluştur veya arkadaşlarının odasına katıl',
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
                ..._rooms.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StudyRoomCard(
                    room: r,
                    onJoin: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${r.name} odasına katıldın! 🎉'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                )),
            ]),
          ),
        ),
      ],
    );
  }
}