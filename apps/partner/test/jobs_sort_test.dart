import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_partner/features/jobs/application/jobs_sort.dart';
import 'package:kaylo_partner/features/jobs/domain/geo.dart';
import 'package:kaylo_partner/features/jobs/domain/job.dart';
import 'package:kaylo_partner/features/jobs/domain/relative_time.dart';
import 'package:kaylo_partner/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Haversine distanceKm', () {
    test(
      'distance between Thottada Beach Rd and City Centre is between 4 and 6 km',
      () {
        // Kadavil House, Thottada Beach Rd: (11.8392, 75.4003)
        // City Centre (Kannur): (11.8745, 75.3704)
        final distance = distanceKm(11.8392, 75.4003, 11.8745, 75.3704);

        expect(distance, greaterThanOrEqualTo(4.0));
        expect(distance, lessThanOrEqualTo(6.0));
        expect(distance, closeTo(5.1, 0.2));
      },
    );

    test('etaMinutes calculates reasonable travel duration', () {
      expect(etaMinutes(0), equals(0));
      // 25 km at 25 km/h = 60 minutes
      expect(etaMinutes(25, speedKmh: 25), equals(60));
      // 5.1 km at 25 km/h = ~12 minutes
      expect(etaMinutes(5.1, speedKmh: 25), equals(12));
    });
  });

  group('Jobs sorting', () {
    final now = DateTime.now();
    final jobA = Job(
      id: 'job-a',
      serviceName: 'Plumbing Repair',
      serviceIcon: 'plumbing',
      customerName: 'Customer A',
      customerPhone: '9999999991',
      addressLine: 'Near Place',
      latitude: 11.8700,
      longitude: 75.3700,
      distanceKm: 1.2,
      scheduledAt: now.add(const Duration(hours: 3)),
      payout: 350.0,
      notes: '',
      stage: JobStage.requested,
    );

    final jobB = Job(
      id: 'job-b',
      serviceName: 'Electrical Wiring',
      serviceIcon: 'electrical',
      customerName: 'Customer B',
      customerPhone: '9999999992',
      addressLine: 'Mid Place',
      latitude: 11.8600,
      longitude: 75.3600,
      distanceKm: 2.5,
      scheduledAt: now.add(const Duration(hours: 1)),
      payout: 800.0,
      notes: '',
      stage: JobStage.requested,
    );

    final jobC = Job(
      id: 'job-c',
      serviceName: 'Appliance Service',
      serviceIcon: 'appliances',
      customerName: 'Customer C',
      customerPhone: '9999999993',
      addressLine: 'Far Place',
      latitude: 11.8400,
      longitude: 75.4000,
      distanceKm: 5.0,
      scheduledAt: now.add(const Duration(hours: 5)),
      payout: 500.0,
      notes: '',
      stage: JobStage.requested,
    );

    final testJobs = [jobC, jobA, jobB];

    test('sorts by Nearest (distanceKm ascending)', () {
      final sorted = sortAndFilterJobs(testJobs, sort: JobSort.nearest);
      expect(
        sorted.map((j) => j.id).toList(),
        equals(['job-a', 'job-b', 'job-c']),
      );
      expect(sorted[0].distanceKm, equals(1.2));
      expect(sorted[1].distanceKm, equals(2.5));
      expect(sorted[2].distanceKm, equals(5.0));
    });

    test('sorts by Highest Payout (payout descending)', () {
      final sorted = sortAndFilterJobs(testJobs, sort: JobSort.highestPayout);
      expect(
        sorted.map((j) => j.id).toList(),
        equals(['job-b', 'job-c', 'job-a']),
      );
      expect(sorted[0].payout, equals(800.0));
      expect(sorted[1].payout, equals(500.0));
      expect(sorted[2].payout, equals(350.0));
    });

    test('sorts by Soonest (scheduledAt ascending)', () {
      final sorted = sortAndFilterJobs(testJobs, sort: JobSort.soonest);
      expect(
        sorted.map((j) => j.id).toList(),
        equals(['job-b', 'job-a', 'job-c']),
      );
      expect(sorted[0].scheduledAt, equals(jobB.scheduledAt));
      expect(sorted[1].scheduledAt, equals(jobA.scheduledAt));
      expect(sorted[2].scheduledAt, equals(jobC.scheduledAt));
    });
  });

  group('Jobs filtering', () {
    final now = DateTime.now();
    final plumbingJob = Job(
      id: 'job-p',
      serviceName: 'Bathroom Plumbing',
      serviceIcon: 'plumbing',
      customerName: 'Customer P',
      customerPhone: '9999999991',
      addressLine: 'Kannur',
      latitude: 11.8700,
      longitude: 75.3700,
      distanceKm: 1.0,
      scheduledAt: now,
      payout: 400.0,
      notes: '',
      stage: JobStage.requested,
    );

    final electricalJob = Job(
      id: 'job-e',
      serviceName: 'Electrical Rewiring',
      serviceIcon: 'electrical',
      customerName: 'Customer E',
      customerPhone: '9999999992',
      addressLine: 'Kannur',
      latitude: 11.8700,
      longitude: 75.3700,
      distanceKm: 2.0,
      scheduledAt: now,
      payout: 600.0,
      notes: '',
      stage: JobStage.requested,
    );

    final carpentryJob = Job(
      id: 'job-c',
      serviceName: 'Carpentry Repair',
      serviceIcon: 'carpentry',
      customerName: 'Customer C',
      customerPhone: '9999999993',
      addressLine: 'Kannur',
      latitude: 11.8700,
      longitude: 75.3700,
      distanceKm: 3.0,
      scheduledAt: now,
      payout: 500.0,
      notes: '',
      stage: JobStage.requested,
    );

    final allJobs = [plumbingJob, electricalJob, carpentryJob];

    test('filtering by service drops non-matching jobs', () {
      final filtered = sortAndFilterJobs(allJobs, serviceFilters: {'Plumbing'});
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('job-p'));
    });

    test('multi-select filtering includes all selected services', () {
      final filtered = sortAndFilterJobs(
        allJobs,
        serviceFilters: {'Plumbing', 'Electrical'},
      );
      expect(filtered.length, equals(2));
      expect(filtered.map((j) => j.id).toSet(), equals({'job-p', 'job-e'}));
    });

    test('clearing service filter restores all jobs', () {
      final filtered = sortAndFilterJobs(allJobs, serviceFilters: {'Plumbing'});
      expect(filtered.length, equals(1));

      final restored = sortAndFilterJobs(allJobs, serviceFilters: <String>{});
      expect(restored.length, equals(3));
    });

    test('empty match returns empty list', () {
      final filtered = sortAndFilterJobs(allJobs, serviceFilters: {'Cleaning'});
      expect(filtered, isEmpty);
    });
  });

  group('JobSort persistence', () {
    test(
      'persists selection to SharedPreferences under partner.job_sort',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        // Default sort should be nearest
        expect(container.read(jobSortProvider), equals(JobSort.nearest));

        // Change to highest payout
        container.read(jobSortProvider.notifier).setSort(JobSort.highestPayout);
        expect(container.read(jobSortProvider), equals(JobSort.highestPayout));
        expect(prefs.getString('partner.job_sort'), equals('highestPayout'));

        // New container reads persisted value
        final container2 = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container2.dispose);
        expect(container2.read(jobSortProvider), equals(JobSort.highestPayout));
      },
    );
  });

  group('formatRelativeScheduled', () {
    testWidgets('formats past and future times accurately', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      final fixedNow = DateTime(2026, 10, 8, 10, 0); // 10:00 AM

      // 12 min ago
      final past = fixedNow.subtract(const Duration(minutes: 12));
      expect(
        formatRelativeScheduled(past, l10n, now: fixedNow),
        equals('12 min ago'),
      );

      // in 45 min
      final futureSoon = fixedNow.add(const Duration(minutes: 45));
      expect(
        formatRelativeScheduled(futureSoon, l10n, now: fixedNow),
        equals('in 45 min'),
      );

      // tomorrow 9:00
      final tomorrow = DateTime(2026, 10, 9, 9, 0);
      expect(
        formatRelativeScheduled(tomorrow, l10n, now: fixedNow),
        equals('tomorrow 9:00'),
      );

      // today 14:30
      final todayLater = DateTime(2026, 10, 8, 14, 30);
      expect(
        formatRelativeScheduled(todayLater, l10n, now: fixedNow),
        equals('today 14:30'),
      );
    });
  });
}
