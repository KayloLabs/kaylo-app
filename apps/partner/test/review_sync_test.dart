import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_partner/features/profile/application/profile_providers.dart';
import 'package:kaylo_partner/features/profile/domain/worker_profile.dart';
import 'package:kaylo_partner/features/reviews/application/review_changes_provider.dart';
import 'package:kaylo_partner/features/reviews/application/reviews_providers.dart';
import 'package:kaylo_partner/features/reviews/domain/reviews_repository.dart';
import 'package:kaylo_partner/features/reviews/domain/worker_review.dart';

class TestProfileRepository implements WorkerProfileRepository {
  WorkerProfile profile = WorkerProfile(
    id: 'worker-1',
    personId: 'person-1',
    name: 'Partner',
    phone: '',
    joinedOn: DateTime(2026),
  );
  int reads = 0;
  @override
  Stream<WorkerProfile?> watchProfile() async* {
    reads++;
    yield profile;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestReviewsRepository implements PartnerReviewsRepository {
  List<WorkerReview> reviews = [];
  int reads = 0;
  @override
  Future<List<WorkerReview>> getReviews() async {
    reads++;
    return reviews;
  }
}

void main() {
  test(
    'customer review changes refresh profile, summary and job review together',
    () async {
      final events = StreamController<int>();
      final profile = TestProfileRepository();
      final reviews = TestReviewsRepository();
      final container = ProviderContainer(
        overrides: [
          partnerReviewChangesProvider.overrideWith((ref) => events.stream),
          workerProfileRepositoryProvider.overrideWithValue(profile),
          partnerReviewsRepositoryProvider.overrideWithValue(reviews),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await events.close();
      });
      container.listen(workerProfileProvider, (_, _) {});
      container.listen(ratingSummaryProvider, (_, _) {});
      await container.read(workerProfileProvider.future);
      await container.read(reviewsProvider.future);
      expect(container.read(ratingSummaryProvider).count, 0);

      for (final rating in [5, 3]) {
        profile.profile = profile.profile.copyWith(
          rating: rating.toDouble(),
          reviewsCount: 1,
        );
        reviews.reviews = [
          WorkerReview(
            id: 'review-1',
            jobId: 'booking-1',
            customerName: 'Customer',
            serviceName: 'Plumbing',
            rating: rating,
            text: 'Review',
            createdAt: DateTime(2026, 10, 15),
          ),
        ];
        events.add(rating);
        await container.pump();
        final updated = await container.read(workerProfileProvider.future);
        await container.read(reviewsProvider.future);
        expect(updated!.rating, rating.toDouble());
        expect(updated.reviewsCount, 1);
        expect(
          container.read(ratingSummaryProvider).average,
          rating.toDouble(),
        );
        expect(container.read(jobReviewProvider('booking-1'))!.rating, rating);
      }
      profile.profile = profile.profile.copyWith(rating: 0, reviewsCount: 0);
      reviews.reviews = [];
      events.add(0);
      await container.pump();
      expect((await container.read(workerProfileProvider.future))!.rating, 0);
      await container.read(reviewsProvider.future);
      expect(container.read(ratingSummaryProvider).count, 0);
      expect(container.read(jobReviewProvider('booking-1')), isNull);
      // Each change causes one read, with no subscription/invalidation loop.
      expect(profile.reads, 4);
      expect(reviews.reads, 4);
    },
  );
}
