import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaylo/features/home/data/mock_home_repository.dart';
import 'package:kaylo/features/home/domain/home_repository.dart';
import 'package:kaylo/features/workers/data/mock_workers_repository.dart';
import 'package:kaylo/features/workers/application/workers_providers.dart';
import 'package:kaylo/features/care/data/mock_care_repository.dart';
import 'package:kaylo/features/care/domain/models/appointment.dart';
import 'package:kaylo/features/care/domain/models/caregiver.dart';

void main() {
  group('M3 - Home Services & Catalog Tests', () {
    late HomeRepository homeRepo;

    setUp(() {
      homeRepo = MockHomeRepository();
    });

    test('getServicesByCategory("home") returns all 7 core home services', () async {
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
    });

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

    test('searchWorkers matches worker name and service', () async {
      final results = await homeRepo.searchWorkers('Suresh');
      expect(results, isNotEmpty);
      expect(results.any((w) => w.name.contains('Suresh')), isTrue);
    });
  });

  group('M3 - Workers, Reviews, Filter & Sort Tests', () {
    late MockWorkersRepository workersRepo;

    setUp(() {
      workersRepo = MockWorkersRepository();
    });

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

    test('getReviewsForWorker returns review list with ratings and comments', () async {
      final reviews = await workersRepo.getReviewsForWorker('w1');
      expect(reviews, isNotEmpty);
      expect(reviews.first.customerName, isNotEmpty);
      expect(reviews.first.comment, isNotEmpty);
      expect(reviews.first.rating, inInclusiveRange(1.0, 5.0));
    });

    test('filteredWorkersProvider correctly applies filter and sort', () async {
      final container = ProviderContainer(
        overrides: [
          workersRepositoryProvider.overrideWithValue(workersRepo),
        ],
      );
      addTearDown(container.dispose);

      // 1. Initial list for plumbing
      final initialWorkers = await container.read(filteredWorkersProvider('1').future);
      expect(initialWorkers, isNotEmpty);

      // 2. Filter by minRating 4.8
      container.read(workerFilterSortProvider.notifier).updateFilter(
            const WorkerFilter(minRating: 4.8),
          );
      final ratingFiltered = await container.read(filteredWorkersProvider('1').future);
      for (final w in ratingFiltered) {
        expect(w.rating, greaterThanOrEqualTo(4.8));
      }

      // 3. Filter by maxPrice 350
      container.read(workerFilterSortProvider.notifier).updateFilter(
            const WorkerFilter(maxPrice: 350),
          );
      final priceFiltered = await container.read(filteredWorkersProvider('1').future);
      for (final w in priceFiltered) {
        expect(w.hourlyRate, lessThanOrEqualTo(350));
      }

      // 4. Sort by priceLowToHigh
      container.read(workerFilterSortProvider.notifier).setSort(WorkerSort.priceLowToHigh);
      final sortedLowToHigh = await container.read(filteredWorkersProvider('1').future);
      for (int i = 0; i < sortedLowToHigh.length - 1; i++) {
        expect(sortedLowToHigh[i].hourlyRate!, lessThanOrEqualTo(sortedLowToHigh[i + 1].hourlyRate!));
      }

      // 5. Sort by rating
      container.read(workerFilterSortProvider.notifier).setSort(WorkerSort.rating);
      final sortedByRating = await container.read(filteredWorkersProvider('1').future);
      for (int i = 0; i < sortedByRating.length - 1; i++) {
        expect(sortedByRating[i].rating, greaterThanOrEqualTo(sortedByRating[i + 1].rating));
      }
    });
  });

  group('M3 - Care Features (Doctor Appointment & Caregiver Booking) Tests', () {
    late MockCareRepository careRepo;

    setUp(() {
      careRepo = MockCareRepository();
    });

    test('getDoctors returns doctor list and filters by specialty', () async {
      final allDoctors = await careRepo.getDoctors();
      expect(allDoctors.length, greaterThanOrEqualTo(4));

      final cardiologists = await careRepo.getDoctors(specialty: 'Cardiologist');
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

    test('getCaregivers returns verified caregivers with hourly rates', () async {
      final caregivers = await careRepo.getCaregivers();
      expect(caregivers, isNotEmpty);
      for (final cg in caregivers) {
        expect(cg.hourlyRate, greaterThan(0));
        expect(cg.specialties, isNotEmpty);
      }
    });

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
  });
}
