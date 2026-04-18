import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';

class CreateRoomSheet extends StatefulWidget {
  final Function(String name, String subject, String emoji, Color color, int maxParticipants) onCreate;

  const CreateRoomSheet({super.key, required this.onCreate});

  @override
  State<CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<CreateRoomSheet> {
  final _nameController = TextEditingController();
  int _selectedSubjectIndex = 0;
  int _maxParticipants = 4;
  bool _isLoading = false;

  final _subjects = const [
    {'name': 'Matematik', 'emoji': '📐', 'color': Color(0xFFE74C3C)},
    {'name': 'Fizik', 'emoji': '⚡', 'color': Color(0xFF3498DB)},
    {'name': 'İngilizce', 'emoji': '📖', 'color': Color(0xFF2ECC71)},
    {'name': 'Kimya', 'emoji': '🧪', 'color': Color(0xFF9B59B6)},
    {'name': 'Biyoloji', 'emoji': '🌿', 'color': Color(0xFF1ABC9C)},
    {'name': 'Tarih', 'emoji': '📜', 'color': Color(0xFFE67E22)},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    final subject = _subjects[_selectedSubjectIndex];
    widget.onCreate(
      _nameController.text.trim(),
      subject['name'] as String,
      subject['emoji'] as String,
      subject['color'] as Color,
      _maxParticipants,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tutamaç
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Center(
              child: Text(
                'Çalışma Odası Oluştur',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Oda adı
            Text(
              'Oda Adı',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _nameController,
                style: GoogleFonts.dmSans(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Örn: Matematik Kampı',
                  hintStyle: GoogleFonts.dmSans(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Konu seçimi
            Text(
              'Konu',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _subjects.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final s = _subjects[i];
                  final isSelected = _selectedSubjectIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSubjectIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? s['color'] as Color
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? s['color'] as Color
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(s['emoji'] as String,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            s['name'] as String,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Maksimum katılımcı
            Row(
              children: [
                Text(
                  'Maksimum Katılımcı',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _maxParticipants > 2
                      ? () => setState(() => _maxParticipants--)
                      : null,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _maxParticipants > 2
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 16,
                      color: _maxParticipants > 2
                          ? AppColors.primary
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$_maxParticipants',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _maxParticipants < 10
                      ? () => setState(() => _maxParticipants++)
                      : null,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _maxParticipants < 10
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      size: 16,
                      color: _maxParticipants < 10
                          ? AppColors.primary
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Oluştur butonu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _create,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Oda Oluştur',
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
      ),
    );
  }
}