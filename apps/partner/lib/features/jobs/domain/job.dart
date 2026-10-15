import 'package:flutter/foundation.dart';

enum JobStage {
  requested,
  accepted,
  onTheWay,
  arrived,
  inProgress,
  completed,
  cancelled;

  bool get isRequested => this == JobStage.requested;
  bool get isAccepted => this == JobStage.accepted;
  bool get isOnTheWay => this == JobStage.onTheWay;
  bool get isArrived => this == JobStage.arrived;
  bool get isInProgress => this == JobStage.inProgress;
  bool get isCompleted => this == JobStage.completed;
  bool get isCancelled => this == JobStage.cancelled;

  JobStage? get next {
    switch (this) {
      case JobStage.requested:
        return JobStage.accepted;
      case JobStage.accepted:
        return JobStage.onTheWay;
      case JobStage.onTheWay:
        return JobStage.arrived;
      case JobStage.arrived:
        return JobStage.inProgress;
      case JobStage.inProgress:
        return JobStage.completed;
      case JobStage.completed:
      case JobStage.cancelled:
        return null;
    }
  }
}

@immutable
class Job {
  final String id;
  final String serviceName; // "Plumbing"
  final String serviceIcon; // icon asset or category
  final String customerName; // "Anjali Menon"
  final String customerPhone; // for the call button
  final String addressLine; // "Kadavil House, Thottada, Kannur"
  final double? latitude;
  final double? longitude;
  final double? distanceKm; // Unknown until a route distance is available.
  final DateTime scheduledAt;
  final double payout; // what the worker earns
  final String paymentMode;
  final double? customerPrice;
  final String paymentStatus;
  final String notes; // customer instructions
  final JobStage stage;

  const Job({
    required this.id,
    required this.serviceName,
    required this.serviceIcon,
    required this.customerName,
    required this.customerPhone,
    required this.addressLine,
    this.latitude,
    this.longitude,
    required this.distanceKm,
    required this.scheduledAt,
    required this.payout,
    this.paymentMode = 'online',
    this.customerPrice,
    this.paymentStatus = 'pending',
    required this.notes,
    required this.stage,
  });

  bool get needsCashCollection =>
      paymentMode == 'cash' &&
      paymentStatus != 'success' &&
      stage == JobStage.inProgress;

  bool get isActive =>
      stage == JobStage.accepted ||
      stage == JobStage.onTheWay ||
      stage == JobStage.arrived ||
      stage == JobStage.inProgress;

  bool get isRequested => stage == JobStage.requested;
  bool get isCompleted => stage == JobStage.completed;
  bool get isCancelled => stage == JobStage.cancelled;

  Job copyWith({
    String? id,
    String? serviceName,
    String? serviceIcon,
    String? customerName,
    String? customerPhone,
    String? addressLine,
    double? latitude,
    double? longitude,
    double? distanceKm,
    DateTime? scheduledAt,
    double? payout,
    String? paymentMode,
    double? customerPrice,
    String? paymentStatus,
    String? notes,
    JobStage? stage,
  }) {
    return Job(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      serviceIcon: serviceIcon ?? this.serviceIcon,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      addressLine: addressLine ?? this.addressLine,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm: distanceKm ?? this.distanceKm,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      payout: payout ?? this.payout,
      paymentMode: paymentMode ?? this.paymentMode,
      customerPrice: customerPrice ?? this.customerPrice,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      stage: stage ?? this.stage,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'serviceName': serviceName,
    'serviceIcon': serviceIcon,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'addressLine': addressLine,
    'latitude': latitude,
    'longitude': longitude,
    'distanceKm': distanceKm,
    'scheduledAt': scheduledAt.toIso8601String(),
    'payout': payout,
    'paymentMode': paymentMode,
    'customerPrice': customerPrice,
    'paymentStatus': paymentStatus,
    'notes': notes,
    'stage': stage.name,
  };

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String,
      serviceName: json['serviceName'] as String,
      serviceIcon: json['serviceIcon'] as String? ?? 'plumbing',
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      addressLine: json['addressLine'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      payout: (json['payout'] as num).toDouble(),
      paymentMode: json['paymentMode'] as String? ?? 'online',
      customerPrice: (json['customerPrice'] as num?)?.toDouble(),
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      notes: json['notes'] as String? ?? '',
      stage: JobStage.values.firstWhere(
        (e) => e.name == json['stage'],
        orElse: () => JobStage.requested,
      ),
    );
  }

  // Provider notifications must distinguish newer snapshots of the same job.
  // Identity-only equality hid stage and contact changes from detail screens.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Job &&
          id == other.id &&
          stage == other.stage &&
          serviceName == other.serviceName &&
          serviceIcon == other.serviceIcon &&
          customerName == other.customerName &&
          customerPhone == other.customerPhone &&
          addressLine == other.addressLine &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          distanceKm == other.distanceKm &&
          scheduledAt == other.scheduledAt &&
          payout == other.payout &&
          paymentMode == other.paymentMode &&
          customerPrice == other.customerPrice &&
          paymentStatus == other.paymentStatus &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(
    id,
    stage,
    serviceName,
    serviceIcon,
    customerName,
    customerPhone,
    addressLine,
    latitude,
    longitude,
    distanceKm,
    scheduledAt,
    payout,
    paymentMode,
    customerPrice,
    paymentStatus,
    notes,
  );
}
