import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color brandPrimary = Color(0xFF2F7A4F); // Kaylo Green
  static const Color brandPrimaryDark = Color(0xFF1F5638);
  static const Color brandPrimaryBright = Color(0xFF46B876);

  // Accents
  static const Color accent = Color(0xFFF0824D); // Terracotta
  static const Color secondaryAccent = Color(0xFFF2B33D); // Mustard Highlight
  static const Color success = Color(0xFF46B876); // Using bright primary for success
  static const Color error = Color(0xFFE5484D); // Standard error red
  static const Color warning = Color(0xFFF2B33D);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF7F9F6); // Clean, barely-green white
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceAlt = Color(0xFFEFF3EE); // Subtle section backgrounds
  static const Color surfaceTint = Color(0xFFEFF3EE); // Alias for backwards compat
  static const Color surfaceMuted = Color(0xFFEFF3EE); // Alias for backwards compat
  
  // Section Accents
  static const Color homeAccent = Color(0xFF2D6BE4);
  static const Color farmAccent = Color(0xFFF0851B);
  static const Color careAccent = Color(0xFF7A5AF5);

  // Typography
  static const Color textPrimary = Color(0xFF16211B); // Near-black with green undertone
  static const Color textSecondary = Color(0xFF5C6B62);
  static const Color deepCharcoal = Color(0xFF16211B); // Alias
  
  static const Color border = Color(0xFFE2E8E1);
  
  // --- DARK MODE SURFACES ---
  static const Color surfaceMutedDark = Color(0xFF0A0A0A);
  static const Color surfaceDark = Color(0xFF141414);
  static const Color surfaceModalDark = Color(0xFF1C1C1E); // Apple modal dark
  
  static const Color surfaceTintDark = Color(0xFF1F2221);
  
  static const Color textPrimaryDark = Color(0xFFF5F5F7); // Apple off-white text
  static const Color textSecondaryDark = Color(0xFF86868B); // Apple secondary text
  static const Color borderDark = Color(0xFF2C2C2E); // Apple dark border
}
