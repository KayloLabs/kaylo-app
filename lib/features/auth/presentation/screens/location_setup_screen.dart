import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/use_my_location_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../home/application/user_location_provider.dart';
import '../../../home/presentation/widgets/location_picker_sheet.dart';

/// First-run location capture, right after sign-in. GPS through the
/// shared location service; a typed town as the fallback.
class LocationSetupScreen extends ConsumerStatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  ConsumerState<LocationSetupScreen> createState() =>
      _LocationSetupScreenState();
}

class _LocationSetupScreenState extends ConsumerState<LocationSetupScreen> {
  ResolvedLocation? _resolved;

  Future<void> _confirm() async {
    final resolved = _resolved;
    if (resolved != null) {
      await ref
          .read(userLocationProvider.notifier)
          .set(UserLocation.fromResolved(resolved));
    }
    if (mounted) context.go(Routes.dashboard);
  }

  Future<void> _enterManually() async {
    final saved = await showLocationPickerSheet(context);
    if (saved && mounted) context.go(Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final resolved = _resolved;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const Icon(
                Icons.location_on_rounded,
                size: 80,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.enableLocation,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                l10n.enableLocationSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: secondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Expanded(
                child: KayloCard(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: resolved == null
                        ? Column(
                            key: const ValueKey('empty'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 88,
                                color: secondary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: AppSpacing.m),
                              Text(
                                l10n.locationWillAppear,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: secondary),
                              ),
                            ],
                          )
                        : Column(
                            key: const ValueKey('resolved'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.brandPrimary.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.place_rounded,
                                  size: 40,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.l),
                              Text(
                                resolved.label,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (resolved.addressLine != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  resolved.addressLine!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: secondary),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.l),
                              TextButton.icon(
                                onPressed: () {
                                  KayloFeedback.tap();
                                  setState(() => _resolved = null);
                                },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                ),
                                label: Text(l10n.locateAgain),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              if (resolved == null)
                UseMyLocationButton(
                  compact: false,
                  onResolved: (r) => setState(() => _resolved = r),
                )
              else
                KayloButton(
                  text: l10n.continueLabel,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _confirm,
                ),
              const SizedBox(height: AppSpacing.s),
              TextButton(
                onPressed: _enterManually,
                child: Text(l10n.enterManually),
              ),
              TextButton(
                onPressed: () => context.go(Routes.dashboard),
                child: Text(l10n.notNow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
