class Worker {
  final String id;
  final String name;
  final String profileImageUrl;
  final double rating;
  final int reviewsCount;
  final List<String> skillIds; // references to ServiceItem ids
  final String location;
  final double trustScore;

  /// Mirrors `worker_profiles.is_verified`; drives the verified badge.
  final bool isVerified;

  /// Mirrors `worker_profiles.is_available`; false hides the worker
  /// from new bookings without deleting their profile.
  final bool isAvailable;

  /// Mirrors `worker_profiles.hourly_rate`; null when rate-per-job.
  final double? hourlyRate;

  /// Mirrors `worker_profiles.total_jobs` (completed bookings).
  final int totalJobs;

  Worker({
    required this.id,
    required this.name,
    required this.profileImageUrl,
    required this.rating,
    required this.reviewsCount,
    required this.skillIds,
    required this.location,
    required this.trustScore,
    this.isVerified = false,
    this.isAvailable = true,
    this.hourlyRate,
    this.totalJobs = 0,
  });
}
