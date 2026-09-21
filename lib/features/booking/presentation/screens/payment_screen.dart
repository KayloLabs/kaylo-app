import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';
import '../../../../core/widgets/price_tag.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../services/domain/service_info.dart';
import '../../../services/presentation/widgets/service_labels.dart';
import '../../application/checkout_controller.dart';
import '../../domain/booking_draft.dart';
import '../../domain/booking_receipt.dart';
import '../../domain/payment_method.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  /// Null when the route was reached without a draft (deep link, reload);
  /// the screen then offers a way back instead of crashing.
  final BookingDraft? draft;

  const PaymentScreen({super.key, required this.draft});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.upi;

  Future<void> _confirm(BookingDraft draft) async {
    final l10n = AppLocalizations.of(context)!;
    final unit = serviceInfoFor(draft.service).unit;
    final isFarm = draft.service.category == 'farm';

    final booking = await ref
        .read(checkoutControllerProvider.notifier)
        .confirm(draft: draft, method: _method);
    if (!mounted) return;

    if (booking == null) {
      KayloFeedback.alert();
      KayloSnackbar.showError(context, l10n.paymentFailed);
      return;
    }

    KayloFeedback.press();
    context.go(
      Routes.bookingConfirmation,
      extra: BookingReceipt(
        booking: booking,
        service: draft.service,
        paymentMethod: _method,
        extras: [
          ReceiptLine(
              l10n.quantity, serviceUnitCount(l10n, unit, draft.quantity)),
          ReceiptLine(
              isFarm ? l10n.farmAddress : l10n.serviceAddress, draft.address),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = widget.draft;

    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.paymentTitle)),
        body: ErrorState(
          title: l10n.somethingWentWrong,
          message: l10n.draftMissing,
          onRetry: () => context.go(Routes.services('all')),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = MaterialLocalizations.of(context);
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final unit = serviceInfoFor(draft.service).unit;
    final isFarm = draft.service.category == 'farm';
    final isProcessing = ref.watch(checkoutControllerProvider).isLoading;

    Widget summaryRow(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: secondary),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.l,
          AppSpacing.xxl,
        ),
        children: [
          SectionHeader(title: l10n.orderSummary),
          const SizedBox(height: AppSpacing.m),
          KayloCard(
            child: Column(
              children: [
                summaryRow(l10n.service, draft.service.name),
                summaryRow(l10n.date, loc.formatMediumDate(draft.date)),
                summaryRow(l10n.time, formatTimeSlot(context, draft.slot)),
                summaryRow(
                    l10n.quantity, serviceUnitCount(l10n, unit, draft.quantity)),
                summaryRow(
                  l10n.rate,
                  '${formatRupees(draft.service.basePrice)} '
                  '${l10n.perUnit(serviceUnitLabel(l10n, unit))}',
                ),
                summaryRow(
                    isFarm ? l10n.farmAddress : l10n.serviceAddress, draft.address),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.totalPayable,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    PriceTag(amount: draft.total, isLarge: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          SectionHeader(title: l10n.paymentMethod),
          const SizedBox(height: AppSpacing.m),
          _PaymentOption(
            method: PaymentMethod.upi,
            selected: _method,
            icon: Icons.account_balance_wallet_rounded,
            title: l10n.payUpi,
            subtitle: l10n.payUpiSubtitle,
            onSelect: (m) => setState(() => _method = m),
          ),
          const SizedBox(height: AppSpacing.s),
          _PaymentOption(
            method: PaymentMethod.card,
            selected: _method,
            icon: Icons.credit_card_rounded,
            title: l10n.payCard,
            subtitle: l10n.payCardSubtitle,
            onSelect: (m) => setState(() => _method = m),
          ),
          const SizedBox(height: AppSpacing.s),
          _PaymentOption(
            method: PaymentMethod.payAfterService,
            selected: _method,
            icon: Icons.payments_rounded,
            title: l10n.payAfter,
            subtitle: l10n.payAfterSubtitle,
            onSelect: (m) => setState(() => _method = m),
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
        child: KayloButton(
          text: _method == PaymentMethod.payAfterService
              ? l10n.confirmBooking
              : l10n.confirmAndPay(formatRupees(draft.total)),
          icon: Icons.lock_rounded,
          isLoading: isProcessing,
          onPressed: () => _confirm(draft),
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final PaymentMethod method;
  final PaymentMethod selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<PaymentMethod> onSelect;

  const _PaymentOption({
    required this.method,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = method == selected;
    final border = isSelected
        ? AppColors.brandPrimary
        : (isDark ? AppColors.borderDark : AppColors.border);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.brandPrimary.withValues(alpha: isDark ? 0.18 : 0.08)
            : (isDark ? AppColors.surfaceDark : AppColors.surface),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: isSelected ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            KayloFeedback.tap();
            onSelect(method);
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Row(
              children: [
                Icon(icon, color: AppColors.brandPrimary),
                const SizedBox(width: AppSpacing.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected
                      ? AppColors.brandPrimary
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
