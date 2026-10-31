import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Clean Professional Dark Palette (Matte Charcoal / Deep Slate)
  static const Color darkCanvas = Color(0xFF0B0F17);
  static const Color darkCard = Color(0xFF141B26);
  static const Color darkCardElevated = Color(0xFF1C2536);
  static const Color darkBorder = Color(0xFF263246);
  static const Color darkBorderSubtle = Color(0xFF1E2838);

  // Clean Professional Light Palette (Porcelain / Pure White)
  static const Color lightCanvas = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFEDF2F7);

  // High-Contrast Vibrant Accents
  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color indigoLight = Color(0xFF6366F1);
  static const Color primaryCyan = Color(0xFF0284C7);
  static const Color cyanLight = Color(0xFF38BDF8);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFF43F5E);
  static const Color accentCoral = Color(0xFFF43F5E);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color successGreen = Color(0xFF10B981);
  static const Color wishCoinsAmber = Color(0xFFF59E0B);

  // Text Colors
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color textMainLight = Color(0xFF0F172A);
  static const Color textMutedLight = Color(0xFF64748B);

  // Legacy mappings for backward compatibility
  static const Color backgroundDark = Color(0xFF0B0F17);
  static const Color backgroundCard = Color(0xFF141B26);
  static const Color surfaceDark = Color(0xFF1C2536);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color borderLight = Color(0xFF263246);
  static const Color backgroundDialogDark = Color(0xFF141B26);
  static const Color backgroundDeep = Color(0xFF0B0F17);

  // Clean Modern Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0B0F17),
      Color(0xFF0F141C),
      Color(0xFF0B0F17),
    ],
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    final headerTextTheme = GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme);

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.darkCanvas,
      primaryColor: AppColors.indigoLight,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.indigoLight,
        secondary: AppColors.primaryCyan,
        surface: AppColors.darkCard,
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
        fillColor: AppColors.darkCard,
        hintStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.indigoLight, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.indigoLight,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMutedDark,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkCardElevated,
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
      scaffoldBackgroundColor: AppColors.lightCanvas,
      primaryColor: AppColors.primaryIndigo,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryIndigo,
        secondary: AppColors.primaryCyan,
        surface: AppColors.lightCard,
        error: AppColors.accentPink,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: headerTextTheme.displayLarge?.copyWith(color: AppColors.textMainLight, fontWeight: FontWeight.bold),
        displayMedium: headerTextTheme.displayMedium?.copyWith(color: AppColors.textMainLight, fontWeight: FontWeight.bold),
        titleLarge: headerTextTheme.titleLarge?.copyWith(color: AppColors.textMainLight, fontWeight: FontWeight.bold),
        titleMedium: headerTextTheme.titleMedium?.copyWith(color: AppColors.textMainLight, fontWeight: FontWeight.w600),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: const Color(0xFF1E293B)),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: AppColors.textMutedLight),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCard,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightBorderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryIndigo, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.primaryIndigo,
        labelColor: AppColors.primaryIndigo,
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
