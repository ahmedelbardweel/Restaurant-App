import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Colors.deepOrange;
  static const Color primaryLight = Color(0xFFFFCCBC); // deepOrange[100]
  static const Color primaryDark = Color(0xFFBF360C); // deepOrange[900]

  // Neutral Colors
  static const Color backgroundLight = Colors.white;
  static const Color backgroundDark = Color(0xFF121212); // Standard dark background
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimaryLight = Colors.black87;
  static const Color textSecondaryLight = Colors.black54;
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Colors.white70;

  // Border & Dividers
  static const Color borderLight = Color(0xFFE0E0E0); // grey[300]
  static const Color borderDark = Color(0xFF424242); // grey[800]

  // State Colors
  static const Color error = Colors.redAccent;
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;
}
