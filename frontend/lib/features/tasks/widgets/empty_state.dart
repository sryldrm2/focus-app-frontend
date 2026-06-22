import 'package:flutter/material.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class TasksEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const TasksEmptyState({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📋', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(
            'Bu gün için görev yok',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Görev ekleyerek çalışmana başla!',
            style: GoogleFonts.dmSans(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(Icons.add, color: colorScheme.onPrimary),
            label: Text(
              'Görev Ekle',
              style: GoogleFonts.nunito(
                  color: colorScheme.onPrimary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}