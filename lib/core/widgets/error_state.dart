import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'kaylo_button.dart';

class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    this.title = 'Oops! Something went wrong',
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              message,
              style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            KayloButton(
              text: 'Try Again',
              onPressed: onRetry,
              variant: KayloButtonVariant.outline,
            ),
          ],
        ),
      ),
    );
  }
}
