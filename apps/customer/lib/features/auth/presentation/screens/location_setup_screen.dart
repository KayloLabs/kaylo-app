import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_core/services/location_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_shadows.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import '../../../../core/widgets/kaylo_map.dart';
import '../../../../core/widgets/use_my_location_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../home/application/user_location_provider.dart';
import '../../../home/presentation/widgets/location_picker_sheet.dart';

/// First-run location capture, right after sign-in. GPS through the
/// shared location service, shown on a map preview; the picker sheet
/// (pin, GPS or search) as the manual path.
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
    final position = resolved == null
        ? null
        : LatLng(resolved.latitude, resolved.longitude);

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
                  padding: EdgeInsets.zero,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Kerala until there is a fix, then the found spot
                      // with a marker; the camera animates between them.
                      KayloMap(
                        center: position ?? keralaCenter,
                        zoom: position == null ? 6.4 : 15,
                        interactive: false,
                        markers: [
                          if (position != null) KayloMapMarker(position),
                        ],
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: resolved == null
                            ? _EmptyHint(
                                key: const ValueKey('empty'),
                                text: l10n.locationWillAppear,
                              )
                            : _ResolvedPanel(
                                key: const ValueKey('resolved'),
                                location: resolved,
                                onLocateAgain: () {
                                  KayloFeedback.tap();
                                  setState(() => _resolved = null);
                                },
                              ),
                      ),
                    ],
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

/// Floating card in the middle of the map before a fix exists.
class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xxl),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.l,
        ),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.surfaceDark : AppColors.surface)
              .withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [AppShadows.getSm(context)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 36, color: secondary),
            const SizedBox(height: AppSpacing.s),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: secondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Address card docked to the bottom of the map once GPS resolved.
class _ResolvedPanel extends StatelessWidget {
  final ResolvedLocation location;
  final VoidCallback onLocateAgain;

  const _ResolvedPanel({
    super.key,
    required this.location,
    required this.onLocateAgain,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final addressLine = location.addressLine;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.m),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.l,
          AppSpacing.l,
          AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.surfaceDark : AppColors.surface)
              .withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [AppShadows.getMd(context)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (addressLine != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          addressLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onLocateAgain,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.locateAgain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
