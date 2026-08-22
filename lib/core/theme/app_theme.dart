import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF0A66C2);
  static const Color primaryDark = Color(0xFF004182);
  static const Color primaryLight = Color(0xFF3D8FE0);

  // Neutral
  static const Color darkText = Color(0xFF0F172A);
  static const Color secondaryText = Color(0xFF475569);
  static const Color lightText = Color(0xFF94A3B8);
  static const Color divider = Color(0xFFE2E8F0);

  // Accent
  static const Color accent = Color(0xFF0EA5E9);

  // Background
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Pipeline Status
  static const Color applied = Color(0xFF3B82F6);
  static const Color shortlisted = Color(0xFF8B5CF6);
  static const Color interviewing = Color(0xFFF59E0B);
  static const Color hired = Color(0xFF10B981);
  static const Color rejected = Color(0xFFEF4444);

  // Utility
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static Color getStatusColor(String status) {
    switch (status) {
      case 'applied':
        return applied;
      case 'shortlisted':
        return shortlisted;
      case 'interviewing':
        return interviewing;
      case 'hired':
        return hired;
      case 'rejected':
        return rejected;
      default:
        return lightText;
    }
  }

  static String getStatusLabel(String status) {
    switch (status) {
      case 'applied':
        return 'Applied';
      case 'shortlisted':
        return 'Shortlisted';
      case 'interviewing':
        return 'Interviewing';
      case 'hired':
        return 'Hired';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.darkText,
        error: AppColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.darkText,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.lightText,
        ),
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: AppColors.darkText,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: AppColors.darkText,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          color: AppColors.darkText,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: AppColors.darkText,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: AppColors.darkText,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          color: AppColors.darkText,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: AppColors.darkText,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.secondaryText,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: AppColors.lightText,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.secondaryText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
