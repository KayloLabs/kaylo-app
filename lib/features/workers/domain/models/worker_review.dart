class WorkerReview {
  final String id;
  final String workerId;
  final String customerName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? avatarUrl;

  const WorkerReview({
    required this.id,
    required this.workerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.avatarUrl,
  });
}
