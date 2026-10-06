import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/features/workers/application/workers_providers.dart';
import 'package:kaylo/features/workers/presentation/screens/worker_profile_screen.dart';
import 'package:kaylo/features/workers/presentation/widgets/worker_verification_record.dart';
import 'package:kaylo_core/models/worker.dart';

import 'support/test_app.dart';

Worker _worker({bool verified = true}) => Worker(
  id: 'worker-reference-123',
  name: 'Anjali Very Long Professional Name That Should Wrap',
  profileImageUrl: '',
  rating: 4.5,
  reviewsCount: 1,
  skillIds: ['4'],
  location: 'Kannur',
  trustScore: 88,
  isVerified: verified,
);

Future<Widget> _app({bool verified = true, bool record = false}) => testApp(
  initialLocation: '/worker',
  routes: [
    GoRoute(
      path: '/worker',
      builder: (_, _) => record
          ? const WorkerVerificationRecord(workerId: 'worker-reference-123')
          : const WorkerProfileScreen(workerId: 'worker-reference-123'),
    ),
  ],
  overrides: [
    workerDetailProvider(
      'worker-reference-123',
    ).overrideWith((ref) async => _worker(verified: verified)),
    workerReviewsProvider(
      'worker-reference-123',
    ).overrideWith((ref) async => []),
  ],
);

void main() {
  testWidgets('verified badge opens a truthful Kaylo record', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await _app());
    await settle(tester);
    expect(tester.takeException(), isNull, reason: 'long names must wrap');
    expect(find.text('Government ID verified'), findsNothing);
    expect(find.text('Police clearance verified'), findsNothing);
    expect(find.text('Kaylo skill certified'), findsNothing);

    await tester.tap(find.byTooltip('View verification record'));
    await settle(tester);
    expect(find.byType(WorkerVerificationRecord), findsOneWidget);
    expect(find.text('worker-reference-123'), findsOneWidget);
    expect(find.text('Verified on Kaylo'), findsOneWidget);
    expect(
      find.textContaining('Supporting documents and check details'),
      findsOneWidget,
    );
    expect(find.text('Listed services'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unverified profiles cannot open a verified record', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(await _app(verified: false));
    await settle(tester);
    expect(find.byTooltip('View verification record'), findsNothing);
    expect(find.text('Not yet verified'), findsOneWidget);
    expect(find.text('Verified on Kaylo'), findsNothing);
    expect(find.text('Government ID verified'), findsNothing);
  });

  testWidgets('record checks current status rather than assuming verified', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(await _app(verified: false, record: true));
    await settle(tester);
    expect(find.text('Not yet verified'), findsOneWidget);
    expect(find.text('Verified on Kaylo'), findsNothing);
  });
}
