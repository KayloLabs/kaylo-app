import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/worker_review.dart';
import '../domain/reviews_repository.dart';

class SupabasePartnerReviewsRepository implements PartnerReviewsRepository {
  final SupabaseClient client;
  SupabasePartnerReviewsRepository(this.client);
  @override
  Future<List<WorkerReview>> getReviews() async {
    final rows = await client.rpc('my_worker_reviews');
    final reviews = (rows as List)
        .map(
          (row) => WorkerReview.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  }
}
