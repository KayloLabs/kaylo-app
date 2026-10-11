class WorkerReview {
  final String id, jobId, customerName, serviceName, text;
  final int rating;
  final DateTime createdAt;
  const WorkerReview({
    required this.id,
    required this.jobId,
    required this.customerName,
    required this.serviceName,
    required this.rating,
    required this.text,
    required this.createdAt,
  }) : assert(rating >= 1 && rating <= 5);
  factory WorkerReview.fromJson(Map<String, dynamic> row) => WorkerReview(
    id: row['review_id'] as String,
    jobId: row['booking_id'] as String,
    customerName: row['customer_name'] as String? ?? '',
    serviceName: row['service_name'] as String? ?? '',
    rating: (row['rating'] as num).toInt(),
    text: row['review'] as String? ?? '',
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
  );
}

class RatingSummary {
  final double average;
  final int count;
  final Map<int, int> distribution;
  const RatingSummary({
    required this.average,
    required this.count,
    required this.distribution,
  });
  factory RatingSummary.fromReviews(List<WorkerReview> reviews) {
    final distribution = {for (var i = 5; i >= 1; i--) i: 0};
    var sum = 0;
    for (final review in reviews) {
      distribution.update(review.rating, (n) => n + 1);
      sum += review.rating;
    }
    return RatingSummary(
      average: reviews.isEmpty ? 0 : sum / reviews.length,
      count: reviews.length,
      distribution: distribution,
    );
  }
}

enum ReviewFilter { all, five, four, threeAndBelow }

List<WorkerReview> filterReviews(
  List<WorkerReview> reviews,
  ReviewFilter filter,
) => reviews
    .where(
      (r) => switch (filter) {
        ReviewFilter.all => true,
        ReviewFilter.five => r.rating == 5,
        ReviewFilter.four => r.rating == 4,
        ReviewFilter.threeAndBelow => r.rating <= 3,
      },
    )
    .toList();
