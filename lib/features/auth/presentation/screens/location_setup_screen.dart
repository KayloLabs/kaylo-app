import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';
import '../../../../l10n/generated/app_localizations.dart';

class LocationSetupScreen extends ConsumerWidget {
  const LocationSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Icon(
                Icons.location_on_rounded,
                size: 80,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Enable Location',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Kaylo needs your location to show services and professionals near you.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Expanded(
                child: KayloCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 100,
                            color: isDark ? Colors.grey[700] : Colors.grey[400],
                          ),
                          // KayloButton fills its parent's width, so the
                          // Positioned must bound it horizontally: with only
                          // `bottom` set it gets unconstrained width, fails
                          // layout, and breaks hit testing for the whole
                          // screen (every button goes dead).
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 20,
                            child: KayloButton(
                              text: 'Pick Manually',
                              variant: KayloButtonVariant.secondary,
                              onPressed: () => KayloSnackbar.showInfo(
                                context,
                                AppLocalizations.of(context)!.comingSoon,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              KayloButton(
                text: 'Enable Location',
                onPressed: () => context.go(Routes.dashboard),
              ),
              const SizedBox(height: AppSpacing.m),
              TextButton(
                onPressed: () => context.go(Routes.dashboard),
                child: const Text('Not now'),
              ),
              const SizedBox(height: AppSpacing.l),
            ],
          ),
        ),
      ),
    );
  }
}
