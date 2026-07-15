import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double size;

  const RatingStars({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.star, color: AppColors.farmAccent, size: size),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount reviews)',
            style: TextStyle(
              fontSize: size - 2,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ]
      ],
    );
  }
}
