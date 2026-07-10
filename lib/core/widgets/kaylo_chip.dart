import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum KayloChipVariant { brand, success, error, warning, neutral }

class KayloChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final KayloChipVariant variant;

  const KayloChip({
    super.key,
    required this.label,
    this.icon,
    this.variant = KayloChipVariant.brand,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _getChipColors(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(100), // Clean capsule shape
        border: Border.all(color: colors.borderColor, width: 0.5), // Subtle thin border
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colors.iconColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500, // Slightly less heavy
              color: colors.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _ChipColors _getChipColors(bool isDark) {
    // Monochrome typography for a cleaner, premium look
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final baseBg = Colors.transparent;
    final baseBorder = isDark ? AppColors.borderDark : AppColors.border;

    switch (variant) {
      case KayloChipVariant.brand:
        return _ChipColors(
          backgroundColor: isDark ? AppColors.brandPrimaryDark.withValues(alpha: 0.1) : AppColors.brandPrimary.withValues(alpha: 0.05),
          borderColor: isDark ? AppColors.brandPrimaryDark.withValues(alpha: 0.3) : AppColors.brandPrimary.withValues(alpha: 0.2),
          textColor: primaryText,
          iconColor: isDark ? AppColors.brandPrimaryDark : AppColors.brandPrimary,
        );
      case KayloChipVariant.success:
        return _ChipColors(
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          borderColor: AppColors.success.withValues(alpha: 0.2),
          textColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          iconColor: AppColors.success,
        );
      case KayloChipVariant.error:
        return _ChipColors(
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          borderColor: AppColors.error.withValues(alpha: 0.2),
          textColor: primaryText,
          iconColor: AppColors.error,
        );
      case KayloChipVariant.warning:
        return _ChipColors(
          backgroundColor: AppColors.warning.withValues(alpha: 0.15),
          borderColor: AppColors.warning.withValues(alpha: 0.3),
          textColor: primaryText,
          iconColor: AppColors.warning,
        );
      case KayloChipVariant.neutral:
        return _ChipColors(
          backgroundColor: baseBg,
          borderColor: baseBorder,
          textColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        );
    }
  }
}

class _ChipColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;

  _ChipColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
  });
}
