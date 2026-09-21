import '../../../core/models/booking.dart';
import '../../../core/models/service_item.dart';
import 'payment_method.dart';

/// One label/value row on the confirmation screen. The flow that created
/// the booking localizes both strings before navigating, so the screen
/// stays generic across farm, home and care bookings.
class ReceiptLine {
  final String label;
  final String value;

  const ReceiptLine(this.label, this.value);
}

/// What the confirmation screen renders; passed as the route's `extra`.
class BookingReceipt {
  final Booking booking;
  final ServiceItem service;
  final PaymentMethod paymentMethod;
  final List<ReceiptLine> extras;

  const BookingReceipt({
    required this.booking,
    required this.service,
    required this.paymentMethod,
    this.extras = const [],
  });
}
