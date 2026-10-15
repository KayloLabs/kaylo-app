import 'package:flutter/foundation.dart';

/// Mirrors `workers.verification_status` (migration 0020).
enum VerificationStatus {
  unverified,
  underReview,
  verified,
  rejected;

  static VerificationStatus parse(String? value) => switch (value) {
    'verified' => VerificationStatus.verified,
    'under_review' => VerificationStatus.underReview,
    'rejected' => VerificationStatus.rejected,
    _ => VerificationStatus.unverified,
  };

  String get dbValue => switch (this) {
    VerificationStatus.verified => 'verified',
    VerificationStatus.underReview => 'under_review',
    VerificationStatus.rejected => 'rejected',
    VerificationStatus.unverified => 'unverified',
  };
}

/// Mirrors `worker_documents.status`.
enum DocumentStatus {
  pending,
  verified,
  rejected;

  static DocumentStatus parse(String? value) => switch (value) {
    'verified' => DocumentStatus.verified,
    'rejected' => DocumentStatus.rejected,
    _ => DocumentStatus.pending,
  };
}

/// One submitted document: `doc_type` is `aadhaar_front`, `aadhaar_back`,
/// `police_certificate`, `photo` or `selfie`.
@immutable
class WorkerDocument {
  final String type;
  final DocumentStatus status;

  const WorkerDocument({required this.type, required this.status});

  factory WorkerDocument.fromJson(Map<String, dynamic> json) => WorkerDocument(
    type: json['doc_type'] as String,
    status: DocumentStatus.parse(json['status'] as String?),
  );

  Map<String, dynamic> toJson() => {'doc_type': type, 'status': status.name};
}

/// A service from the catalogue, the way the worker picks it.
@immutable
class ServiceOption {
  final String id;
  final String name;

  const ServiceOption({required this.id, required this.name});

  factory ServiceOption.fromJson(Map<String, dynamic> json) => ServiceOption(
    id: json['service_id'] as String,
    name: json['service_name'] as String,
  );

  Map<String, dynamic> toJson() => {'service_id': id, 'service_name': name};

  @override
  bool operator ==(Object other) =>
      other is ServiceOption && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// The signed-in worker, as `my_worker_profile()` returns it: the person,
/// the worker row, the services offered, the service area, the payout
/// account and the state of each submitted document.
@immutable
class WorkerProfile {
  final String id;
  final String personId;
  final String name;
  final String phone;
  final String? email;
  final String? photoUrl;
  final int experienceYears;
  final double? hourlyRate;
  final double travelRadiusKm;
  final String? bio;
  final VerificationStatus verification;

  /// Mirrors `workers.is_available`: the on-duty switch.
  final bool isAvailable;
  final double rating;
  final int reviewsCount;
  final int totalJobs;
  final DateTime joinedOn;
  final String? district;

  /// The free-text hours typed at registration; the structured weekly
  /// hours live in the availability feature.
  final String? workingHoursNote;
  final List<ServiceOption> services;
  final String? upiId;
  final String? bankAccount;
  final List<WorkerDocument> documents;

  const WorkerProfile({
    required this.id,
    required this.personId,
    required this.name,
    required this.phone,
    this.email,
    this.photoUrl,
    this.experienceYears = 0,
    this.hourlyRate,
    this.travelRadiusKm = 10,
    this.bio,
    this.verification = VerificationStatus.unverified,
    this.isAvailable = true,
    this.rating = 0,
    this.reviewsCount = 0,
    this.totalJobs = 0,
    required this.joinedOn,
    this.district,
    this.workingHoursNote,
    this.services = const [],
    this.upiId,
    this.bankAccount,
    this.documents = const [],
  });

  bool get isVerified => verification == VerificationStatus.verified;
  bool get hasPayoutAccount =>
      (upiId ?? '').isNotEmpty || (bankAccount ?? '').isNotEmpty;

  /// The state of one document type, or null when never submitted.
  DocumentStatus? documentStatus(String type) {
    for (final doc in documents) {
      if (doc.type == type) return doc.status;
    }
    return null;
  }

  /// Both sides of the Aadhaar card count as one document to the worker:
  /// verified only when both are, rejected if either is, otherwise pending.
  DocumentStatus? get aadhaarStatus {
    final front = documentStatus('aadhaar_front');
    final back = documentStatus('aadhaar_back');
    if (front == null && back == null) return null;
    final both = [front, back];
    if (both.contains(DocumentStatus.rejected)) return DocumentStatus.rejected;
    if (front == DocumentStatus.verified && back == DocumentStatus.verified) {
      return DocumentStatus.verified;
    }
    return DocumentStatus.pending;
  }

  WorkerProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? photoUrl,
    int? experienceYears,
    double? hourlyRate,
    double? travelRadiusKm,
    String? bio,
    VerificationStatus? verification,
    bool? isAvailable,
    double? rating,
    int? reviewsCount,
    int? totalJobs,
    String? district,
    String? workingHoursNote,
    List<ServiceOption>? services,
    String? upiId,
    String? bankAccount,
    List<WorkerDocument>? documents,
  }) {
    return WorkerProfile(
      id: id,
      personId: personId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      experienceYears: experienceYears ?? this.experienceYears,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      travelRadiusKm: travelRadiusKm ?? this.travelRadiusKm,
      bio: bio ?? this.bio,
      verification: verification ?? this.verification,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      totalJobs: totalJobs ?? this.totalJobs,
      joinedOn: joinedOn,
      district: district ?? this.district,
      workingHoursNote: workingHoursNote ?? this.workingHoursNote,
      services: services ?? this.services,
      upiId: upiId ?? this.upiId,
      bankAccount: bankAccount ?? this.bankAccount,
      documents: documents ?? this.documents,
    );
  }

  /// Keys follow `my_worker_profile()` in migration 0022; the sample build
  /// stores the same shape.
  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    return WorkerProfile(
      id: json['worker_id'] as String,
      personId: (json['person_id'] as String?) ?? '',
      name: (json['full_name'] as String?) ?? '',
      phone: (json['phone_number'] as String?) ?? '',
      email: json['email'] as String?,
      photoUrl: json['profile_photo'] as String?,
      experienceYears: ((json['experience_years'] as num?) ?? 0).toInt(),
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      travelRadiusKm: ((json['travel_radius_km'] as num?) ?? 10).toDouble(),
      bio: json['bio'] as String?,
      verification: VerificationStatus.parse(
        json['verification_status'] as String?,
      ),
      isAvailable: (json['is_available'] as bool?) ?? true,
      rating: ((json['average_rating'] as num?) ?? 0).toDouble(),
      reviewsCount: ((json['reviews_count'] as num?) ?? 0).toInt(),
      totalJobs: ((json['total_jobs'] as num?) ?? 0).toInt(),
      joinedOn:
          DateTime.tryParse((json['joined_date'] as String?) ?? '') ??
          DateTime.now(),
      district: json['district'] as String?,
      workingHoursNote: json['working_hours'] as String?,
      services: [
        for (final s in (json['services'] as List?) ?? const [])
          ServiceOption.fromJson(Map<String, dynamic>.from(s as Map)),
      ],
      upiId: json['upi_id'] as String?,
      bankAccount: json['bank_account'] as String?,
      documents: [
        for (final d in (json['documents'] as List?) ?? const [])
          WorkerDocument.fromJson(Map<String, dynamic>.from(d as Map)),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'worker_id': id,
    'person_id': personId,
    'full_name': name,
    'phone_number': phone,
    'email': email,
    'profile_photo': photoUrl,
    'experience_years': experienceYears,
    'hourly_rate': hourlyRate,
    'travel_radius_km': travelRadiusKm,
    'bio': bio,
    'verification_status': verification.dbValue,
    'is_available': isAvailable,
    'average_rating': rating,
    'reviews_count': reviewsCount,
    'total_jobs': totalJobs,
    'joined_date': joinedOn.toIso8601String().substring(0, 10),
    'district': district,
    'working_hours': workingHoursNote,
    'services': [for (final s in services) s.toJson()],
    'upi_id': upiId,
    'bank_account': bankAccount,
    'documents': [for (final d in documents) d.toJson()],
  };
}

/// What the edit sheet can change. A null field is left as it is; the
/// keys match `update_worker_profile(details)`.
@immutable
class WorkerProfileEdit {
  final String? name;
  final String? district;
  final double? travelRadiusKm;
  final String? bio;
  final List<String>? serviceIds;
  final String? upiId;

  const WorkerProfileEdit({
    this.name,
    this.district,
    this.travelRadiusKm,
    this.bio,
    this.serviceIds,
    this.upiId,
  });

  bool get isEmpty =>
      name == null &&
      district == null &&
      travelRadiusKm == null &&
      bio == null &&
      serviceIds == null &&
      upiId == null;

  Map<String, dynamic> toJson() => {
    if (name != null) 'full_name': name,
    if (district != null) 'district': district,
    if (travelRadiusKm != null) 'travel_radius_km': travelRadiusKm,
    if (bio != null) 'bio': bio,
    if (serviceIds != null) 'services': serviceIds,
    if (upiId != null) 'upi_id': upiId,
  };
}

/// The 14 districts a worker can serve; the same list registration uses.
const List<String> keralaDistricts = [
  'Alappuzha',
  'Ernakulam',
  'Idukki',
  'Kannur',
  'Kasaragod',
  'Kollam',
  'Kottayam',
  'Kozhikode',
  'Malappuram',
  'Palakkad',
  'Pathanamthitta',
  'Thiruvananthapuram',
  'Thrissur',
  'Wayanad',
];

/// `user@bank`, the shape every UPI handle has.
final RegExp upiIdPattern = RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$');

abstract class WorkerProfileRepository {
  /// The current profile, then every change; null when the signed-in
  /// person has no worker row yet.
  Stream<WorkerProfile?> watchProfile();
  Future<WorkerProfile?> getProfile();

  /// Applies [edit] and returns the refreshed profile.
  Future<WorkerProfile> updateProfile(WorkerProfileEdit edit);

  /// The on-duty switch. Off-duty workers remain bookable for scheduled work.
  Future<void> setAvailable(bool available);

  /// The catalogue the worker can pick services from.
  Future<List<ServiceOption>> listServices();
  void dispose();
}
