import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimary,
        primary: AppColors.brandPrimary,
        secondary: AppColors.homeAccent,
        error: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.surfaceMuted,
      textTheme: AppTypography.appleTheme,

      // Default Card Theme
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Default AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      // Default Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.brandPrimary,
        primary: AppColors.brandPrimary,
        secondary: AppColors.homeAccent,
        error: AppColors.error,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
      ),
      scaffoldBackgroundColor: AppColors.surfaceMutedDark,
      textTheme: AppTypography.appleTheme.apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),

      cardTheme: CardTheme(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 2),
        ),
      ),
    );
  }

  /// Senior-friendly Kaylo Care theme: 18sp minimum body text, 56x56 tap
  /// targets, high contrast, and calmer shapes. Applied as a local Theme
  /// override on Care screens (see CareHomeScreen), not app-wide.
  static ThemeData get careTheme {
    const careText = Color(0xFF101511); // near-black, >13:1 on white
    const careSurface = Colors.white;
    const careBackground = Color(0xFFF6F4FC); // whisper of care violet
    const careBorder = Color(0xFFAEB6AF);

    final base = AppTypography.appleTheme;
    final careTextTheme = base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(fontSize: 36),
          displayMedium: base.displayMedium?.copyWith(fontSize: 32),
          displaySmall: base.displaySmall?.copyWith(fontSize: 28),
          headlineMedium: base.headlineMedium?.copyWith(fontSize: 26),
          titleLarge: base.titleLarge?.copyWith(
              fontSize: 24, fontWeight: FontWeight.w700),
          titleMedium: base.titleMedium?.copyWith(
              fontSize: 20, fontWeight: FontWeight.w600),
          bodyLarge: base.bodyLarge?.copyWith(fontSize: 20, height: 1.4),
          bodyMedium: base.bodyMedium?.copyWith(fontSize: 18, height: 1.4),
          bodySmall: base.bodySmall?.copyWith(fontSize: 16, height: 1.35),
          labelLarge: base.labelLarge?.copyWith(
              fontSize: 18, fontWeight: FontWeight.w700),
          labelSmall: base.labelSmall?.copyWith(fontSize: 16),
        )
        .apply(bodyColor: careText, displayColor: careText);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimaryDark,
        primary: AppColors.brandPrimaryDark,
        secondary: AppColors.careAccent,
        error: AppColors.error,
        surface: careSurface,
        onSurface: careText,
      ),
      scaffoldBackgroundColor: careBackground,
      textTheme: careTextTheme,
      visualDensity: VisualDensity.comfortable,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      iconTheme: const IconThemeData(size: 28, color: careText),
      dividerTheme: const DividerThemeData(color: careBorder, thickness: 1.5),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 16,
        iconColor: careText,
      ),
      cardTheme: CardTheme(
        color: careSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: careBorder, width: 1.5),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: careBackground,
        foregroundColor: careText,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: careTextTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(56, 56),
          backgroundColor: AppColors.brandPrimaryDark,
          foregroundColor: Colors.white,
          textStyle: careTextTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(56, 56),
          foregroundColor: AppColors.brandPrimaryDark,
          textStyle: careTextTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(56, 56),
          foregroundColor: AppColors.brandPrimaryDark,
          textStyle: careTextTheme.labelLarge,
          side: const BorderSide(color: AppColors.brandPrimaryDark, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
      ),
    );
  }
}
