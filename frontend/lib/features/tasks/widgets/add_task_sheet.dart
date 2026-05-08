import 'package:flutter/material.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/tasks/network/task_service.dart';
import 'package:google_fonts/google_fonts.dart';
 
class AddTaskSheet extends StatefulWidget {
  final DateTime initialDate;
  final Future<bool> Function(CreateTaskDto) onAdd;
 
  const AddTaskSheet({
    super.key,
    required this.initialDate,
    required this.onAdd,
  });
 
  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}
 
class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _dueDate;
  Color _selectedColor = const Color(0xFFE85D04);
  int? _priority;
  bool _isLoading = false;
 
  static const _colors = [
    Color(0xFFE74C3C),
    Color(0xFF3498DB),
    Color(0xFF2ECC71),
    Color(0xFF9B59B6),
    Color(0xFFF39C12),
    Color(0xFF1ABC9C),
  ];
 
  @override
  void initState() {
    super.initState();
    _dueDate = widget.initialDate;
  }
 
  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
 
  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final dto = CreateTaskDto(
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
        ? null
        : _descController.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
    );

    final success = await widget.onAdd(dto);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() => _isLoading = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
 
            Text(
              'Yeni Görev',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
 
            // Başlık
            _Label('Görev Başlığı *'),
            _Field(
              controller: _titleController,
              hint: 'ör. Matematik çalış, Essay yaz...',
              accentColor: _selectedColor,
            ),
            const SizedBox(height: 14),
 
            // Açıklama
            _Label('Açıklama (opsiyonel)'),
            _Field(
              controller: _descController,
              hint: 'Notlar, detaylar...',
              accentColor: _selectedColor,
              maxLines: 2,
            ),
            const SizedBox(height: 14),
 
            // Renk
            _Label('Renk'),
            Row(
              children: _colors.map((c) {
                final isSel = c.value == _selectedColor.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 10),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isSel
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                      boxShadow: isSel
                          ? [BoxShadow(
                              color: c.withOpacity(0.5), blurRadius: 6)]
                          : null,
                    ),
                    child: isSel
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
 
            // Tarih
            _Label('Tarih'),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                          primary: AppColors.primary),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate != null
                          ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                          : 'Tarih seç',
                      style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
 
            // Öncelik
            _Label('Öncelik (opsiyonel)'),
            Row(
              children: List.generate(5, (i) {
                final val = i + 1;
                final isSel = _priority == val;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _priority = isSel ? null : val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isSel
                          ? _selectedColor
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '$val',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSel
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
 
            // Kaydet
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Görevi Kaydet',
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
 
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
 
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      );
}
 
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color accentColor;
  final int maxLines;
 
  const _Field({
    required this.controller,
    required this.hint,
    required this.accentColor,
    this.maxLines = 1,
  });
 
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.dmSans(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.backgroundLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 1.5),
          ),
        ),
      );
}