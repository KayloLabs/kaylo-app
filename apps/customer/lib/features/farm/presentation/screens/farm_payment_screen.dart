import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_core/utils/money.dart';
import 'package:kaylo_ui/widgets/error_state.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';
import 'package:kaylo_core/network/app_failure.dart';
import 'package:kaylo_ui/widgets/price_tag.dart';
import 'package:kaylo_ui/widgets/section_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../booking/domain/booking_receipt.dart';
import '../../../auth/application/current_user_provider.dart';
import '../../../booking/domain/payment_method.dart';
import '../../../workers/application/workers_providers.dart';
import '../../application/farm_providers.dart';
import '../../domain/farm_booking_draft.dart';
import '../../domain/farm_service_info.dart';
import '../widgets/farm_labels.dart';
import '../../../offers/domain/kaylo_offer.dart';
import '../../../offers/presentation/offers_screen.dart';

class FarmPaymentScreen extends ConsumerStatefulWidget {
  /// Null when the route was reached without a draft (deep link, reload);
  /// the screen then offers a way back instead of crashing.
  final FarmBookingDraft? draft;

  const FarmPaymentScreen({super.key, required this.draft});

  @override
  ConsumerState<FarmPaymentScreen> createState() => _FarmPaymentScreenState();
}

class _FarmPaymentScreenState extends ConsumerState<FarmPaymentScreen> {
  PaymentMethod _method = PaymentMethod.online;
  KayloOffer? _offer;
  double _payable(FarmBookingDraft draft) =>
      draft.total -
      (_offer?.savings(draft.total, category: draft.service.category) ?? 0);

  /// Where the invoice goes. Prefilled from the profile; people who
  /// signed up by phone have none, so they type one here.
  final _email = TextEditingController();
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void initState() {
    super.initState();
    _email.text = ref.read(currentUserProvider)?.email ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  /// Name of the worker the customer picked, once loaded; null when none
  /// was picked or the lookup has not finished.
  String? _workerName(FarmBookingDraft draft) {
    final id = draft.workerId;
    if (id == null) return null;
    return ref.watch(workerDetailProvider(id)).whenOrNull(data: (w) => w.name);
  }

  Future<void> _confirm(FarmBookingDraft draft) async {
    final l10n = AppLocalizations.of(context)!;
    final unit = farmInfoFor(draft.service).unit;
    final isFarm = draft.service.category == 'farm';
    final workerName = _workerName(draft);

    final online = _method != PaymentMethod.payAfterService;
    final email = _email.text.trim().toLowerCase();
    final emailOk = _emailPattern.hasMatch(email);
    if (online && !emailOk) {
      KayloSnackbar.showError(context, l10n.invoiceEmailRequired);
      return;
    }

    final booking = await ref
        .read(farmCheckoutControllerProvider.notifier)
        .confirm(
          draft: draft,
          method: _method,
          email: emailOk ? email : null,
          offerCode:
              _offer?.appliesTo(
                    draft.total,
                    category: draft.service.category,
                  ) ==
                  true
              ? _offer!.code
              : null,
        );
    if (!mounted) return;

    if (booking == null) {
      KayloFeedback.alert();
      final error = ref.read(farmCheckoutControllerProvider).error;
      KayloSnackbar.showError(
        context,
        error is AppFailure ? error.message : l10n.paymentFailed,
      );
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
          if (workerName != null) ReceiptLine(l10n.worker, workerName),
          ReceiptLine(l10n.quantity, farmUnitCount(l10n, unit, draft.quantity)),
          ReceiptLine(
            isFarm ? l10n.farmAddress : l10n.serviceAddress,
            draft.address,
          ),
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
          onRetry: () => context.go(Routes.farm),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = MaterialLocalizations.of(context);
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final unit = farmInfoFor(draft.service).unit;
    final isFarm = draft.service.category == 'farm';
    final workerName = _workerName(draft);
    final isProcessing = ref.watch(farmCheckoutControllerProvider).isLoading;
    final savedMethod = ref.watch(defaultPaymentMethodProvider);

    Widget summaryRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: secondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
                if (workerName != null) summaryRow(l10n.worker, workerName),
                summaryRow(l10n.date, loc.formatMediumDate(draft.date)),
                summaryRow(l10n.time, formatTimeSlot(context, draft.slot)),
                summaryRow(
                  l10n.quantity,
                  farmUnitCount(l10n, unit, draft.quantity),
                ),
                summaryRow(
                  l10n.rate,
                  '${formatRupees(draft.service.basePrice)} '
                  '${l10n.perUnit(farmUnitLabel(l10n, unit))}',
                ),
                summaryRow(
                  isFarm ? l10n.farmAddress : l10n.serviceAddress,
                  draft.address,
                ),
                if ((_offer?.savings(
                          draft.total,
                          category: draft.service.category,
                        ) ??
                        0) >
                    0) ...[
                  summaryRow('Subtotal', formatRupees(draft.total)),
                  summaryRow(
                    'Offer • ${_offer!.code}',
                    '−${formatRupees(_offer!.discount)}',
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.totalPayable,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    PriceTag(amount: _payable(draft), isLarge: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          OfferSelector(
            subtotal: draft.total,
            category: draft.service.category,
            selected: _offer,
            enabled:
                !isProcessing &&
                !ref
                    .read(farmCheckoutControllerProvider.notifier)
                    .hasStartedPayment,
            onChanged: (offer) => setState(() => _offer = offer),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: l10n.paymentMethod),
          const SizedBox(height: AppSpacing.m),
          _PaymentOption(
            method: PaymentMethod.online,
            selected: _method,
            icon: Icons.lock_rounded,
            title: l10n.payNow,
            subtitle: l10n.payNowSubtitle,
            onSelect: (m) => setState(() => _method = m),
          ),
          if (_method == PaymentMethod.online && savedMethod != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
              child: Row(
                children: [
                  Icon(
                    savedMethod.type.isUpi
                        ? Icons.account_balance_wallet_rounded
                        : Icons.credit_card_rounded,
                    size: 16,
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      '${savedMethod.label} (${savedMethod.detail})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: secondary,
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(Routes.paymentMethods),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Change', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s),
          _PaymentOption(
            method: PaymentMethod.payAfterService,
            selected: _method,
            icon: Icons.payments_rounded,
            title: l10n.payAfter,
            subtitle: l10n.payAfterSubtitle,
            onSelect: (m) => setState(() => _method = m),
          ),
          const SizedBox(height: AppSpacing.xl),
          KayloTextField(
            label: _method == PaymentMethod.payAfterService
                ? l10n.confirmationEmail
                : l10n.invoiceEmail,
            hintText: 'you@example.com',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            prefixIcon: const Icon(Icons.receipt_long_rounded),
          ),
          const SizedBox(height: AppSpacing.xxl),
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
              : l10n.confirmAndPay(formatRupees(_payable(draft))),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
