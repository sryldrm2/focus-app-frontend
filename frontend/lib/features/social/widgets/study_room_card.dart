import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';

class RoomParticipant {
  final String id;
  final String displayName;
  final String avatarEmoji;
  final bool isWorking;
  final int completedPomodoros;

  const RoomParticipant({
    required this.id,
    required this.displayName,
    required this.avatarEmoji,
    required this.isWorking,
    required this.completedPomodoros,
  });
}

class StudyRoom {
  final String id;
  final String name;
  final String subject;
  final String subjectEmoji;
  final Color subjectColor;
  final int participantCount;
  final int maxParticipants;
  final bool isActive;
  final List<RoomParticipant> participants;

  const StudyRoom({
    required this.id,
    required this.name,
    required this.subject,
    required this.subjectEmoji,
    required this.subjectColor,
    required this.participantCount,
    required this.maxParticipants,
    required this.isActive,
    required this.participants,
  });
}

final mockStudyRooms = [
  StudyRoom(
    id: '1',
    name: 'Matematik Kampı',
    subject: 'Matematik',
    subjectEmoji: '📐',
    subjectColor: Color(0xFFE74C3C),
    participantCount: 3,
    maxParticipants: 5,
    isActive: true,
    participants: [
      RoomParticipant(id: '1', displayName: 'Ahmet', avatarEmoji: '🦊', isWorking: true, completedPomodoros: 3),
      RoomParticipant(id: '2', displayName: 'Zeynep', avatarEmoji: '🐻', isWorking: true, completedPomodoros: 2),
      RoomParticipant(id: '3', displayName: 'Sen', avatarEmoji: '⭐', isWorking: false, completedPomodoros: 0),
    ],
  ),
  StudyRoom(
    id: '2',
    name: 'İngilizce Grubu',
    subject: 'İngilizce',
    subjectEmoji: '📖',
    subjectColor: Color(0xFF2ECC71),
    participantCount: 2,
    maxParticipants: 4,
    isActive: true,
    participants: [
      RoomParticipant(id: '1', displayName: 'Mehmet', avatarEmoji: '🐯', isWorking: false, completedPomodoros: 1),
      RoomParticipant(id: '2', displayName: 'Ayşe', avatarEmoji: '🦋', isWorking: true, completedPomodoros: 4),
    ],
  ),
];

class StudyRoomCard extends StatelessWidget {
  final StudyRoom room;
  final VoidCallback onJoin;

  const StudyRoomCard({
    super.key,
    required this.room,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = room.participantCount >= room.maxParticipants;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Üst satır ────────────────────────────
          Row(
            children: [
              // Konu badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: room.subjectColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      room.subjectEmoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      room.subject,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: room.subjectColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Aktif göstergesi
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Aktif',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Oda adı
          Text(
            room.name,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // ── Katılımcılar ──────────────────────────
          Row(
            children: [
              // Avatar stack
              SizedBox(
                width: room.participants.length * 28.0 + 8,
                height: 32,
                child: Stack(
                  children: room.participants.asMap().entries.map((e) {
                    return Positioned(
                      left: e.key * 22.0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: e.value.isWorking
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.backgroundLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: e.value.isWorking
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            e.value.avatarEmoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${room.participantCount}/${room.maxParticipants} kişi',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),

              // Katıl butonu
              GestureDetector(
                onTap: isFull ? null : onJoin,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isFull
                        ? Colors.grey.shade100
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isFull ? 'Dolu' : 'Katıl',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isFull ? Colors.grey : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}