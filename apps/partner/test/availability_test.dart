import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_partner/core/router/app_router.dart';
import 'package:kaylo_partner/features/availability/application/availability_providers.dart';
import 'package:kaylo_partner/features/availability/data/mock_availability_repository.dart';
import 'package:kaylo_partner/features/availability/domain/availability.dart';
import 'package:kaylo_partner/features/jobs/application/jobs_providers.dart';
import 'package:kaylo_partner/l10n/generated/app_localizations.dart';
import 'package:kaylo_ui/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, Widget)> createHarness() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  final router = container.read(partnerRouterProvider);
  return (
    container,
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

Future<void> signIn(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'NewKayloPass123!');
  await tester.enterText(find.byType(TextFormField).at(1), 'NewKayloPass123!');
  await tester.tap(find.text('Save password'));
  await tester.pumpAndSettle();
}

Future<void> shutDown(WidgetTester tester, ProviderContainer container) async {
  await container.read(jobsRepositoryProvider).setDuty(false);
  await tester.pumpWidget(const SizedBox.shrink());
  container.dispose();
}

void main() {
  group('WeeklyHours', () {
    test('defaults are Monday to Saturday, 8 to 19, Sunday off', () {
      final hours = WeeklyHours.defaults();
      expect(hours.days.length, 7);
      expect(hours[1].works, isTrue);
      expect(hours[7].works, isFalse);
      expect(hours.workingDays.length, 6);
      expect(hours.hasOneWindow, isTrue);
      expect(hours.isValid, isTrue);
    });

    test('a window ending before it starts is invalid', () {
      final hours = WeeklyHours.defaults().withDay(
        const DayHours(weekday: 2, startMinutes: 600, endMinutes: 540),
      );
      expect(hours.isValid, isFalse);
      expect(
        hours.withDay(const DayHours(weekday: 2, works: false)).isValid,
        isTrue,
      );
    });

    test('rows round-trip through the table column names', () {
      final hours = WeeklyHours.defaults().withDay(
        const DayHours(
          weekday: 3,
          startMinutes: 9 * 60 + 30,
          endMinutes: 17 * 60,
        ),
      );
      final json = hours.toJson();
      expect(json[2], {
        'weekday': 3,
        'works': true,
        'start_time': '09:30',
        'end_time': '17:00',
      });
      expect(WeeklyHours.fromJson(json), hours);
      expect(hours.hasOneWindow, isFalse);
      // Missing weekdays fall back to the defaults.
      expect(WeeklyHours.fromJson([json[0]])[7].works, isFalse);
      expect(
        DayHours.fromJson({
          'weekday': 1,
          'start_time': '08:00:00',
          'end_time': '19:00:00',
        }).endMinutes,
        19 * 60,
      );
    });
  });

  test('a time off covers whole days', () {
    final off = TimeOff(
      id: 'x',
      startsOn: DateTime(2026, 10, 20),
      endsOn: DateTime(2026, 10, 22),
    );
    expect(off.dayCount, 3);
    expect(off.covers(DateTime(2026, 10, 22, 23, 59)), isTrue);
    expect(off.covers(DateTime(2026, 10, 23)), isFalse);
    expect(TimeOff.fromJson(off.toJson()).endsOn, DateTime(2026, 10, 22));
  });

  group('MockAvailabilityRepository', () {
    test('saves hours and keeps only current and upcoming days off', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = MockAvailabilityRepository(prefs);
      addTearDown(repo.dispose);

      final hours = WeeklyHours.defaults().withDay(
        const DayHours(weekday: 7, works: true),
      );
      await repo.saveWeeklyHours(hours);
      expect(await repo.watchWeeklyHours().first, hours);

      final now = DateTime.now();
      await repo.addTimeOff(
        startsOn: now.subtract(const Duration(days: 10)),
        endsOn: now.subtract(const Duration(days: 8)),
      );
      final kept = await repo.addTimeOff(
        startsOn: now.add(const Duration(days: 3)),
        endsOn: now.add(const Duration(days: 4)),
        reason: '  Temple festival ',
      );
      final listed = await repo.watchTimeOff().first;
      expect(listed.map((t) => t.id), [kept.id]);
      expect(listed.single.reason, 'Temple festival');

      await repo.removeTimeOff(kept.id);
      expect(await repo.watchTimeOff().first, isEmpty);

      expect(
        () => repo.addTimeOff(
          startsOn: now.add(const Duration(days: 2)),
          endsOn: now,
        ),
        throwsArgumentError,
      );
      expect(
        () => repo.saveWeeklyHours(
          hours.withDay(
            const DayHours(weekday: 1, startMinutes: 600, endMinutes: 540),
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  testWidgets('the availability screen edits hours and removes days off', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 9000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final (container, app) = await createHarness();
    final repo = container.read(availabilityRepositoryProvider);
    final now = DateTime.now();
    await repo.addTimeOff(
      startsOn: now.add(const Duration(days: 5)),
      endsOn: now.add(const Duration(days: 6)),
      reason: 'Onam',
    );
    await tester.pumpWidget(app);
    await signIn(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage availability'));
    await tester.pumpAndSettle();

    expect(find.text('My availability'), findsOneWidget);
    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Sunday'), findsOneWidget);
    expect(find.text('Day off'), findsOneWidget);
    expect(find.text('8:00 AM'), findsNWidgets(6));
    expect(find.text('2 days · Onam'), findsOneWidget);

    // Sunday becomes a working day; the hours only change once saved.
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(find.text('Day off'), findsNothing);
    expect((await repo.watchWeeklyHours().first)![7].works, isFalse);

    await tester.tap(find.text('Save hours'));
    await tester.pumpAndSettle();
    expect(find.text('Working hours saved'), findsOneWidget);
    expect((await repo.watchWeeklyHours().first)![7].works, isTrue);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Days off removed'), findsOneWidget);
    expect(find.text('No days off planned'), findsOneWidget);
    expect(await repo.watchTimeOff().first, isEmpty);

    // Back on the profile, the summary follows the saved hours.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Mon – Sun · 8:00 AM – 7:00 PM'), findsOneWidget);
    await shutDown(tester, container);
  });
}
