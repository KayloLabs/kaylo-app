import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaylo_core/models/worker.dart';
import 'package:kaylo_core/models/service_item.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/home/application/home_providers.dart';
import 'package:kaylo/features/home/application/user_location_provider.dart';
import 'package:kaylo/features/home/data/mock_home_repository.dart';
import 'package:kaylo/features/home/domain/home_repository.dart';
import 'package:kaylo/features/home/presentation/screens/service_details_screen.dart';
import 'package:kaylo/features/workers/data/mock_workers_repository.dart';
import 'package:kaylo/features/workers/application/workers_providers.dart';
import 'package:kaylo/features/workers/presentation/screens/worker_profile_screen.dart';
import 'package:kaylo/features/care/data/mock_care_repository.dart';
import 'package:kaylo/features/care/domain/models/appointment.dart';
import 'package:kaylo/features/care/domain/models/caregiver.dart';
import 'package:kaylo/features/care/presentation/screens/doctor_appointment_screen.dart';
import 'support/test_app.dart';

void main() {
  group('M3 - Home Services & Catalog Tests', () {
    late HomeRepository homeRepo;

    setUp(() {
      homeRepo = MockHomeRepository();
    });

    test(
      'getServicesByCategory("home") returns all 7 core home services',
      () async {
        final services = await homeRepo.getServicesByCategory('home');
        expect(services.length, greaterThanOrEqualTo(7));

        final names = services.map((s) => s.name).toList();
        expect(names, contains('Plumbing'));
        expect(names, contains('Electrical'));
        expect(names, contains('Carpentry'));
        expect(names, contains('Painting'));
        expect(names, contains('House Cleaning'));
        expect(names, contains('AC Service'));
        expect(names, contains('Appliance Repair'));
      },
    );

    test('getServiceById returns the requested service', () async {
      final service = await homeRepo.getServiceById('4');
      expect(service, isNotNull);
      expect(service!.name, equals('Plumbing'));
      expect(service.basePrice, equals(500.0));
    });

    test('searchServices matches substring query case-insensitively', () async {
      final results = await homeRepo.searchServices('PLUMB');
      expect(results, isNotEmpty);
      expect(results.first.name, equals('Plumbing'));
    });
  });

  group('M3 - Workers, Reviews, Filter & Sort Tests', () {
    late MockWorkersRepository workersRepo;

    setUp(() {
      workersRepo = MockWorkersRepository();
    });

    test('searchWorkers matches worker name and district', () async {
      final byName = await workersRepo.searchWorkers('Suresh');
      expect(byName.map((w) => w.id), equals(['w3']));

      final byDistrict = await workersRepo.searchWorkers('kannur');
      expect(byDistrict.map((w) => w.id), equals(['w10']));

      expect(await workersRepo.searchWorkers('   '), isEmpty);
    });

    test(
      'searchWorkers returns the same workers the service lists do',
      () async {
        final searched = await workersRepo.searchWorkers('Raju');
        final listed = await workersRepo.getWorkersByServiceId('4');
        expect(searched.single.id, equals('w1'));
        expect(listed.any((w) => w.id == 'w1'), isTrue);
      },
    );

    test('getWorkersByService returns workers with rich metadata', () async {
      final workers = await workersRepo.getWorkersByServiceId('1'); // Plumbing
      expect(workers, isNotEmpty);
      for (final w in workers) {
        expect(w.rating, inInclusiveRange(1.0, 5.0));
        expect(w.hourlyRate, greaterThan(0));
        expect(w.totalJobs, greaterThanOrEqualTo(0));
        expect(w.trustScore, greaterThan(0));
      }
    });

    test(
      'getReviewsForWorker returns review list with ratings and comments',
      () async {
        final reviews = await workersRepo.getReviewsForWorker('w1');
        expect(reviews, isNotEmpty);
        expect(reviews.first.customerName, isNotEmpty);
        expect(reviews.first.comment, isNotEmpty);
        expect(reviews.first.rating, inInclusiveRange(1.0, 5.0));
      },
    );

    test('filteredWorkersProvider correctly applies filter and sort', () async {
      final container = ProviderContainer(
        overrides: [workersRepositoryProvider.overrideWithValue(workersRepo)],
      );
      addTearDown(container.dispose);

      // 1. Initial list for plumbing
      final initialWorkers = await container.read(
        filteredWorkersProvider('1').future,
      );
      expect(initialWorkers, isNotEmpty);

      // 2. Filter by minRating 4.8
      container
          .read(workerFilterSortProvider.notifier)
          .updateFilter(const WorkerFilter(minRating: 4.8));
      final ratingFiltered = await container.read(
        filteredWorkersProvider('1').future,
      );
      for (final w in ratingFiltered) {
        expect(w.rating, greaterThanOrEqualTo(4.8));
      }

      // 3. Filter by maxPrice 350
      container
          .read(workerFilterSortProvider.notifier)
          .updateFilter(const WorkerFilter(maxPrice: 350));
      final priceFiltered = await container.read(
        filteredWorkersProvider('1').future,
      );
      for (final w in priceFiltered) {
        expect(w.hourlyRate, lessThanOrEqualTo(350));
      }

      // 4. Sort by priceLowToHigh
      container
          .read(workerFilterSortProvider.notifier)
          .setSort(WorkerSort.priceLowToHigh);
      final sortedLowToHigh = await container.read(
        filteredWorkersProvider('1').future,
      );
      for (int i = 0; i < sortedLowToHigh.length - 1; i++) {
        expect(
          sortedLowToHigh[i].hourlyRate!,
          lessThanOrEqualTo(sortedLowToHigh[i + 1].hourlyRate!),
        );
      }

      // 5. Sort by rating
      container
          .read(workerFilterSortProvider.notifier)
          .setSort(WorkerSort.rating);
      final sortedByRating = await container.read(
        filteredWorkersProvider('1').future,
      );
      for (int i = 0; i < sortedByRating.length - 1; i++) {
        expect(
          sortedByRating[i].rating,
          greaterThanOrEqualTo(sortedByRating[i + 1].rating),
        );
      }
    });
  });

  group(
    'M3 - Care Features (Doctor Appointment & Caregiver Booking) Tests',
    () {
      late MockCareRepository careRepo;

      setUp(() {
        careRepo = MockCareRepository();
      });

      test('getDoctors returns doctor list and filters by specialty', () async {
        final allDoctors = await careRepo.getDoctors();
        expect(allDoctors.length, greaterThanOrEqualTo(4));

        final cardiologists = await careRepo.getDoctors(
          specialty: 'Cardiologist',
        );
        expect(cardiologists, isNotEmpty);
        for (final doc in cardiologists) {
          expect(doc.specialty, equals('Cardiologist'));
        }
      });

      test('bookDoctorAppointment persists appointment record', () async {
        final apt = DoctorAppointment(
          id: 'apt_test_1',
          doctorId: 'doc1',
          doctorName: 'Dr. Jacob Abraham',
          specialty: 'General Physician',
          hospital: 'Lakeshore Hospital',
          date: DateTime.now().add(const Duration(days: 1)),
          timeSlot: '10:00 AM',
          consultationType: 'homeVisit',
          status: 'confirmed',
          patientName: 'Kunjamma V.',
        );

        final booked = await careRepo.bookDoctorAppointment(apt);
        expect(booked.id, equals('apt_test_1'));

        final appointments = await careRepo.getDoctorAppointments();
        expect(appointments.any((a) => a.id == 'apt_test_1'), isTrue);
      });

      test(
        'getCaregivers returns verified caregivers with hourly rates',
        () async {
          final caregivers = await careRepo.getCaregivers();
          expect(caregivers, isNotEmpty);
          for (final cg in caregivers) {
            expect(cg.hourlyRate, greaterThan(0));
            expect(cg.specialties, isNotEmpty);
          }
        },
      );

      test('bookCaregiver records caregiver booking', () async {
        final record = CaregiverBookingRecord(
          id: 'cgb_test_1',
          caregiverId: 'cg1',
          caregiverName: 'Mary Varghese',
          date: DateTime.now().add(const Duration(days: 2)),
          startTime: '09:00 AM',
          hours: 4,
          hourlyRate: 250,
          totalAmount: 1000,
          careType: 'Elderly Care',
          status: 'confirmed',
        );

        final booked = await careRepo.bookCaregiver(record);
        expect(booked.id, equals('cgb_test_1'));
        expect(booked.totalAmount, equals(1000.0));

        final bookings = await careRepo.getCaregiverBookings();
        expect(bookings.any((b) => b.id == 'cgb_test_1'), isTrue);
      });
    },
  );

  group('M3 - Review Polish & Discovery Verification Tests', () {
    testWidgets('Worker profile shows real rating and review count, no < 30m', (
      tester,
    ) async {
      useTallPhone(tester);
      final worker = Worker(
        id: 'w_test_1',
        name: 'Suresh Babu',
        profileImageUrl: '',
        rating: 4.8,
        reviewsCount: 124,
        skillIds: const ['1'],
        location: 'Kochi',
        trustScore: 95,
        isVerified: true,
        hourlyRate: 350,
        totalJobs: 88,
      );

      final widget = await testApp(
        initialLocation: Routes.workerProfile,
        routes: [
          GoRoute(
            path: Routes.workerProfile,
            builder: (_, _) => WorkerProfileScreen(
              workerId: 'w_test_1',
              initialWorker: worker,
            ),
          ),
        ],
        overrides: [
          workerDetailProvider('w_test_1').overrideWith((ref) async => worker),
          workerReviewsProvider('w_test_1').overrideWith((ref) async => []),
        ],
      );

      await tester.pumpWidget(widget);
      await settle(tester);

      expect(find.text('4.8'), findsWidgets);
      expect(find.text('124'), findsOneWidget);
      expect(find.textContaining('< 30m'), findsNothing);
    });

    testWidgets(
      'Verified worker exposes a record without inventing qualification checks',
      (tester) async {
        useTallPhone(tester);
        final verifiedWorker = Worker(
          id: 'w_ver',
          name: 'Verified Raju',
          profileImageUrl: '',
          rating: 4.5,
          reviewsCount: 10,
          skillIds: const ['1'],
          location: 'Kochi',
          trustScore: 90,
          totalJobs: 20,
          isVerified: true,
          hourlyRate: 300,
        );

        final appVerified = await testApp(
          initialLocation: Routes.workerProfile,
          routes: [
            GoRoute(
              path: Routes.workerProfile,
              builder: (_, _) => WorkerProfileScreen(
                workerId: 'w_ver',
                initialWorker: verifiedWorker,
              ),
            ),
          ],
          overrides: [
            workerDetailProvider(
              'w_ver',
            ).overrideWith((ref) async => verifiedWorker),
            workerReviewsProvider('w_ver').overrideWith((ref) async => []),
          ],
        );
        await tester.pumpWidget(appVerified);
        await settle(tester);

        expect(find.text('Verified on Kaylo'), findsOneWidget);
        expect(find.text('View verification record'), findsOneWidget);
        expect(find.text('Government ID verified'), findsNothing);
        expect(find.text('Police clearance verified'), findsNothing);
        expect(find.text('Kaylo skill certified'), findsNothing);
      },
    );

    testWidgets(
      'Unverified worker has no certification or implied check in progress',
      (tester) async {
        useTallPhone(tester);
        final unverifiedWorker = Worker(
          id: 'w_unver',
          name: 'Unverified Babu',
          profileImageUrl: '',
          rating: 4.0,
          reviewsCount: 5,
          skillIds: const ['1'],
          location: 'Kozhikode',
          trustScore: 70,
          totalJobs: 10,
          isVerified: false,
          hourlyRate: 250,
        );

        final appUnverified = await testApp(
          initialLocation: Routes.workerProfile,
          routes: [
            GoRoute(
              path: Routes.workerProfile,
              builder: (_, _) => WorkerProfileScreen(
                workerId: 'w_unver',
                initialWorker: unverifiedWorker,
              ),
            ),
          ],
          overrides: [
            workerDetailProvider(
              'w_unver',
            ).overrideWith((ref) async => unverifiedWorker),
            workerReviewsProvider('w_unver').overrideWith((ref) async => []),
          ],
        );
        await tester.pumpWidget(appUnverified);
        await settle(tester);

        expect(find.text('Not yet verified'), findsOneWidget);
        expect(find.text('View verification record'), findsNothing);
        expect(find.text('Government ID verified'), findsNothing);
      },
    );

    testWidgets('Service Details shows computed rating from worker reviews', (
      tester,
    ) async {
      useTallPhone(tester);
      final testService = ServiceItem(
        id: 'srv_1',
        name: 'Plumbing',
        category: 'home',
        basePrice: 500,
        description: 'Plumbing service',
        iconPath: '',
        isPopular: true,
      );

      final appWithReviews = await testApp(
        initialLocation: Routes.serviceDetails,
        routes: [
          GoRoute(
            path: Routes.serviceDetails,
            builder: (_, _) => ServiceDetailsScreen(
              serviceId: 'srv_1',
              initialService: testService,
            ),
          ),
        ],
        overrides: [
          serviceDetailProvider(
            'srv_1',
          ).overrideWith((ref) async => testService),
          workerListProvider('srv_1').overrideWith(
            (ref) async => [
              Worker(
                id: 'w1',
                name: 'Worker 1',
                profileImageUrl: '',
                rating: 4.0,
                reviewsCount: 10,
                skillIds: const ['1'],
                location: 'Kochi',
                trustScore: 85,
                totalJobs: 15,
                isVerified: true,
                hourlyRate: 300,
              ),
              Worker(
                id: 'w2',
                name: 'Worker 2',
                profileImageUrl: '',
                rating: 5.0,
                reviewsCount: 10,
                skillIds: const ['1'],
                location: 'Kochi',
                trustScore: 92,
                totalJobs: 25,
                isVerified: true,
                hourlyRate: 350,
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(appWithReviews);
      await settle(tester);

      // Weighted average: (4.0*10 + 5.0*10)/20 = 4.5
      expect(find.text('4.5'), findsOneWidget);
    });

    testWidgets('Service Details shows "New" when workers have no reviews', (
      tester,
    ) async {
      useTallPhone(tester);
      final testService = ServiceItem(
        id: 'srv_1',
        name: 'Plumbing',
        category: 'home',
        basePrice: 500,
        description: 'Plumbing service',
        iconPath: '',
        isPopular: true,
      );

      final appNoReviews = await testApp(
        initialLocation: Routes.serviceDetails,
        routes: [
          GoRoute(
            path: Routes.serviceDetails,
            builder: (_, _) => ServiceDetailsScreen(
              serviceId: 'srv_1',
              initialService: testService,
            ),
          ),
        ],
        overrides: [
          serviceDetailProvider(
            'srv_1',
          ).overrideWith((ref) async => testService),
          workerListProvider('srv_1').overrideWith(
            (ref) async => [
              Worker(
                id: 'w3',
                name: 'Worker 3',
                profileImageUrl: '',
                rating: 0.0,
                reviewsCount: 0,
                skillIds: const ['1'],
                location: 'Kochi',
                trustScore: 70,
                totalJobs: 0,
                isVerified: true,
                hourlyRate: 300,
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(appNoReviews);
      await settle(tester);

      expect(find.text('New'), findsOneWidget);
    });

    test(
      '"Nearby first" puts workers from customer district at the top',
      () async {
        final container = ProviderContainer(
          overrides: [
            userLocationProvider.overrideWith(
              () => _FakeUserLocationNotifier(
                const UserLocation(label: 'Kannur, Kerala'),
              ),
            ),
            workerListProvider('test_service').overrideWith(
              (ref) async => [
                Worker(
                  id: 'w_kochi',
                  name: 'Kochi Worker',
                  profileImageUrl: '',
                  rating: 4.8,
                  reviewsCount: 50,
                  skillIds: const ['1'],
                  location: 'Kochi',
                  trustScore: 90,
                  totalJobs: 60,
                  isVerified: true,
                  hourlyRate: 300,
                ),
                Worker(
                  id: 'w_kannur',
                  name: 'Kannur Worker',
                  profileImageUrl: '',
                  rating: 4.5,
                  reviewsCount: 20,
                  skillIds: const ['1'],
                  location: 'Kannur',
                  trustScore: 88,
                  totalJobs: 30,
                  isVerified: true,
                  hourlyRate: 350,
                ),
                Worker(
                  id: 'w_thrissur',
                  name: 'Thrissur Worker',
                  profileImageUrl: '',
                  rating: 4.9,
                  reviewsCount: 80,
                  skillIds: const ['1'],
                  location: 'Thrissur',
                  trustScore: 95,
                  totalJobs: 100,
                  isVerified: true,
                  hourlyRate: 400,
                ),
              ],
            ),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(workerFilterSortProvider.notifier)
            .setSort(WorkerSort.distance);

        final workers = await container.read(
          filteredWorkersProvider('test_service').future,
        );

        expect(workers.first.id, equals('w_kannur'));
        expect(workers.first.location, equals('Kannur'));
      },
    );

    testWidgets(
      'Doctor appointment: Confirm is disabled until slot chosen, patient field starts with signed-in user name',
      (tester) async {
        useTallPhone(tester);
        tester.view.physicalSize = const Size(1080, 8000);
        final widget = await testApp(
          initialLocation: Routes.doctorAppointment,
          routes: [
            GoRoute(
              path: Routes.doctorAppointment,
              builder: (_, _) => const DoctorAppointmentScreen(),
            ),
          ],
        );

        await tester.pumpWidget(widget);
        await settle(tester);

        // Before doctor selection, no confirm button exists
        expect(find.byType(KayloButton), findsNothing);

        // Tap the first doctor card (Dr. Priya Nambiar)
        expect(find.text('Dr. Priya Nambiar'), findsOneWidget);
        await tester.tap(find.text('Dr. Priya Nambiar'));
        await settle(tester);

        // Patient field starts with signed-in user's name ("Nimal User")
        final patientField = tester.widget<TextFormField>(
          find.descendant(
            of: find.byWidgetPredicate(
              (w) => w is KayloTextField && w.label == 'Who is it for?',
            ),
            matching: find.byType(TextFormField),
          ),
        );
        expect(patientField.controller?.text, equals('Nimal User'));

        // Confirm button is disabled because no slot is selected yet
        final buttonBefore = tester.widget<KayloButton>(
          find.byType(KayloButton),
        );
        expect(buttonBefore.onPressed, isNull);

        // Tap a time slot ChoiceChip
        final slotFinder = find.widgetWithText(ChoiceChip, '09:00 AM');
        expect(slotFinder, findsOneWidget);
        await tester.tap(slotFinder);
        await settle(tester);

        // Confirm button is now enabled
        final buttonAfter = tester.widget<KayloButton>(
          find.byType(KayloButton),
        );
        expect(buttonAfter.onPressed, isNotNull);

        // A home visit needs a real destination, never the fallback town.
        await tester.tap(find.byType(KayloButton));
        await tester.pump();
        expect(find.text('Please enter the service address'), findsOneWidget);
        expect(find.text('Choose an address'), findsOneWidget);

        await tester.tap(find.text('Video Teleconsult'));
        await settle(tester);
        expect(find.text('Service address'), findsNothing);
      },
    );
  });
}

class _FakeUserLocationNotifier extends UserLocationNotifier {
  final UserLocation _initial;
  _FakeUserLocationNotifier(this._initial);
  @override
  UserLocation build() => _initial;
}
