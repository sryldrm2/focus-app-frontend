import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';
import 'package:focus_app/features/tasks/network/task_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTaskSheet extends StatefulWidget {
  final DateTime initialDate;
  final Future<bool> Function(CreateTaskDto)? onAdd;
  final Future<bool> Function(String taskId, UpdateTaskDto)? onUpdate;
  final TaskModel? taskToEdit;
  final String? workspaceId;
  final String title;

  const AddTaskSheet({
    super.key,
    required this.initialDate,
    this.onAdd,
    this.onUpdate,
    this.taskToEdit,
    this.workspaceId,
    this.title = 'Yeni Görev',
  });

  bool get isEditing => taskToEdit != null;

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _pomodoroController = TextEditingController();
  DateTime? _dueDate;
  Color _selectedColor = const Color(0xFFE85D04);
  int? _priority;
  bool _isLoading = false;
  String? _pomodoroError;

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
    final task = widget.taskToEdit;
    if (task != null) {
      _titleController.text = task.title;
      _descController.text = task.description;
      _dueDate = task.dueDate;
      _selectedColor = task.color;
      _priority = task.priority;
      if (task.pomodoroTargetCount != null) {
        _pomodoroController.text = '${task.pomodoroTargetCount}';
      }
    } else {
      _dueDate = widget.initialDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _pomodoroController.dispose();
    super.dispose();
  }

  int? _parsePomodoroTarget() {
    final text = _pomodoroController.text.trim();
    if (text.isEmpty) return null;
    final value = int.tryParse(text);
    if (value == null || value < 1 || value > 500) {
      setState(() {
        _pomodoroError = '1 ile 500 arasında bir sayı girin';
      });
      return null;
    }
    setState(() => _pomodoroError = null);
    return value;
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    final pomodoroTarget = _parsePomodoroTarget();
    if (_pomodoroController.text.trim().isNotEmpty &&
        pomodoroTarget == null) {
      return;
    }

    setState(() => _isLoading = true);

    final success = widget.isEditing
        ? await widget.onUpdate!(
            widget.taskToEdit!.taskId,
            UpdateTaskDto(
              title: _titleController.text.trim(),
              description: _descController.text.trim().isEmpty
                  ? ''
                  : _descController.text.trim(),
              priority: _priority,
              dueDate: _dueDate,
              pomodoroTargetCount: pomodoroTarget,
            ),
          )
        : await widget.onAdd!(
            CreateTaskDto(
              title: _titleController.text.trim(),
              description: _descController.text.trim().isEmpty
                  ? null
                  : _descController.text.trim(),
              priority: _priority,
              dueDate: _dueDate,
              workspaceId: widget.workspaceId,
              pomodoroTargetCount: pomodoroTarget,
            ),
          );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              widget.title,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),

            _Label('Görev Başlığı *'),
            _Field(
              controller: _titleController,
              hint: 'ör. Matematik çalış, Essay yaz...',
              accentColor: _selectedColor,
            ),
            const SizedBox(height: 14),

            _Label('Açıklama (opsiyonel)'),
            _Field(
              controller: _descController,
              hint: 'Notlar, detaylar...',
              accentColor: _selectedColor,
              maxLines: 2,
            ),
            const SizedBox(height: 14),

            _Label('Renk'),
            Row(
              children: _colors.map((c) {
                final isSel = c.value == _selectedColor.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 10),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isSel
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: c.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    child: isSel
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

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
                        primary: AppColors.primary,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate != null
                          ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                          : 'Tarih seç',
                      style: GoogleFonts.dmSans(color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            _Label('Öncelik (opsiyonel)'),
            Row(
              children: List.generate(5, (i) {
                final val = i + 1;
                final isSel = _priority == val;
                return GestureDetector(
                  onTap: () => setState(() => _priority = isSel ? null : val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSel
                          ? _selectedColor
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '$val',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSel
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),

            _Label('Pomodoro hedefi (opsiyonel)'),
            _Field(
              controller: _pomodoroController,
              hint: 'ör. 4',
              accentColor: _selectedColor,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            if (_pomodoroError != null) ...[
              const SizedBox(height: 6),
              Text(
                _pomodoroError!,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: colorScheme.onPrimary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        widget.isEditing ? 'Değişiklikleri Kaydet' : 'Görevi Kaydet',
                        style: GoogleFonts.nunito(
                          color: colorScheme.onPrimary,
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color accentColor;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.controller,
    required this.hint,
    required this.accentColor,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.dmSans(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(color: colorScheme.onSurfaceVariant),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
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
}
