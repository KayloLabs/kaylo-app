/// What came of taking the customer through a payment.
class PaymentOutcome {
  final bool paid;

  /// From the server once the payment is verified.
  final String? invoiceNumber;
  final bool invoiceSent;

  /// Why it did not go through, in words the screen can show.
  final String? message;

  const PaymentOutcome.paid({this.invoiceNumber, this.invoiceSent = false})
    : paid = true,
      message = null;

  const PaymentOutcome.notPaid(this.message)
    : paid = false,
      invoiceNumber = null,
      invoiceSent = false;
}

/// Takes the customer through paying for a booking and returns once the
/// server has confirmed the payment, or the customer gave up. The amount
/// is never passed in: the server reads it from the booking.
abstract class PaymentGateway {
  /// [preferredMethod] is 'upi' or 'card': the sheet opens on that
  /// method first, with the others still available.
  Future<PaymentOutcome> pay({
    required String bookingId,
    String? email,
    String? preferredMethod,
  });
}
