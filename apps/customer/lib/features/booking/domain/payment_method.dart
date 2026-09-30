/// How the customer settles a booking. Paying now opens Razorpay with
/// whatever the account offers (cards, netbanking, UPI where enabled);
/// paying after the service skips it and leaves the booking pending
/// until the worker confirms.
enum PaymentMethod { online, payAfterService }
