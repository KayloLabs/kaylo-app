import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/home/application/search_controller.dart';
import 'package:kaylo/features/home/application/user_location_provider.dart';
import 'package:kaylo/features/home/application/voice_search.dart';
import 'package:kaylo/features/home/data/mock_home_repository.dart';
import 'package:kaylo/features/home/presentation/screens/search_screen.dart';
import 'package:kaylo/features/workers/application/workers_providers.dart';
import 'package:kaylo/features/workers/data/mock_workers_repository.dart';
import 'package:kaylo_core/models/service_item.dart';
import 'package:kaylo_core/models/worker.dart';

import 'support/test_app.dart';

Worker worker(
  String id,
  List<String> skills,
  double? price, {
  String location = 'Kochi',
}) => Worker(
  id: id,
  name: id,
  profileImageUrl: '',
  rating: 4.8,
  reviewsCount: 12,
  skillIds: skills,
  location: location,
  trustScore: 80,
  hourlyRate: price,
);

class _ControlledWorkers extends MockWorkersRepository {
  final firstQuery = Completer<List<Worker>>();
  @override
  Future<List<Worker>> searchWorkers(String query) async =>
      query == 'raju' ? firstQuery.future : [];
}

void main() {
  late List<ServiceItem> catalog;
  setUpAll(() async {
    final repository = MockHomeRepository();
    catalog = [
      for (final list in await Future.wait([
        repository.getServicesByCategory('home'),
        repository.getServicesByCategory('farm'),
        repository.getServicesByCategory('care'),
      ]))
        ...list,
    ];
  });

  test(
    'everyday problems return the appropriate trade without incidental hits',
    () {
      final examples = <String, List<String>>{
        'water leaking': ['Plumbing'],
        'I want to harvest coconut': ['Coconut Plucking'],
        'clean my AC': ['AC Service'],
        'the fridge is leaking': ['Appliance Repair'],
        'washing machine needs repair': ['Appliance Repair'],
        'need medicine for my father': ['Medicine Delivery'],
        'trim the overhanging branches': ['Tree Pruning'],
        'clear my plot': ['Plot Clearing'],
        'a plumber and an electrician': ['Electrical', 'Plumbing'],
      };
      for (final entry in examples.entries) {
        expect(
          matchServicesToTranscript(entry.key, catalog).map((s) => s.name),
          unorderedEquals(entry.value),
          reason: entry.key,
        );
      }
    },
  );

  test('every popular service chip resolves to itself first', () {
    for (final service in catalog.where(
      (s) => s.isPopular && s.name != 'More',
    )) {
      expect(
        matchServicesToTranscript(service.name, catalog).first.id,
        service.id,
      );
    }
    expect(matchServicesToTranscript('AC', catalog).map((s) => s.name), [
      'AC Service',
    ]);
  });

  test(
    'both price orders apply to services and workers, unknown rates last',
    () {
      final workers = [
        worker('medium', ['4'], 300),
        worker('unknown', ['4'], null),
        worker('high', ['4'], 500),
        worker('low', ['4'], 150),
      ];
      for (final sort in [SearchSort.priceLowHigh, SearchSort.priceHighLow]) {
        final filters = (category: 'home', sort: sort);
        final services = rankSearchServices('', filters, catalog);
        final expectedPrices = services.map((s) => s.basePrice).toList()
          ..sort();
        expect(
          services.map((s) => s.basePrice),
          sort == SearchSort.priceLowHigh
              ? expectedPrices
              : expectedPrices.reversed,
        );
        expect(
          rankSearchWorkers(workers, filters, catalog).map((w) => w.id),
          sort == SearchSort.priceLowHigh
              ? ['low', 'medium', 'high', 'unknown']
              : ['high', 'medium', 'low', 'unknown'],
        );
      }
    },
  );

  test(
    'category narrowing applies to professionals and deduplicates skills',
    () {
      final farm = worker('farm', ['1'], 250);
      final home = worker('home', ['4'], 300);
      final care = worker('care', ['8'], 400);
      final both = worker('both', ['1', '4'], 350);
      expect(
        rankSearchWorkers(
          [farm, home, care, both, both],
          (category: 'farm', sort: SearchSort.relevance),
          catalog,
        ).map((w) => w.id),
        ['both', 'farm'],
      );
      expect(
        rankSearchServices('water leaking', (
          category: 'farm',
          sort: SearchSort.relevance,
        ), catalog),
        isEmpty,
      );
    },
  );

  test('numeric filter chips can be removed independently', () {
    const filter = WorkerFilter(
      minRating: 4.5,
      maxPrice: 400,
      verifiedOnly: true,
    );
    expect(filter.copyWith(minRating: null).minRating, isNull);
    expect(filter.copyWith(minRating: null).maxPrice, 400);
    expect(filter.copyWith(maxPrice: null).maxPrice, isNull);
    expect(filter.copyWith(maxPrice: null).verifiedOnly, isTrue);
  });

  test(
    'nearby preference uses saved address locality rather than Home label',
    () {
      const address = UserLocation(
        label: 'Home',
        addressLine: 'Fort Road, Kannur, Kerala 670001',
      );
      expect(
        localityScore('Kannur', address),
        greaterThan(localityScore('Kochi', address)),
      );
      expect(localityScore('Kerala', address), 0);
      final unknown = worker('unknown', [], null);
      final priced = worker('priced', [], 500);
      expect(compareWorkerRates(unknown, priced), greaterThan(0));
      expect(
        compareWorkerRates(unknown, priced, descending: true),
        greaterThan(0),
      );
    },
  );

  testWidgets(
    'natural search links a multiskilled worker to the requested service',
    (tester) async {
      useTallPhone(tester);
      await tester.pumpWidget(
        await testApp(
          initialLocation: Routes.search,
          routes: [
            GoRoute(
              path: Routes.search,
              builder: (_, _) =>
                  const SearchScreen(initialQuery: 'water leaking'),
            ),
            GoRoute(
              path: Routes.workerProfile,
              builder: (_, state) => Scaffold(
                body: Text(
                  'selected-service:${state.uri.queryParameters['serviceId']}',
                ),
              ),
            ),
          ],
        ),
      );
      await settle(tester);
      await tester.tap(find.text('Raju K.'));
      await settle(tester);
      expect(
        find.text('selected-service:4'),
        findsOneWidget,
        reason: 'Raju first lists coconut, but this search is for plumbing',
      );
    },
  );

  testWidgets(
    'an earlier response cannot replace a newer query during debounce',
    (tester) async {
      useTallPhone(tester);
      final repository = _ControlledWorkers();
      await tester.pumpWidget(
        await testApp(
          initialLocation: Routes.search,
          routes: [
            GoRoute(
              path: Routes.search,
              builder: (_, _) => const SearchScreen(),
            ),
          ],
          overrides: [workersRepositoryProvider.overrideWithValue(repository)],
        ),
      );
      await settle(tester);
      final context = tester.element(find.byType(SearchScreen));
      final container = ProviderScope.containerOf(context);
      final notifier = container.read(searchControllerProvider.notifier);
      notifier.onQueryChanged('raju');
      await tester.pump(const Duration(milliseconds: 350));
      notifier.onQueryChanged('water leaking');
      repository.firstQuery.complete([
        worker('Stale worker', ['1'], 300),
      ]);
      await tester.pump(const Duration(milliseconds: 50));
      expect(container.read(searchControllerProvider).results.workers, isEmpty);
      expect(container.read(searchControllerProvider).isLoading, isTrue);
      await settle(tester);
      expect(
        container.read(searchControllerProvider).results.services.single.name,
        'Plumbing',
      );
      expect(
        container
            .read(searchControllerProvider)
            .results
            .workers
            .map((w) => w.name),
        isNot(contains('Stale worker')),
      );
    },
  );
}
