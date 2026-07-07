enum BookingStatus { pending, confirmed, inProgress, completed, cancelled }

class Booking {
  final String id;
  final String userId;
  final String serviceId;
  final String? workerId; // null if not yet assigned
  final DateTime scheduledAt;
  final BookingStatus status;
  final double totalAmount;

  Booking({
    required this.id,
    required this.userId,
    required this.serviceId,
    this.workerId,
    required this.scheduledAt,
    required this.status,
    required this.totalAmount,
  });
}
