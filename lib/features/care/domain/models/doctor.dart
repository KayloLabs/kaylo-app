class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String hospital;
  final int experienceYears;
  final double rating;
  final int reviewsCount;
  final double consultationFee;
  final List<String> availableDays;
  final List<String> timeSlots;
  final String imageUrl;
  final String bio;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.experienceYears,
    required this.rating,
    required this.reviewsCount,
    required this.consultationFee,
    required this.availableDays,
    required this.timeSlots,
    required this.imageUrl,
    required this.bio,
  });
}
