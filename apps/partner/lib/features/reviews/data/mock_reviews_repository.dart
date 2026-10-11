import '../domain/worker_review.dart';
import '../domain/reviews_repository.dart';

class MockPartnerReviewsRepository implements PartnerReviewsRepository {
  final List<String> comments;
  final DateTime now;
  MockPartnerReviewsRepository({required this.comments, DateTime? now})
    : now = now ?? DateTime.now();
  @override
  Future<List<WorkerReview>> getReviews() async {
    const names = [
      'അഞ്ജലി മേനോൻ',
      'രമേഷ് നായർ',
      'ദേവിക സുരേഷ്',
      'ഫാത്തിമ റഹ്മാൻ',
      'അനൂപ് കുമാർ',
      'മീര കൃഷ്ണൻ',
      'ജോസഫ് മാത്യു',
      'ലത രാജൻ',
    ];
    const jobs = [
      'job-comp-today',
      'job-comp-yest-1',
      'job-comp-yest-2',
      'job-comp-d2',
      'job-comp-d3-1',
      'job-comp-d3-2',
      'job-comp-d4',
      'job-comp-d5',
    ];
    const ratings = [5, 5, 4, 5, 3, 5, 4, 5];
    return [
      for (var i = 0; i < 8; i++)
        WorkerReview(
          id: 'review-$i',
          jobId: jobs[i],
          customerName: names[i],
          serviceName: '',
          rating: ratings[i],
          text: comments[i],
          createdAt: now.subtract(
            Duration(days: [0, 2, 6, 12, 20, 31, 42, 56][i]),
          ),
        ),
    ];
  }
}
