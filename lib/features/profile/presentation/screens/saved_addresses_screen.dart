import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/feedback_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/kaylo_chip.dart';
import '../../../../core/widgets/kaylo_loader.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';
import '../../../../core/widgets/kaylo_text_field.dart';
import '../../../../core/widgets/use_my_location_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/addresses_providers.dart';
import '../../domain/saved_address.dart';

class SavedAddressesScreen extends ConsumerWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final addresses = ref.watch(savedAddressesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.savedAddresses)),
      body: addresses.when(
        data: (list) => list.isEmpty
            ? EmptyState(
                title: l10n.noAddressesTitle,
                description: l10n.noAddressesDescription,
                icon: Icons.location_on_outlined,
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  AppSpacing.m,
                  AppSpacing.l,
                  140,
                ),
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.m),
                itemBuilder: (context, index) =>
                    _AddressCard(address: list[index]),
              ),
        loading: () => const Center(child: KayloLoader()),
        error: (error, _) => ErrorState(
          title: l10n.somethingWentWrong,
          message: error.toString(),
          onRetry: () => ref.invalidate(savedAddressesProvider),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.l,
          120, // above the floating bottom nav
        ),
        child: KayloButton(
          text: l10n.addAddress,
          icon: Icons.add_location_alt_rounded,
          onPressed: () {
            KayloFeedback.tap();
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const _AddAddressSheet(),
            );
          },
        ),
      ),
    );
  }
}

IconData addressIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('home') || l.contains('house')) return Icons.home_rounded;
  if (l.contains('farm')) return Icons.agriculture_rounded;
  if (l.contains('work') || l.contains('office')) return Icons.work_rounded;
  return Icons.place_rounded;
}

class _AddressCard extends ConsumerWidget {
  final SavedAddress address;

  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return KayloCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.m,
        AppSpacing.xs,
        AppSpacing.m,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(addressIcon(address.label),
                color: AppColors.brandPrimary),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        address.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: AppSpacing.s),
                      KayloChip(
                        label: l10n.defaultLabel,
                        icon: Icons.check_rounded,
                        variant: KayloChipVariant.success,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  address.line,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              KayloFeedback.tap();
              final controller = ref.read(addressesControllerProvider);
              if (value == 'default') await controller.setDefault(address.id);
              if (value == 'remove') await controller.remove(address.id);
            },
            itemBuilder: (context) => [
              if (!address.isDefault)
                PopupMenuItem(value: 'default', child: Text(l10n.setAsDefault)),
              PopupMenuItem(
                value: 'remove',
                child: Text(
                  l10n.removeAddress,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddAddressSheet extends ConsumerStatefulWidget {
  const _AddAddressSheet();

  @override
  ConsumerState<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<_AddAddressSheet> {
  static const _presets = ['Home', 'Farm', 'Work'];
  String _label = 'Home';
  final _customLabel = TextEditingController();
  final _line = TextEditingController();
  double? _lat;
  double? _lng;
  bool _saving = false;

  bool get _isCustom => !_presets.contains(_label);

  @override
  void dispose() {
    _customLabel.dispose();
    _line.dispose();
    super.dispose();
  }

  String _presetLabel(AppLocalizations l10n, String preset) => switch (preset) {
        'Home' => l10n.labelHome,
        'Farm' => l10n.labelFarm,
        'Work' => l10n.labelWork,
        _ => l10n.labelOther,
      };

  void _applyLocation(ResolvedLocation resolved) {
    setState(() {
      _line.text = resolved.addressLine ?? resolved.label;
      _lat = resolved.latitude;
      _lng = resolved.longitude;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final line = _line.text.trim();
    final label = _isCustom ? _customLabel.text.trim() : _presetLabel(l10n, _label);
    if (line.isEmpty) {
      KayloSnackbar.showError(context, l10n.addressRequired);
      return;
    }
    if (label.isEmpty) {
      KayloSnackbar.showError(context, l10n.nameRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(addressesControllerProvider).add(
            label: label,
            line: line,
            latitude: _lat,
            longitude: _lng,
          );
      if (!mounted) return;
      KayloFeedback.press();
      Navigator.of(context).pop();
      KayloSnackbar.showSuccess(context, l10n.addressSaved);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        KayloSnackbar.showError(context, l10n.somethingWentWrong);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.addAddress, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.l),
            Text(
              l10n.addressLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: AppSpacing.s,
              children: [
                for (final preset in [..._presets, 'Other'])
                  ChoiceChip(
                    avatar: Icon(addressIcon(preset), size: 18),
                    label: Text(_presetLabel(l10n, preset)),
                    selected: _label == preset,
                    showCheckmark: false,
                    onSelected: (_) {
                      KayloFeedback.tap();
                      setState(() => _label = preset);
                    },
                  ),
              ],
            ),
            if (_isCustom) ...[
              const SizedBox(height: AppSpacing.m),
              KayloTextField(
                label: l10n.addressLabel,
                hintText: l10n.labelOtherHint,
                controller: _customLabel,
              ),
            ],
            const SizedBox(height: AppSpacing.m),
            KayloTextField(
              label: l10n.addressLine,
              hintText: l10n.farmAddressHint,
              controller: _line,
              prefixIcon: const Icon(Icons.pin_drop_rounded),
            ),
            const SizedBox(height: AppSpacing.s),
            Align(
              alignment: Alignment.centerLeft,
              child: UseMyLocationButton(onResolved: _applyLocation),
            ),
            const SizedBox(height: AppSpacing.xl),
            KayloButton(text: l10n.save, isLoading: _saving, onPressed: _save),
            const SizedBox(height: AppSpacing.s),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
