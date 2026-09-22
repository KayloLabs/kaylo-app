/// How the customer settles a booking. Card and UPI go through
/// [PaymentService]; paying after the service skips it and leaves the
/// booking pending until the worker confirms.
enum PaymentMethod { upi, card, payAfterService }
