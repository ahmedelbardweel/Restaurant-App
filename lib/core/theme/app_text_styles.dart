import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Headings (Tajawal)
  static TextStyle get displayLarge => GoogleFonts.tajawal(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.tajawal(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      );

  static TextStyle get displaySmall => GoogleFonts.tajawal(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      );

  // Body Text (Tajawal)
  static TextStyle get bodyLarge => GoogleFonts.tajawal(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodyMedium => GoogleFonts.tajawal(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodySmall => GoogleFonts.tajawal(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  // Buttons & Labels (Tajawal)
  static TextStyle get labelLarge => GoogleFonts.tajawal(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get labelMedium => GoogleFonts.tajawal(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      );
}
