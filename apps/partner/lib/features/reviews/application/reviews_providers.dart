import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/application/partner_session.dart';
import '../data/mock_reviews_repository.dart';
import '../data/supabase_reviews_repository.dart';
import '../domain/reviews_repository.dart';
import '../domain/worker_review.dart';

final partnerReviewsRepositoryProvider = Provider<PartnerReviewsRepository>((
  ref,
) {
  ref.watch(
    partnerAuthStateProvider.select(
      (s) => (s.asData?.value.workerId, s.asData?.value.status),
    ),
  );
  if (useMockData) {
    final l = lookupAppLocalizations(ref.watch(partnerLocaleProvider));
    return MockPartnerReviewsRepository(
      comments: [
        l.reviewSample1,
        l.reviewSample2,
        l.reviewSample3,
        l.reviewSample4,
        l.reviewSample5,
        l.reviewSample6,
        l.reviewSample7,
        l.reviewSample8,
      ],
    );
  }
  return SupabasePartnerReviewsRepository(ref.watch(supabaseClientProvider));
});
final reviewsProvider = FutureProvider<List<WorkerReview>>(
  (ref) => ref.watch(partnerReviewsRepositoryProvider).getReviews(),
);
final ratingSummaryProvider = Provider<RatingSummary>(
  (ref) =>
      RatingSummary.fromReviews(ref.watch(reviewsProvider).asData?.value ?? []),
);
final jobReviewProvider = Provider.family<WorkerReview?, String>((ref, id) {
  for (final review
      in ref.watch(reviewsProvider).asData?.value ?? <WorkerReview>[]) {
    if (review.jobId == id) return review;
  }
  return null;
});
