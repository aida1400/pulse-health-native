import 'package:flutter/material.dart';

class AppTheme {
  // Medical Decoy Theme (Clinical ECG Monitor)
  static final ThemeData decoyTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF0F172A),
    scaffoldBackgroundColor: const Color(0xFF070B14),
    cardColor: const Color(0xFF131D2E),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF10B981), // Emerald green pulse line
      secondary: Color(0xFF06B6D4),
      surface: Color(0xFF131D2E),
    ),
    fontFamily: 'Vazirmatn',
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
    ),
  );

  // Secret Romantic Theme (Deep Obsidian Black + Rich Crimson Red / Wine - No Navy Blue!)
  static final ThemeData secretTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFE11D48),
    scaffoldBackgroundColor: const Color(0xFF0C0206), // Deep obsidian black
    cardColor: const Color(0xFF220512),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFE11D48),
      secondary: Color(0xFFFB7185),
      surface: Color(0xFF1A040D),
    ),
    fontFamily: 'Vazirmatn',
  );
}
