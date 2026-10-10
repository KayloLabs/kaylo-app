import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_partner/features/earnings/presentation/screens/earnings_screen.dart';
import 'package:kaylo_partner/features/jobs/application/jobs_providers.dart';
import 'package:kaylo_partner/features/jobs/data/pending_jobs_repository.dart';
import 'package:kaylo_partner/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'a live build cannot accept or complete a demo job before integration',
    () async {
      final repo = PendingJobsRepository(initiallyOnline: false);
      addTearDown(repo.dispose);
      for (final action in [
        repo.acceptJob,
        repo.rejectJob,
        repo.advanceJob,
        repo.cancelJob,
      ]) {
        await expectLater(
          action('sample-job'),
          throwsA(isA<LiveJobsPending>()),
        );
      }
      await expectLater(repo.getJobs(), throwsA(isA<LiveJobsPending>()));
    },
  );
  testWidgets(
    'live earnings show unavailable rather than sample or zero income',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PendingJobsRepository(initiallyOnline: false);
      addTearDown(repo.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            jobsRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: EarningsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Live job requests and earnings are not available yet',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('earned today'), findsNothing);
      expect(find.textContaining('₹'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
