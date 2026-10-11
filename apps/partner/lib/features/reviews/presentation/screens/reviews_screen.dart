import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import '../../../../core/widgets/partner_load_error.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/reviews_providers.dart';
import '../../domain/worker_review.dart';
import '../widgets/review_widgets.dart';

class PartnerReviewsScreen extends ConsumerStatefulWidget {
  const PartnerReviewsScreen({super.key});
  @override
  ConsumerState<PartnerReviewsScreen> createState() => _ReviewsState();
}

class _ReviewsState extends ConsumerState<PartnerReviewsScreen> {
  ReviewFilter _filter = ReviewFilter.all;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.reviewsTitle)),
      body: ref
          .watch(reviewsProvider)
          .when(
            loading: () => const Center(child: KayloLoader()),
            error: (_, _) => PartnerLoadError(
              message: l.reviewsLoadFailed,
              onRetry: () => ref.invalidate(reviewsProvider),
            ),
            data: (all) {
              final rows = filterReviews(all, _filter);
              return RefreshIndicator(
                onRefresh: () => ref.refresh(reviewsProvider.future).then((_) {}),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    RatingDistribution(summary: RatingSummary.fromReviews(all)),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final filter in ReviewFilter.values)
                          ChoiceChip(
                            key: ValueKey('reviews-filter-${filter.name}'),
                            label: Text(switch (filter) {
                              ReviewFilter.all => l.reviewsAll,
                              ReviewFilter.five => l.reviewsFive,
                              ReviewFilter.four => l.reviewsFour,
                              ReviewFilter.threeAndBelow => l.reviewsThreeBelow,
                            }),
                            selected: _filter == filter,
                            onSelected: (_) => setState(() => _filter = filter),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (rows.isEmpty)
                      EmptyState(
                        title: l.reviewsEmpty,
                        description: l.reviewsEmptyBody,
                        icon: Icons.star_outline_rounded,
                      ),
                    for (final review in rows) ...[
                      WorkerReviewTile(
                        key: ValueKey(review.id),
                        review: review,
                      ),
                      const Divider(height: 1),
                    ],
                  ],
                ),
              );
            },
          ),
    );
  }
}
