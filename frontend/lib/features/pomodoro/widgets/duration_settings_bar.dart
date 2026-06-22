import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';

class DurationSettingsBar extends StatelessWidget {
  final int workMinutes;
  final int breakMinutes;
  final int longBreakMinutes;
  final bool enabled;
  final void Function(int work, int breakMin, int longBreak) onChanged;

  const DurationSettingsBar({
    super.key,
    required this.workMinutes,
    required this.breakMinutes,
    required this.longBreakMinutes,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _DurationChip(
                emoji: '🎯',
                label: 'Odak',
                value: workMinutes,
                min: 5,
                max: 90,
                enabled: enabled,
                onChanged: (v) => onChanged(v, breakMinutes, longBreakMinutes),
              ),
            ),
            Container(
              width: 1,
              height: 52,
              color: colorScheme.outline.withOpacity(0.35),
            ),
            Expanded(
              child: _DurationChip(
                emoji: '☕',
                label: 'Kısa mola',
                value: breakMinutes,
                min: 1,
                max: 30,
                enabled: enabled,
                onChanged: (v) => onChanged(workMinutes, v, longBreakMinutes),
              ),
            ),
            Container(
              width: 1,
              height: 52,
              color: colorScheme.outline.withOpacity(0.35),
            ),
            Expanded(
              child: _DurationChip(
                emoji: '🛋️',
                label: 'Uzun mola',
                value: longBreakMinutes,
                min: 5,
                max: 60,
                enabled: enabled,
                onChanged: (v) => onChanged(workMinutes, breakMinutes, v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String emoji;
  final String label;
  final int value;
  final int min;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _DurationChip({
    required this.emoji,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (enabled)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepButton(
                icon: Icons.remove,
                active: value > min,
                onTap: value > min ? () => onChanged(value - 1) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '$value',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                active: value < max,
                onTap: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          )
        else
          Text(
            '$value dk',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  const _StepButton({
    required this.icon,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.1)
              : colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: active ? AppColors.primary : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
