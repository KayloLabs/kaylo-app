import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/feedback_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class LanguageSelectorSheet extends ConsumerWidget {
  const LanguageSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.languageSettings,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            _buildLanguageOption(context, ref, 'English', 'en', currentLocale.languageCode),
            _buildLanguageOption(context, ref, 'മലയാളം (Malayalam)', 'ml', currentLocale.languageCode),
            _buildLanguageOption(context, ref, 'हिंदी (Hindi)', 'hi', currentLocale.languageCode),
            _buildLanguageOption(context, ref, 'தமிழ் (Tamil)', 'ta', currentLocale.languageCode),
            const SizedBox(height: AppSpacing.l),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, WidgetRef ref, String title, String code, String currentCode) {
    final isSelected = code == currentCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: () {
        KayloFeedback.tap();
        ref.read(localeProvider.notifier).setLocale(code);
        Navigator.pop(context);
      },
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected 
              ? AppColors.brandPrimary 
              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.brandPrimary)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: isSelected 
          ? AppColors.brandPrimary.withValues(alpha: 0.1) 
          : Colors.transparent,
    );
  }
}
