

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AiSuggestionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8B4FE), width: 1),
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Öneri',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7C3AED),
                ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Matematik sınavına 3 gün kaldı. Bugün odaklanmanı öneririm.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFF6D28D9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.go('/chat'),
            child: Text(
              'Sor →',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7C3AED),
              ),
            ),
          )
        ],
      ),
    );
  }
}