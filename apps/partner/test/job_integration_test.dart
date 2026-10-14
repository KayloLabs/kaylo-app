import 'partner_tab_bar_test.dart' show createHarness, signIn;
import 'package:kaylo_partner/features/jobs/application/jobs_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_partner/core/widgets/partner_tab_bar.dart';
import 'package:kaylo_partner/features/jobs/application/jobs_sort.dart';
import 'package:kaylo_partner/features/jobs/data/supabase_jobs_repository.dart';
import 'package:kaylo_ui/widgets/liquid_nav_surface.dart';
import 'supabase_jobs_repository_test.dart' show row;

void main() {
  testWidgets(
    'an unmatched filter explains the empty list and can be cleared',
    (tester) async {
      final (container, app) = await createHarness();
      await tester.pumpWidget(app);
      await signIn(tester);
      container.read(jobServiceFilterProvider.notifier).toggle('unmatched');
      await tester.pumpAndSettle();
      expect(find.text('No jobs match your filter'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('No jobs match your filter'), findsNothing);
      expect(container.read(jobServiceFilterProvider), isEmpty);
      await container.read(jobsRepositoryProvider).setDuty(false);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );
  test('live coordinates remain absent when the server hides them', () {
    final hidden = partnerJobFromRow(row());
    expect(hidden.latitude, isNull);
    expect(hidden.longitude, isNull);
    final visible = partnerJobFromRow(
      row()..addAll({'latitude': 11.8, 'longitude': 75.4}),
    );
    expect(visible.latitude, 11.8);
    expect(visible.longitude, 75.4);
    expect(visible.distanceKm, isNull);
  });
  test('nearest sorts unknown distances last with deterministic ties', () {
    final unknown = partnerJobFromRow(row(id: 'unknown'));
    final a = partnerJobFromRow(row(id: 'a')).copyWith(distanceKm: 2);
    final b = partnerJobFromRow(row(id: 'b')).copyWith(distanceKm: 2);
    expect(sortAndFilterJobs([unknown, b, a]).map((x) => x.id), [
      'a',
      'b',
      'unknown',
    ]);
  });
  test('service filters match categories exactly rather than substrings', () {
    final plumbing = partnerJobFromRow(row());
    expect(jobMatchesServiceFilter(plumbing, {'plumb'}), isFalse);
    expect(jobMatchesServiceFilter(plumbing, {'Plumbing'}), isTrue);
    expect(jobMatchesServiceFilter(plumbing, {'electrical'}), isFalse);
  });
  testWidgets('four-tab glass drag commits on release and preserves alerts', (
    tester,
  ) async {
    final selections = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: PartnerTabBar(
                currentIndex: 0,
                onSelected: selections.add,
                items: const [
                  PartnerTabItem(
                    icon: Icons.work_outline,
                    selectedIcon: Icons.work,
                    label: 'Jobs',
                  ),
                  PartnerTabItem(
                    icon: Icons.bar_chart_outlined,
                    selectedIcon: Icons.bar_chart,
                    label: 'Earnings',
                  ),
                  PartnerTabItem(
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'Profile',
                  ),
                  PartnerTabItem(
                    icon: Icons.notifications_none,
                    selectedIcon: Icons.notifications,
                    label: 'Alerts',
                    badgeCount: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final surface = tester.widget<LiquidNavSurface>(
      find.byType(LiquidNavSurface),
    );
    expect(surface.count, 4);
    expect(find.text('3'), findsOneWidget);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byTooltip('Jobs')),
    );
    await gesture.moveTo(tester.getCenter(find.byTooltip('Alerts')));
    await tester.pump();
    expect(selections, isEmpty);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selections, [3]);
    expect(tester.takeException(), isNull);
  });
}
