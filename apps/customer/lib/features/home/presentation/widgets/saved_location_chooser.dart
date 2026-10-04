import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import '../../../../core/widgets/use_my_location_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../profile/application/addresses_providers.dart';
import '../../../profile/presentation/screens/saved_addresses_screen.dart';
import '../../application/user_location_provider.dart';
import 'location_picker_sheet.dart';

/// Shared by the dashboard and checkout. Only the dashboard caller persists
/// the result as the active place; cancelling a booking picker changes nothing.
Future<UserLocation?> showSavedLocationChooser(
  BuildContext context, {
  UserLocation? initialLocation,
}) => showModalBottomSheet<UserLocation>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  clipBehavior: Clip.antiAlias,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => _SavedLocationChooser(initialLocation: initialLocation),
);

class _SavedLocationChooser extends ConsumerWidget {
  final UserLocation? initialLocation;
  const _SavedLocationChooser({this.initialLocation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final UserLocation selected =
        initialLocation ?? ref.watch(userLocationProvider);
    final addresses = ref.watch(savedAddressesProvider);
    final theme = Theme.of(context);

    void choose(UserLocation value) {
      KayloFeedback.tap();
      Navigator.of(context).pop(value);
    }

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.yourLocation,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            UseMyLocationButton(
              onResolved: (value) => choose(UserLocation.fromResolved(value)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.map_outlined,
                color: AppColors.brandPrimary,
              ),
              title: Text(l10n.selectOnMap),
              subtitle: Text(l10n.moveMapToPlacePin),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final value = await showMapLocationPickerSheet(
                  context,
                  initialLocation: selected,
                );
                if (value != null && context.mounted) choose(value);
              },
            ),
            const Divider(height: 28),
            Text(
              l10n.savedAddresses,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            addresses.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, _) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.somethingWentWrong),
                trailing: IconButton(
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).refreshIndicatorSemanticLabel,
                  onPressed: () => ref.invalidate(savedAddressesProvider),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              data: (items) => items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        l10n.noAddressesDescription,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : Column(
                      children: [
                        for (final address in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Semantics(
                              selected: selected.savedAddressId == address.id,
                              child: Material(
                                color: selected.savedAddressId == address.id
                                    ? AppColors.brandPrimary.withValues(
                                        alpha: .09,
                                      )
                                    : Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                    color: selected.savedAddressId == address.id
                                        ? AppColors.brandPrimary.withValues(
                                            alpha: .4,
                                          )
                                        : theme.dividerColor,
                                  ),
                                ),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  leading: Icon(
                                    addressIcon(address.label),
                                    color: AppColors.brandPrimary,
                                  ),
                                  title: Text(
                                    address.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    address.line,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Icon(
                                    selected.savedAddressId == address.id
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: selected.savedAddressId == address.id
                                        ? AppColors.brandPrimary
                                        : theme.hintColor,
                                  ),
                                  onTap: () => choose(
                                    UserLocation.fromSavedAddress(address),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final saved = await showAddAddressSheet(context);
                if (saved != null && context.mounted) {
                  choose(UserLocation.fromSavedAddress(saved));
                }
              },
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(l10n.addAddress),
            ),
          ],
        ),
      ),
    );
  }
}
