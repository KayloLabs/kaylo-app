import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/models/booking.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import '../../../auth/application/current_user_provider.dart';
import '../../../booking/application/bookings_providers.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});
  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
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
        KayloSnackbar.showSuccess(
          context,
          'Payment verified. Your booking is confirmed.',
        );
      } else {
        KayloSnackbar.showInfo(
          context,
          outcome.message ?? 'Payment was not completed.',
        );
      }
    } catch (_) {
      if (mounted) {
        KayloSnackbar.showError(
          context,
          'Could not open secure checkout. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Payment methods')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.credit_card, size: 64),
          const SizedBox(height: 20),
          Text(
            'Cards and UPI',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter a card manually or choose UPI in secure Razorpay checkout. Where supported, choose Razorpay’s save-card option to use that card again. Saved cards are managed inside checkout.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Kaylo does not store your full card number, CVV or PIN. NFC card enrolment is not supported by the current payment integration.',
          ),
          const SizedBox(height: 28),
          Text(
            'Complete a pending payment',
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
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Your next booking will open checkout, where you can add or select a card.',
                      ),
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
                              'Booking ${booking.id.substring(0, booking.id.length < 8 ? booking.id.length : 8)} • ${booking.scheduledAt.day}/${booking.scheduledAt.month}',
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
                  child: const Text('Could not load bookings. Retry'),
                ),
                loading: () => const LinearProgressIndicator(),
              ),
        ],
      ),
    ),
  );
}
