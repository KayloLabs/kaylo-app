import 'worker_review.dart';

abstract class PartnerReviewsRepository {
  Future<List<WorkerReview>> getReviews();
}
