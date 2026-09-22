import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Headings (Original Surfer)
  static TextStyle get displayLarge => GoogleFonts.originalSurfer(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      );

  static TextStyle get displayMedium => GoogleFonts.originalSurfer(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      );

  static TextStyle get displaySmall => GoogleFonts.originalSurfer(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      );

  // Body Text (Poppins)
  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  // Buttons & Labels (Poppins)
  static TextStyle get labelLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get labelMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );
}
