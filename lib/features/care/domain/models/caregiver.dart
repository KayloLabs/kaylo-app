class Caregiver {
  final String id;
  final String name;
  final double rating;
  final int reviewsCount;
  final double hourlyRate;
  final int experienceYears;
  final bool isVerified;
  final String imageUrl;
  final List<String> specialties;
  final String bio;

  const Caregiver({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewsCount,
    required this.hourlyRate,
    required this.experienceYears,
    required this.isVerified,
    required this.imageUrl,
    required this.specialties,
    required this.bio,
  });
}

class CaregiverBookingRecord {
  final String id;
  final String caregiverId;
  final String caregiverName;
  final DateTime date;
  final String startTime;
  final int hours;
  final double hourlyRate;
  final double totalAmount;
  final String careType;
  final String? notes;
  final String status;

  const CaregiverBookingRecord({
    required this.id,
    required this.caregiverId,
    required this.caregiverName,
    required this.date,
    required this.startTime,
    required this.hours,
    required this.hourlyRate,
    required this.totalAmount,
    required this.careType,
    this.notes,
    required this.status,
  });
}
