import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaylo_core/models/service_item.dart';
import '../../../../core/router/routes.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_core/utils/money.dart';
import 'package:kaylo_ui/widgets/error_state.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';
import 'package:kaylo_ui/widgets/price_tag.dart';
import '../../../../core/widgets/use_my_location_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../profile/application/addresses_providers.dart';
import '../../application/farm_providers.dart';
import '../../domain/farm_booking_draft.dart';
import '../../domain/farm_service_info.dart';
import '../widgets/farm_labels.dart';
import '../widgets/quantity_stepper.dart';

/// Schedule step of checkout. Serves every category: the farm flow
/// reaches it from the service details page, the home flow from a
/// worker list or profile (which also pins [workerId]).
class FarmScheduleScreen extends ConsumerWidget {
  final String serviceId;
  final String? workerId;

  const FarmScheduleScreen({super.key, required this.serviceId, this.workerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref
        .watch(farmServiceProvider(serviceId))
        .when(
          data: (service) =>
              _ScheduleForm(service: service, workerId: workerId),
          loading: () => Scaffold(
            appBar: AppBar(),
            body: const Center(child: KayloLoader()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(),
            body: ErrorState(
              title: l10n.somethingWentWrong,
              message: error.toString(),
              onRetry: () => ref.invalidate(farmServiceProvider(serviceId)),
            ),
          ),
        );
  }
}

class _ScheduleForm extends ConsumerStatefulWidget {
  final ServiceItem service;
  final String? workerId;

  const _ScheduleForm({required this.service, this.workerId});

  @override
  ConsumerState<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends ConsumerState<_ScheduleForm> {
  late FarmBookingDraft _draft;
  final _addressController = TextEditingController();

  FarmServiceInfo get _info => farmInfoFor(widget.service);
  bool get _isFarm => widget.service.category == 'farm';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _draft = FarmBookingDraft(
      service: widget.service,
      date: DateTime(now.year, now.month, now.day + 1),
      slot: FarmTimeSlot.all[1],
      // Trees are booked by the dozen or so, hourly work by the morning,
      // and a tradesperson's callout is one visit.
      quantity: switch (_info.unit) {
        FarmUnit.tree => 10,
        FarmUnit.hour => 2,
        FarmUnit.visit => 1,
      },
      address: '',
      workerId: widget.workerId,
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _draft = _draft.copyWith(date: picked));
  }

  void _continue() {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      KayloSnackbar.showError(
        context,
        _isFarm ? l10n.addressRequired : l10n.serviceAddressRequired,
      );
      return;
    }
    context.push(
      Routes.farmPayment(widget.service.id),
      extra: _draft.copyWith(address: address),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = MaterialLocalizations.of(context);
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final labelStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final unit = _info.unit;
    final accent = _isFarm ? AppColors.farmAccent : AppColors.brandPrimary;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scheduleTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.l,
          AppSpacing.xxl,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Image.asset(widget.service.iconPath, width: 40, height: 40),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    widget.service.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PriceTag(
                  amount: widget.service.basePrice,
                  suffix: l10n.perUnit(farmUnitLabel(l10n, unit)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          Text(l10n.selectDate, style: labelStyle),
          const SizedBox(height: AppSpacing.s),
          KayloCard(
            onTap: _pickDate,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.m,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: accent, size: 20),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    loc.formatFullDate(_draft.date),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  l10n.change,
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text(l10n.selectTimeSlot, style: labelStyle),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final slot in FarmTimeSlot.all)
                ChoiceChip(
                  label: Text(formatTimeSlot(context, slot)),
                  selected: identical(slot, _draft.slot),
                  showCheckmark: false,
                  selectedColor: AppColors.brandPrimary,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: identical(slot, _draft.slot)
                        ? Colors.white
                        : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary),
                  ),
                  shape: const StadiumBorder(),
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                  onSelected: (_) {
                    KayloFeedback.tap();
                    setState(() => _draft = _draft.copyWith(slot: slot));
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          Text(l10n.quantity, style: labelStyle),
          const SizedBox(height: AppSpacing.s),
          KayloCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      farmUnitCount(l10n, unit, _draft.quantity),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.priceEach(formatRupees(widget.service.basePrice)),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: secondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),
                QuantityStepper(
                  value: _draft.quantity,
                  onChanged: (value) =>
                      setState(() => _draft = _draft.copyWith(quantity: value)),
                ),
                const SizedBox(height: AppSpacing.l),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.m),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.calculation,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: secondary),
                          ),
                          Text(
                            l10n.breakdown(
                              formatRupees(widget.service.basePrice),
                              farmUnitCount(l10n, unit, _draft.quantity),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    PriceTag(amount: _draft.total, isLarge: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          KayloTextField(
            label: _isFarm ? l10n.farmAddress : l10n.serviceAddress,
            hintText: l10n.farmAddressHint,
            controller: _addressController,
            prefixIcon: const Icon(Icons.pin_drop_rounded),
          ),
          const SizedBox(height: AppSpacing.s),
          // GPS and the customer's saved addresses fill the field in one
          // tap; typing stays available for a one-off place.
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              UseMyLocationButton(
                onResolved: (resolved) => setState(() {
                  _addressController.text =
                      resolved.addressLine ?? resolved.label;
                }),
              ),
              for (final address
                  in ref
                          .watch(savedAddressesProvider)
                          .whenOrNull(data: (list) => list) ??
                      const [])
                ActionChip(
                  avatar: Icon(_addressIcon(address.label), size: 18),
                  label: Text(address.label),
                  onPressed: () {
                    KayloFeedback.tap();
                    setState(() => _addressController.text = address.line);
                  },
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.l,
          AppSpacing.l,
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.total,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: secondary),
                ),
                PriceTag(amount: _draft.total, isLarge: true),
              ],
            ),
            const SizedBox(width: AppSpacing.l),
            Expanded(
              child: KayloButton(
                text: l10n.continueToPayment,
                icon: Icons.arrow_forward_rounded,
                onPressed: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _addressIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('home') || l.contains('house')) return Icons.home_rounded;
  if (l.contains('farm')) return Icons.agriculture_rounded;
  if (l.contains('work') || l.contains('office')) return Icons.work_rounded;
  return Icons.place_rounded;
}
