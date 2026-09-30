enum BookingStatus { pending, confirmed, inProgress, completed, cancelled }

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

  Booking copyWith({
    String? id,
    String? userId,
    String? serviceId,
    String? workerId,
    DateTime? scheduledAt,
    BookingStatus? status,
    double? totalAmount,
    String? locationId,
    String? notes,
    double? finalCost,
  }) => Booking(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    serviceId: serviceId ?? this.serviceId,
    workerId: workerId ?? this.workerId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    status: status ?? this.status,
    totalAmount: totalAmount ?? this.totalAmount,
    locationId: locationId ?? this.locationId,
    notes: notes ?? this.notes,
    finalCost: finalCost ?? this.finalCost,
  );
}
