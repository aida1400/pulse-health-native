import 'package:flutter/material.dart';

class AppTheme {
  // Medical Decoy Theme (Clinical, stealthy medical monitor)
  static final ThemeData decoyTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF0F050A),
    scaffoldBackgroundColor: const Color(0xFF0A0206),
    cardColor: const Color(0xFF1A0710),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF10B981), // Emerald green pulse ECG
      secondary: Color(0xFFE11D48),
      surface: Color(0xFF1A0710),
    ),
    fontFamily: 'Vazirmatn',
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
    ),
  );

  // Secret Romantic Theme (100% Dark Crimson & Velvet Red - No Navy Blue)
  static final ThemeData secretTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFE11D48), // Rose red / Crimson
    scaffoldBackgroundColor: const Color(0xFF0D0307), // Velvet black cherry
    cardColor: const Color(0xFF1C0612), // Dark wine
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFE11D48),
      secondary: Color(0xFFFB7185),
      surface: Color(0xFF1E0713),
      background: Color(0xFF0D0307),
    ),
    fontFamily: 'Vazirmatn',
  );
}
