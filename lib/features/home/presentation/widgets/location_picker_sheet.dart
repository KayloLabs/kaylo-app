import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';
import '../../../../core/widgets/kaylo_text_field.dart';
import '../../../../core/widgets/use_my_location_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/user_location_provider.dart';

/// Lets the customer set their active location by GPS or by typing a
/// town. Resolves true when a location was saved.
Future<bool> showLocationPickerSheet(BuildContext context) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    // Over the whole app so the floating bottom nav stays underneath.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const LocationPickerSheet(),
  );
  return saved ?? false;
}

class LocationPickerSheet extends ConsumerStatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  ConsumerState<LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<LocationPickerSheet> {
  final _town = TextEditingController();

  @override
  void dispose() {
    _town.dispose();
    super.dispose();
  }

  Future<void> _finish(UserLocation location) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(userLocationProvider.notifier).set(location);
    if (!mounted) return;
    KayloFeedback.press();
    Navigator.of(context).pop(true);
    KayloSnackbar.showSuccess(context, l10n.locationUpdated(location.label));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = ref.watch(userLocationProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.yourLocation, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.place_rounded,
                  size: 18, color: AppColors.brandPrimary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  current.addressLine ?? current.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          UseMyLocationButton(
            compact: false,
            onResolved: (resolved) =>
                _finish(UserLocation.fromResolved(resolved)),
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: Text(
                  l10n.or,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          KayloTextField(
            label: l10n.townOrCity,
            hintText: l10n.townHint,
            controller: _town,
            prefixIcon: const Icon(Icons.edit_location_alt_rounded),
          ),
          const SizedBox(height: AppSpacing.l),
          KayloButton(
            text: l10n.saveLocation,
            variant: KayloButtonVariant.secondary,
            onPressed: () {
              final town = _town.text.trim();
              if (town.isEmpty) {
                KayloSnackbar.showError(context, l10n.townRequired);
                return;
              }
              _finish(UserLocation(label: town));
            },
          ),
        ],
      ),
    );
  }
}
