import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.nunito(
    fontSize: 32, fontWeight: FontWeight.w800,
  );
  static TextStyle get headlineMedium => GoogleFonts.nunito(
    fontSize: 22, fontWeight: FontWeight.w700,
  );
  static TextStyle get titleLarge => GoogleFonts.nunito(
    fontSize: 18, fontWeight: FontWeight.w600,
  );
  static TextStyle get bodyMedium => GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w400,
  );
  static TextStyle get labelSmall => GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Timer ekranı için özel monospace
  static TextStyle get timerDisplay => GoogleFonts.spaceMono(
    fontSize: 64, fontWeight: FontWeight.w700,
  );
}