import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/kaylo_liquid_glass.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../l10n/generated/app_localizations.dart';

class BottomPromoBanner extends StatelessWidget {
  const BottomPromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return KayloLiquidGlass(
      borderRadius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          Image.asset(
            'assets_kaylo/3d_transparent/promo_calendar.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.promoTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.promoSubtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: AppSpacing.s),
                KayloButton(
                  text: AppLocalizations.of(context)!.promoButton,
                  // Reminders live in Kaylo Care — route there until M5's
                  // dedicated reminders screen lands.
                  onPressed: () => context.go(Routes.careHome),
                  icon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
