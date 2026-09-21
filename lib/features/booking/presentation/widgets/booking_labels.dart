import 'package:flutter/material.dart';

import '../../../../core/models/booking.dart';
import '../../../../core/widgets/kaylo_chip.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/payment_method.dart';

String bookingStatusLabel(AppLocalizations l10n, BookingStatus status) =>
    switch (status) {
      BookingStatus.pending => l10n.statusPending,
      BookingStatus.confirmed => l10n.statusConfirmed,
      BookingStatus.inProgress => l10n.statusInProgress,
      BookingStatus.completed => l10n.statusCompleted,
      BookingStatus.cancelled => l10n.statusCancelled,
    };

String paymentMethodLabel(AppLocalizations l10n, PaymentMethod method) =>
    switch (method) {
      PaymentMethod.upi => l10n.payUpi,
      PaymentMethod.card => l10n.payCard,
      PaymentMethod.payAfterService => l10n.payAfter,
    };

class BookingStatusChip extends StatelessWidget {
  final BookingStatus status;

  const BookingStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (variant, icon) = switch (status) {
      BookingStatus.pending => (KayloChipVariant.warning, Icons.schedule_rounded),
      BookingStatus.confirmed => (KayloChipVariant.brand, Icons.check_rounded),
      BookingStatus.inProgress =>
        (KayloChipVariant.brand, Icons.autorenew_rounded),
      BookingStatus.completed =>
        (KayloChipVariant.success, Icons.task_alt_rounded),
      BookingStatus.cancelled => (KayloChipVariant.error, Icons.close_rounded),
    };
    return KayloChip(
      label: bookingStatusLabel(l10n, status),
      icon: icon,
      variant: variant,
    );
  }
}
