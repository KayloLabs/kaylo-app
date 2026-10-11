import 'support/stream_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_partner/features/jobs/domain/job.dart';
import 'package:kaylo_partner/features/notifications/application/alerts_providers.dart';
import 'package:kaylo_partner/features/notifications/data/mock_partner_notifications_repository.dart';
import 'package:kaylo_partner/features/notifications/presentation/screens/alerts_screen.dart';
import 'package:kaylo_partner/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/round2_jobs.dart';

void main() {
  testWidgets(
    'new request creates an alert and unread badge, mark all clears it',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final jobs = Round2JobsRepository([]);
      final repo = MockPartnerNotificationsRepository(jobs, prefs);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [partnerAlertsRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: const PartnerAlertsScreen(),
                bottomNavigationBar: Badge.count(
                  key: const Key('unread-alert-badge'),
                  count: ref.watch(partnerAlertUnreadProvider),
                  isLabelVisible: ref.watch(partnerAlertUnreadProvider) > 0,
                  child: const Icon(Icons.notifications_outlined),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      jobs.add(round2Job('new-request', stage: JobStage.requested));
      await tester.pumpAndSettle();
      expect(find.text('New job request'), findsOneWidget);
      expect(
        tester
            .widget<Badge>(find.byKey(const Key('unread-alert-badge')))
            .isLabelVisible,
        isTrue,
      );
      expect(find.text('1'), findsOneWidget);
      expect(repo.unreadCount, 1);
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();
      expect(repo.unreadCount, 0);
      expect(
        tester
            .widget<Badge>(find.byKey(const Key('unread-alert-badge')))
            .isLabelVisible,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
      repo.dispose();
      final again = MockPartnerNotificationsRepository(jobs, prefs);
      await tester.pump();
      expect(
        (await streamSnapshot(tester, again.watchAll())).single.isRead,
        isTrue,
      );
      again.dispose();
      jobs.dispose();
    },
  );
  testWidgets('disabled request notifications are never created', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'partner.notify_requests': false});
    final jobs = Round2JobsRepository([]);
    final repo = MockPartnerNotificationsRepository(
      jobs,
      await SharedPreferences.getInstance(),
    );
    jobs.add(round2Job('request', stage: JobStage.requested));
    await tester.pump();
    expect(await streamSnapshot(tester, repo.watchAll()), isEmpty);
    expect(repo.unreadCount, 0);
    repo.dispose();
    jobs.dispose();
  });
  testWidgets(
    'stage updates derive one job alert and respect job preferences',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final jobs = Round2JobsRepository([round2Job('active')]);
      final repo = MockPartnerNotificationsRepository(jobs, prefs);
      await tester.pump();
      expect(await streamSnapshot(tester, repo.watchAll()), isEmpty);
      jobs.setStage('active', JobStage.onTheWay);
      await tester.pump();
      expect(
        (await streamSnapshot(tester, repo.watchAll())).single.event,
        'onTheWay',
      );
      jobs.setStage('active', JobStage.onTheWay);
      await tester.pump();
      expect((await streamSnapshot(tester, repo.watchAll())).length, 1);
      await prefs.setBool('partner.notify_jobs', false);
      jobs.setStage('active', JobStage.arrived);
      await tester.pump();
      expect((await streamSnapshot(tester, repo.watchAll())).length, 1);
      repo.dispose();
      jobs.dispose();
    },
  );
}
