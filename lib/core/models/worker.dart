class Worker {
  final String id;
  final String name;
  final String profileImageUrl;
  final double rating;
  final int reviewsCount;
  final List<String> skillIds; // references to ServiceItem ids
  final String location;
  final double trustScore;

  Worker({
    required this.id,
    required this.name,
    required this.profileImageUrl,
    required this.rating,
    required this.reviewsCount,
    required this.skillIds,
    required this.location,
    required this.trustScore,
  });
}
