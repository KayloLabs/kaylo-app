import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_partner/features/reviews/application/reviews_providers.dart';
import 'package:kaylo_partner/features/reviews/data/mock_reviews_repository.dart';
import 'package:kaylo_partner/features/reviews/domain/worker_review.dart';
import 'package:kaylo_partner/features/reviews/presentation/screens/reviews_screen.dart';
import 'package:kaylo_partner/features/reviews/presentation/widgets/review_widgets.dart';
import 'package:kaylo_partner/l10n/generated/app_localizations.dart';

void main() {
  MockPartnerReviewsRepository repository() => MockPartnerReviewsRepository(
    comments: List.generate(8, (i) => 'Review $i'),
    now: DateTime(2026, 10, 10),
  );
  test(
    'eight reviews average and distribution match the actual seed',
    () async {
      final reviews = await repository().getReviews();
      final summary = RatingSummary.fromReviews(reviews);
      expect(reviews.length, 8);
      expect(
        summary.average,
        reviews.fold<int>(0, (sum, r) => sum + r.rating) / reviews.length,
      );
      expect(summary.average, 4.5);
      expect(
        summary.distribution.values.reduce((a, b) => a + b),
        summary.count,
      );
      expect(summary.distribution, {5: 5, 4: 2, 3: 1, 2: 0, 1: 0});
      expect(reviews.first.createdAt.isAfter(reviews.last.createdAt), isTrue);
    },
  );
  test('rating filters include only matching ratings', () async {
    final reviews = await repository().getReviews();
    expect(
      filterReviews(reviews, ReviewFilter.five).every((r) => r.rating == 5),
      isTrue,
    );
    expect(filterReviews(reviews, ReviewFilter.four).length, 2);
    expect(filterReviews(reviews, ReviewFilter.threeAndBelow).single.rating, 3);
    expect(filterReviews(reviews, ReviewFilter.all).length, 8);
  });
  test('empty summary does not invent a rating', () {
    final summary = RatingSummary.fromReviews([]);
    expect(summary.average, 0);
    expect(summary.count, 0);
    expect(summary.distribution.values.every((n) => n == 0), isTrue);
  });
  testWidgets('list filters show only the selected reviews', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partnerReviewsRepositoryProvider.overrideWithValue(repository()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PartnerReviewsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('reviews-filter-threeAndBelow')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WorkerReviewTile), findsOneWidget);
    expect(find.text('Review 4'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reviews-filter-four')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkerReviewTile), findsNWidgets(2));
    expect(find.text('Review 4'), findsNothing);
  });
  for (final locale in ['hi', 'ml', 'ta']) {
    testWidgets('ratings fit a small phone in $locale', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            partnerReviewsRepositoryProvider.overrideWithValue(repository()),
          ],
          child: MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PartnerReviewsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
