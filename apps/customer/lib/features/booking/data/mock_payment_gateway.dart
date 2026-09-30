import '../domain/payment_gateway.dart';

/// The demo build's gateway: a short pause, then paid, so the checkout
/// flow runs with no backend and no Razorpay account.
class MockPaymentGateway implements PaymentGateway {
  @override
  Future<PaymentOutcome> pay({
    required String bookingId,
    String? email,
    String? preferredMethod,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return PaymentOutcome.paid(
      invoiceNumber: 'KAY-DEMO-${bookingId.hashCode.abs() % 100000}'.padRight(9, '0'),
      invoiceSent: email != null && email.isNotEmpty,
    );
  }
}
