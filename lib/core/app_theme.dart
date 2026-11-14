import 'package:flutter/material.dart';

class AppTheme {
  // Medical Decoy Theme (Clean, clinical, trustworthy)
  static final ThemeData decoyTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF0F172A),
    scaffoldBackgroundColor: const Color(0xFF0A0F1D),
    cardColor: const Color(0xFF1E293B),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF10B981), // Emerald green pulse line
      secondary: Color(0xFF06B6D4), // Cyan accents
      surface: Color(0xFF1E293B),
    ),
    fontFamily: 'Vazirmatn',
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
    ),
  );

  // Secret Intimate Theme (Warm, deep rose, romantic gradients)
  static final ThemeData secretTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFE11D48), // Rose red
    scaffoldBackgroundColor: const Color(0xFF0F0715), // Deep midnight violet
    cardColor: const Color(0xFF261230),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF43F5E),
      secondary: Color(0xFFFDA4AF),
      surface: Color(0xFF200F29),
    ),
    fontFamily: 'Vazirmatn',
  );
}
