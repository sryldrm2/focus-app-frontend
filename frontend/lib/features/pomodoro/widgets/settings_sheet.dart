import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsSheet extends StatefulWidget {
  final int workMinutes;
  final int breakMinutes;
  final int longBreakMinutes;
  final Function(int work, int breakMin, int longBreakMin) onSave;

  const SettingsSheet({
    super.key,
    required this.workMinutes,
    required this.breakMinutes,
    required this.longBreakMinutes,
    required this.onSave,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late int _tempWork;
  late int _tempBreak;
  late int _tempLongBreak;

  @override
  void initState() {
    super.initState();
    _tempWork = widget.workMinutes;
    _tempBreak = widget.breakMinutes;
    _tempLongBreak = widget.longBreakMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Timer Ayarları',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 28),

          SettingRow(
            label: 'Çalışma Süresi',
            emoji: '🎯',
            value: _tempWork,
            min: 5,
            max: 90,
            onChanged: (v) => setState(() => _tempWork = v),
          ),
          const SizedBox(height: 20),

          SettingRow(
            label: 'Mola Süresi',
            emoji: '☕',
            value: _tempBreak,
            min: 1,
            max: 30,
            onChanged: (v) => setState(() => _tempBreak = v),
          ),
          const SizedBox(height: 28),

          SettingRow(
            label: 'Uzun Mola Süresi',
            emoji: '🛋️',
            value: _tempLongBreak,
            min: 5,
            max: 60,
            onChanged: (v) => setState(() => _tempLongBreak = v),
          ),
          const SizedBox(height: 28),

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
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('work_minutes', _tempWork);
                await prefs.setInt('break_minutes', _tempBreak);
                await prefs.setInt('long_break_minutes', _tempLongBreak);
                widget.onSave(_tempWork, _tempBreak, _tempLongBreak);
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              child: Text(
                'Kaydet',
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
    );
  }
}

class SettingRow extends StatelessWidget {
  final String label;
  final String emoji;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const SettingRow({
    super.key,
    required this.label,
    required this.emoji,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        GestureDetector(
          onTap: value > min ? () => onChanged(value - 1) : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: value > min
                  ? AppColors.primary.withOpacity(0.1)
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.remove,
              size: 18,
              color: value > min ? AppColors.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 52,
          child: Text(
            '$value dk',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: value < max ? () => onChanged(value + 1) : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: value < max
                  ? AppColors.primary.withOpacity(0.1)
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add,
              size: 18,
              color: value < max ? AppColors.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
