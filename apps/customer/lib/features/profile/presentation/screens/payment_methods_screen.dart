import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/models/booking.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import '../../../auth/application/current_user_provider.dart';
import '../../../booking/application/bookings_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});
  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  bool _busy = false;
  Future<void> _pay(Booking booking) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final outcome = await ref
          .read(paymentGatewayProvider)
          .pay(
            bookingId: booking.id,
            email: ref.read(currentUserProvider)?.email,
            preferredMethod: 'card',
          );
      ref.invalidate(userBookingsProvider);
      if (!mounted) return;
      if (outcome.paid) {
        KayloSnackbar.showSuccess(context, _l10n.paymentVerified);
      } else {
        KayloSnackbar.showInfo(
          context,
          outcome.message ?? _l10n.paymentNotCompleted,
        );
      }
    } catch (_) {
      if (mounted) {
        KayloSnackbar.showError(context, _l10n.checkoutOpenFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: Text(_l10n.paymentMethods)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.credit_card, size: 64),
          const SizedBox(height: 20),
          Text(
            _l10n.cardsAndUpi,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(_l10n.paymentMethodsBody),
          const SizedBox(height: 12),
          Text(_l10n.paymentMethodsNote),
          const SizedBox(height: 28),
          Text(
            _l10n.completePendingPayment,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (_busy) const LinearProgressIndicator(),
          ref
              .watch(userBookingsProvider)
              .when(
                data: (rows) {
                  final pending = rows
                      .where(
                        (b) =>
                            b.status == BookingStatus.pending &&
                            b.totalAmount > 0,
                      )
                      .toList();
                  if (pending.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_l10n.noPendingPayments),
                    );
                  }
                  return Column(
                    children: [
                      for (final booking in pending)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.credit_card_outlined),
                            title: Text(
                              '₹${booking.totalAmount.toStringAsFixed(2)}',
                            ),
                            subtitle: Text(
                              _l10n.pendingBookingLine(
                                booking.id.substring(
                                  0,
                                  booking.id.length < 8 ? booking.id.length : 8,
                                ),
                                '${booking.scheduledAt.day}/${booking.scheduledAt.month}',
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _busy ? null : () => _pay(booking),
                          ),
                        ),
                    ],
                  );
                },
                error: (_, _) => TextButton(
                  onPressed: () => ref.invalidate(userBookingsProvider),
                  child: Text(_l10n.bookingsLoadFailedRetry),
                ),
                loading: () => const LinearProgressIndicator(),
              ),
        ],
      ),
    ),
  );
}
