import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import 'package:kaylo_core/services/sound_service.dart';
import 'package:kaylo_ui/widgets/google_pay_tick.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_core/utils/money.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/booking_receipt.dart';
import '../widgets/booking_labels.dart';

/// Final step of every booking flow. Back navigation is deliberately
/// disabled: the payment is done, so "back" means the dashboard.
class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final BookingReceipt? receipt;

  const BookingConfirmationScreen({super.key, required this.receipt});

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.receipt == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.dashboard);
      });
    } else {
      ref.read(soundServiceProvider).playSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipt = widget.receipt;
    if (receipt == null) return const Scaffold();

    final l10n = AppLocalizations.of(context)!;
    final loc = MaterialLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final booking = receipt.booking;
    final scheduledTime = TimeOfDay.fromDateTime(booking.scheduledAt);

    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
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
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );

    Widget text(String value, {bool bold = false}) => Text(
      value,
      textAlign: TextAlign.end,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.dashboard);
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxxl,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            children: [
              const Center(
                child: GooglePayTick(size: 104, color: AppColors.brandPrimary),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.bookingConfirmed,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                l10n.bookingConfirmedSubtitle(
                  loc.formatFullDate(booking.scheduledAt),
                  loc.formatTimeOfDay(scheduledTime),
                ),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: secondary, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.xxl),
              KayloCard(
                child: Column(
                  children: [
                    row(l10n.bookingId, text(booking.id, bold: true)),
                    const Divider(height: 1),
                    row(l10n.service, text(receipt.service.name)),
                    for (final line in receipt.extras)
                      row(line.label, text(line.value)),
                    row(
                      l10n.total,
                      text(formatRupees(booking.totalAmount), bold: true),
                    ),
                    row(
                      l10n.payment,
                      text(paymentMethodLabel(l10n, receipt.paymentMethod)),
                    ),
                    row(l10n.status, BookingStatusChip(status: booking.status)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              KayloButton(
                text: l10n.viewMyBookings,
                icon: Icons.event_available_rounded,
                onPressed: () => context.go(Routes.bookings),
              ),
              const SizedBox(height: AppSpacing.m),
              KayloButton(
                text: l10n.backToHome,
                variant: KayloButtonVariant.outline,
                onPressed: () => context.go(Routes.dashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
