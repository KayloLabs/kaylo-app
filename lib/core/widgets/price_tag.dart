import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PriceTag extends StatelessWidget {
  final double amount;
  final String? prefix;
  final String? suffix;
  final bool isLarge;

  const PriceTag({
    super.key,
    required this.amount,
    this.prefix = '₹',
    this.suffix,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = isLarge
        ? Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.brandPrimary,
          )
        : Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.brandPrimary,
          );

    return Text.rich(
      TextSpan(
        children: [
          if (prefix != null) TextSpan(text: prefix),
          TextSpan(text: amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)),
          if (suffix != null) TextSpan(
            text: ' $suffix',
            style: TextStyle(
              fontSize: isLarge ? 14 : 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      style: style,
    );
  }
}
