import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Deep space background gradient
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color backgroundCard = Color(0xFF161F33);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Vibrant Accents
  static const Color primaryCyan = Color(0xFF0EA5E9);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFF43F5E);
  static const Color wishCoinsAmber = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);

  // Text Colors
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color borderLight = Color(0x1AFFFFFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0B0F19),
      Color(0xFF0F172A),
      Color(0xFF1E1B4B),
      Color(0xFF0B0F19),
    ],
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    final headerTextTheme = GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme);

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.backgroundDark,
      primaryColor: AppColors.primaryCyan,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryCyan,
        secondary: AppColors.accentPurple,
        surface: AppColors.surfaceDark,
        error: AppColors.accentPink,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: headerTextTheme.displayLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        displayMedium: headerTextTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        titleLarge: headerTextTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        titleMedium: headerTextTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: AppColors.textLight),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: AppColors.textMutedDark),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        hintStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;
}
