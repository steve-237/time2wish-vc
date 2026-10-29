import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Deep space background gradient
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color backgroundCard = Color(0xFF1E293B);
  static const Color surfaceDark = Color(0xFF334155);

  // Vibrant Accents
  static const Color primaryCyan = Color(0xFF0EA5E9);

  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFF43F5E);
  static const Color wishCoinsAmber = Color(0xFFFFB800);
  static const Color successGreen = Color(0xFF10B981);

  // Text Colors
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color borderLight = Color(0x1AFFFFFF);

  // Additional accent colors (replaces hardcoded hex values scattered across screens)
  static const Color cyanLight = Color(0xFF38BDF8);
  static const Color backgroundDialogDark = Color(0xFF1E1B4B);
  static const Color backgroundDeep = Color(0xFF0F172A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFFF8A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF0F172A),
      Color(0xFF1E1B4B),
      Color(0xFF0F172A),
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
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.backgroundDialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.primaryCyan,
        labelColor: AppColors.cyanLight,
        unselectedLabelColor: AppColors.textMutedDark,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
    );
  }

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);
    final headerTextTheme = GoogleFonts.outfitTextTheme(ThemeData.light().textTheme);

    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      primaryColor: AppColors.primaryCyan,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryCyan,
        secondary: AppColors.accentPurple,
        surface: Colors.white,
        error: AppColors.accentPink,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: headerTextTheme.displayLarge?.copyWith(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        displayMedium: headerTextTheme.displayMedium?.copyWith(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        titleLarge: headerTextTheme.titleLarge?.copyWith(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        titleMedium: headerTextTheme.titleMedium?.copyWith(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: const Color(0xFF1E293B)),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.03),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.primaryCyan,
        labelColor: AppColors.primaryCyan,
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
    );
  }
}
