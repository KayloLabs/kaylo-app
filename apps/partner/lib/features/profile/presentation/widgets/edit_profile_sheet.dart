import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/network/app_failure.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/profile_providers.dart';
import '../../domain/worker_profile.dart';

/// Opens the edit sheet; resolves to true when the profile was saved.
Future<bool> showEditProfileSheet(BuildContext context, WorkerProfile profile) {
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EditProfileSheet(profile: profile),
  ).then((saved) => saved ?? false);
}

/// Name, district, travel radius, services and UPI id. Only the fields the
/// worker changed are sent, so an untouched field is never overwritten.
class EditProfileSheet extends ConsumerStatefulWidget {
  final WorkerProfile profile;

  const EditProfileSheet({super.key, required this.profile});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _radius;
  late final TextEditingController _upi;
  late String? _district;
  late Set<String> _serviceIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p.name);
    _radius = TextEditingController(
      text: p.travelRadiusKm == p.travelRadiusKm.roundToDouble()
          ? p.travelRadiusKm.toInt().toString()
          : p.travelRadiusKm.toString(),
    );
    _upi = TextEditingController(text: p.upiId ?? '');
    _district = p.district;
    _serviceIds = {for (final s in p.services) s.id};
  }

  @override
  void dispose() {
    _name.dispose();
    _radius.dispose();
    _upi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = ref.watch(serviceOptionsProvider);
    final districts = [
      ...keralaDistricts,
      if (_district != null && !keralaDistricts.contains(_district)) _district!,
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.l,
        right: AppSpacing.l,
        top: AppSpacing.m,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.l,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.editProfileTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            KayloTextField(
              label: l10n.fullNameLabel,
              controller: _name,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.m),
            DropdownButtonFormField<String>(
              initialValue: _district,
              decoration: InputDecoration(labelText: l10n.districtLabel),
              items: [
                for (final d in districts)
                  DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: (value) => setState(() => _district = value),
            ),
            const SizedBox(height: AppSpacing.m),
            KayloTextField(
              label: l10n.travelRadiusLabel,
              controller: _radius,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.m),
            KayloTextField(
              label: l10n.upiIdLabel,
              controller: _upi,
              hintText: 'name@bank',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              l10n.servicesLabel,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.s),
            options.when(
              loading: () => const Center(child: KayloLoader(size: 28)),
              error: (e, _) => Text(
                e is AppFailure ? e.message : '$e',
                style: const TextStyle(color: AppColors.error),
              ),
              data: (list) => Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  for (final option in list)
                    FilterChip(
                      label: Text(option.name),
                      selected: _serviceIds.contains(option.id),
                      selectedColor: AppColors.brandPrimary.withValues(
                        alpha: isDark ? 0.3 : 0.15,
                      ),
                      checkmarkColor: AppColors.brandPrimary,
                      onSelected: (selected) {
                        KayloFeedback.tap();
                        setState(() {
                          if (selected) {
                            _serviceIds.add(option.id);
                          } else {
                            _serviceIds.remove(option.id);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            KayloButton(
              text: l10n.save,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final p = widget.profile;

    final name = _name.text.trim();
    if (name.isEmpty) {
      KayloSnackbar.showError(context, l10n.nameRequired);
      return;
    }
    final radius = double.tryParse(_radius.text.trim());
    if (radius == null || radius < 1 || radius > 100) {
      KayloSnackbar.showError(context, l10n.radiusRange);
      return;
    }
    final upi = _upi.text.trim();
    if (upi.isNotEmpty && !upiIdPattern.hasMatch(upi)) {
      KayloSnackbar.showError(context, l10n.invalidUpi);
      return;
    }
    if (_serviceIds.isEmpty) {
      KayloSnackbar.showError(context, l10n.chooseOneService);
      return;
    }

    final currentIds = {for (final s in p.services) s.id};
    final edit = WorkerProfileEdit(
      name: name == p.name ? null : name,
      district: _district == p.district ? null : _district,
      travelRadiusKm: radius == p.travelRadiusKm ? null : radius,
      upiId: upi == (p.upiId ?? '') ? null : upi,
      serviceIds:
          _serviceIds.length == currentIds.length &&
              _serviceIds.containsAll(currentIds)
          ? null
          : _serviceIds.toList(),
    );
    if (edit.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(workerProfileRepositoryProvider).updateProfile(edit);
      if (!mounted) return;
      KayloFeedback.press();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      KayloSnackbar.showError(
        context,
        e is AppFailure
            ? e.message
            : e is ArgumentError
            ? '${e.message}'
            : '$e',
      );
    }
  }
}
