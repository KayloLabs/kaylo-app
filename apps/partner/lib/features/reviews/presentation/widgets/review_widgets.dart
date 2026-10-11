import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_ui/widgets/avatar_circle.dart';
import 'package:kaylo_ui/widgets/rating_stars.dart';
import 'package:kaylo_ui/widgets/section_header.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/partner_load_error.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/reviews_providers.dart';
import '../../domain/worker_review.dart';

class RatingDistribution extends StatelessWidget {
  final RatingSummary summary;
  const RatingDistribution({super.key, required this.summary});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!,
        scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Text(
                summary.average.toStringAsFixed(1),
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              RatingStars(rating: summary.average, size: 16),
              const SizedBox(height: 6),
              Text(
                l.reviewsCount(summary.count),
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              for (var stars = 5; stars >= 1; stars--)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Semantics(
                    label: l.reviewsDistribution(
                      stars,
                      summary.distribution[stars] ?? 0,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          child: Text(
                            '$stars',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: summary.count == 0
                                  ? 0
                                  : (summary.distribution[stars] ?? 0) /
                                        summary.count,
                              color: scheme.primary,
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${summary.distribution[stars] ?? 0}',
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class WorkerReviewTile extends StatelessWidget {
  final WorkerReview review;
  const WorkerReviewTile({super.key, required this.review});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AvatarCircle(fallbackText: review.customerName, radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                review.customerName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              MaterialLocalizations.of(
                context,
              ).formatShortMonthDay(review.createdAt),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        RatingStars(rating: review.rating.toDouble(), size: 16),
        if (review.serviceName.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            review.serviceName,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
        if (review.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(review.text),
        ],
      ],
    ),
  );
}

class ProfileReviewsSection extends ConsumerWidget {
  const ProfileReviewsSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l.reviewsTitle,
          actionText: l.reviewsSeeAll,
          onActionPressed: () => context.push(Routes.reviews),
        ),
        const SizedBox(height: 12),
        ref
            .watch(reviewsProvider)
            .when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => PartnerLoadError(
                message: l.reviewsLoadFailed,
                onRetry: () => ref.invalidate(reviewsProvider),
              ),
              data: (rows) => KayloCard(
                child: Column(
                  children: [
                    RatingDistribution(
                      summary: RatingSummary.fromReviews(rows),
                    ),
                    if (rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          l.reviewsEmptyBody,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    for (final review in rows.take(3)) ...[
                      const Divider(height: 24),
                      WorkerReviewTile(review: review),
                    ],
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class JobReviewStars extends ConsumerWidget {
  final String jobId;
  const JobReviewStars({super.key, required this.jobId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(jobReviewProvider(jobId));
    if (review == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.reviewsCustomerRating,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(width: 8),
          RatingStars(rating: review.rating.toDouble(), size: 16),
        ],
      ),
    );
  }
}
