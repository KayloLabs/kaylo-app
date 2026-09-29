/// A booking progresses from confirmation through travel and work completion.
///
/// [onWay] is deliberately distinct from [inProgress]: it lets the tracking
/// screen accurately show that a professional is travelling before work starts.
enum BookingStatus {
  pending,
  confirmed,
  onWay,
  inProgress,
  completed,
  cancelled,
}

class Booking {
  final String id;
  final String userId;
  final String serviceId;
  final String? workerId; // null if not yet assigned
  final DateTime scheduledAt;
  final BookingStatus status;

  /// Estimated cost quoted at booking time (`bookings.estimated_cost`).
  final double totalAmount;

  /// Mirrors `bookings.location_id`; null until an address is chosen.
  final String? locationId;

  /// Customer instructions for the worker (`bookings.notes`).
  final String? notes;

  /// Actual amount charged on completion (`bookings.final_cost`);
  /// null while the job is still open.
  final double? finalCost;

  Booking({
    required this.id,
    required this.userId,
    required this.serviceId,
    this.workerId,
    required this.scheduledAt,
    required this.status,
    required this.totalAmount,
    this.locationId,
    this.notes,
    this.finalCost,
  });
}
