enum BookingStatus { pending, confirmed, inProgress, completed, cancelled }

/// How the customer settles the booking (`bookings.payment_mode`): through
/// Razorpay, or cash handed to the worker once the job is done.
enum PaymentMode { online, cash }

/// Where the worker is in the job (`bookings.worker_stage`). The status
/// above is the customer's coarse view of the same thing.
enum WorkerStage {
  requested,
  accepted,
  onTheWay,
  arrived,
  inProgress,
  completed,
  cancelled;

  static WorkerStage fromDb(String? value) => switch (value) {
    'accepted' => accepted,
    'on_the_way' => onTheWay,
    'arrived' => arrived,
    'in_progress' => inProgress,
    'completed' => completed,
    'cancelled' => cancelled,
    _ => requested,
  };
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

  final double? subtotalAmount;
  final double discountAmount;
  final String? offerCode;
  final PaymentMode paymentMode;
  final WorkerStage workerStage;

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
    this.subtotalAmount,
    this.discountAmount = 0,
    this.offerCode,
    this.paymentMode = PaymentMode.online,
    this.workerStage = WorkerStage.requested,
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
    double? subtotalAmount,
    double? discountAmount,
    String? offerCode,
    PaymentMode? paymentMode,
    WorkerStage? workerStage,
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
    subtotalAmount: subtotalAmount ?? this.subtotalAmount,
    discountAmount: discountAmount ?? this.discountAmount,
    offerCode: offerCode ?? this.offerCode,
    paymentMode: paymentMode ?? this.paymentMode,
    workerStage: workerStage ?? this.workerStage,
  );
}
