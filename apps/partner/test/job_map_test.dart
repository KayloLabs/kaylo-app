import 'package:shared_preferences/shared_preferences.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_partner/features/jobs/application/partner_location.dart';
import 'package:kaylo_core/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_partner/core/router/routes.dart';
import 'package:kaylo_partner/features/jobs/application/jobs_providers.dart';
import 'package:kaylo_partner/features/jobs/domain/job.dart';
import 'package:kaylo_partner/features/jobs/presentation/screens/job_detail_screen.dart';
import 'package:kaylo_partner/features/jobs/presentation/screens/job_map_screen.dart';
import 'package:kaylo_partner/features/jobs/presentation/widgets/job_map.dart';
import 'package:kaylo_partner/l10n/generated/app_localizations.dart';
import 'package:kaylo_ui/theme/app_theme.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });
  final testJob = Job(
    id: 'test-job-1',
    serviceName: 'Plumbing Repair',
    serviceIcon: 'plumbing',
    customerName: 'Anjali Menon',
    customerPhone: '9847012345',
    addressLine: 'Kadavil House, Thottada Beach Rd',
    latitude: 11.8392,
    longitude: 75.4003,
    distanceKm: 5.1,
    scheduledAt: DateTime.now().add(const Duration(hours: 2)),
    payout: 450.0,
    notes: 'Please check kitchen sink pipe leak',
    stage: JobStage.requested,
  );

  Widget buildTestableWidget({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        jobMapTilesProvider.overrideWithValue(false),
        partnerLocationProvider.overrideWith(
          (ref) async => const ResolvedLocation(
            latitude: 11.8745,
            longitude: 75.3704,
            label: 'Test',
          ),
        ),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  group('JobMap widget', () {
    testWidgets('pumps JobMap(showTiles: false) and finds both markers', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: JobMap(
            job: testJob,
            height: 250,
            showTiles: false,
            showExpandButton: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find worker marker dot
      expect(find.byKey(const Key('worker_marker')), findsOneWidget);

      // Find customer marker pin
      expect(find.byKey(const Key('customer_marker')), findsOneWidget);

      // Find OpenStreetMap attribution
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);

      // Find Expand button
      expect(find.text('Expand'), findsOneWidget);
    });

    testWidgets('renders Google Maps action button when callback provided', (
      tester,
    ) async {
      bool googleMapsTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: JobMap(
            job: testJob,
            height: 250,
            showTiles: false,
            showExpandButton: false,
            onOpenGoogleMaps: () {
              googleMapsTapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open in Google Maps'), findsOneWidget);
      await tester.tap(find.text('Open in Google Maps'));
      expect(googleMapsTapped, isTrue);
    });
  });

  group('JobDetailScreen with JobMap', () {
    testWidgets('displays the job map and customer details', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          overrides: [
            jobDetailProvider(
              testJob.id,
            ).overrideWith((ref) => Stream.value(testJob)),
          ],
          child: JobDetailScreen(jobId: testJob.id),
        ),
      );
      await tester.pumpAndSettle();

      // Verify JobMap widget is present
      expect(find.byType(JobMap), findsOneWidget);

      // Verify both markers inside JobMap
      expect(find.byKey(const Key('worker_marker')), findsOneWidget);
      expect(find.byKey(const Key('customer_marker')), findsOneWidget);

      // Verify distance and ETA text

      // Verify address and customer details
      expect(find.text(testJob.customerName), findsOneWidget);
      expect(find.text(testJob.addressLine), findsOneWidget);
    });
  });

  group('JobMapScreen full-screen interactive view', () {
    testWidgets('displays full-screen map, job card, and Google Maps button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          overrides: [
            jobDetailProvider(
              testJob.id,
            ).overrideWith((ref) => Stream.value(testJob)),
          ],
          child: JobMapScreen(jobId: testJob.id, showTiles: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Job Location Map'), findsOneWidget);
      expect(find.text('Open in Google Maps'), findsOneWidget);
      expect(find.text(testJob.customerName), findsOneWidget);
      expect(find.text(testJob.addressLine), findsOneWidget);
      expect(find.byType(JobMap), findsOneWidget);
    });

    testWidgets('expand button in JobMap navigates to /jobs/:id/map', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/jobs/${testJob.id}',
        routes: [
          GoRoute(
            path: '/jobs/:id',
            builder: (context, state) =>
                JobDetailScreen(jobId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: Routes.jobMapRoute,
            builder: (context, state) => JobMapScreen(
              jobId: state.pathParameters['id']!,
              showTiles: false,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            jobMapTilesProvider.overrideWithValue(false),
            jobDetailProvider(
              testJob.id,
            ).overrideWith((ref) => Stream.value(testJob)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Expand button
      expect(find.text('Expand'), findsOneWidget);
      await tester.tap(find.text('Expand'));
      await tester.pumpAndSettle();

      // Should now be on the JobMapScreen
      expect(find.text('Job Location Map'), findsOneWidget);
    });
  });
}
