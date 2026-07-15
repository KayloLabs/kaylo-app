import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'kaylo_liquid_glass.dart';

class KayloSnackbar {
  static void showSuccess(BuildContext context, String message) {
    _showSnackbar(context, message, AppColors.success, Icons.check_circle);
  }

  static void showError(BuildContext context, String message) {
    _showSnackbar(context, message, AppColors.error, Icons.error);
  }

  static void showInfo(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _showSnackbar(context, message, isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, Icons.info);
  }

  static void _showSnackbar(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        content: Center(
          child: KayloLiquidGlass(
            borderRadius: 100, // Pill shape
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Keep it compact
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, 
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
