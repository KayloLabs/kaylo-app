import '../../../core/models/worker.dart';
import '../domain/models/worker_review.dart';
import '../domain/workers_repository.dart';
import '../../../core/network/app_failure.dart';

class MockWorkersRepository implements WorkersRepository {
  final List<Worker> _mockWorkers = [
    Worker(id: 'w1', name: 'Raju K.', profileImageUrl: '', rating: 4.8, reviewsCount: 120, skillIds: ['1', '4'], location: 'Kochi', trustScore: 95, isVerified: true, hourlyRate: 350, totalJobs: 132),
    Worker(id: 'w2', name: 'Manoj P.', profileImageUrl: '', rating: 4.5, reviewsCount: 85, skillIds: ['1', '4', '10'], location: 'Ernakulam', trustScore: 88, isVerified: true, hourlyRate: 300, totalJobs: 96),
    Worker(id: 'w3', name: 'Suresh B.', profileImageUrl: '', rating: 4.9, reviewsCount: 200, skillIds: ['5', '12'], location: 'Thrissur', trustScore: 98, isVerified: true, hourlyRate: 400, totalJobs: 214),
    Worker(id: 'w4', name: 'Anil Kumar', profileImageUrl: '', rating: 4.7, reviewsCount: 75, skillIds: ['7', '11'], location: 'Kochi', trustScore: 92, isVerified: true, hourlyRate: 280, totalJobs: 82),
    Worker(id: 'w5', name: 'Prasad V.', profileImageUrl: '', rating: 4.6, reviewsCount: 110, skillIds: ['4', '13'], location: 'Kochi', trustScore: 90, isVerified: false, hourlyRate: 320, totalJobs: 105),
    Worker(id: 'w6', name: 'Haridas M.', profileImageUrl: '', rating: 4.4, reviewsCount: 42, skillIds: ['4', '5'], location: 'Kochi', trustScore: 85, isVerified: true, hourlyRate: 250, totalJobs: 54),
    Worker(id: 'w7', name: 'Vijayan C.', profileImageUrl: '', rating: 4.9, reviewsCount: 180, skillIds: ['10', '11'], location: 'Aluva', trustScore: 96, isVerified: true, hourlyRate: 450, totalJobs: 190),
    Worker(id: 'w8', name: 'Santhosh N.', profileImageUrl: '', rating: 4.3, reviewsCount: 30, skillIds: ['7', '12'], location: 'Kochi', trustScore: 82, isVerified: false, hourlyRate: 220, totalJobs: 38),
    Worker(id: 'w9', name: 'Deepak S.', profileImageUrl: '', rating: 4.8, reviewsCount: 95, skillIds: ['13', '5'], location: 'Kochi', trustScore: 94, isVerified: true, hourlyRate: 380, totalJobs: 112),
  ];

  final Map<String, List<WorkerReview>> _mockReviews = {
    'w1': [
      WorkerReview(id: 'r1', workerId: 'w1', customerName: 'Lakshmi N.', rating: 5.0, comment: 'Punctual, polite and very skilled. Fixed our bathroom leakage in 30 mins.', createdAt: DateTime(2026, 8, 12)),
      WorkerReview(id: 'r2', workerId: 'w1', customerName: 'George Thomas', rating: 4.5, comment: 'Great service. Arrived on time with all required tools.', createdAt: DateTime(2026, 7, 24)),
      WorkerReview(id: 'r3', workerId: 'w1', customerName: 'Sunil Menon', rating: 5.0, comment: 'Highly recommended for any plumbing or coconut tree climbing work!', createdAt: DateTime(2026, 6, 18)),
    ],
    'w2': [
      WorkerReview(id: 'r4', workerId: 'w2', customerName: 'Anitha R.', rating: 4.5, comment: 'Good work, fair pricing.', createdAt: DateTime(2026, 8, 5)),
      WorkerReview(id: 'r5', workerId: 'w2', customerName: 'Mohanan K.', rating: 4.0, comment: 'Job done properly, very polite person.', createdAt: DateTime(2026, 7, 10)),
    ],
    'w3': [
      WorkerReview(id: 'r6', workerId: 'w3', customerName: 'Dr. Radhakrishnan', rating: 5.0, comment: 'Outstanding electrician. Solved a complex short circuit issue promptly.', createdAt: DateTime(2026, 8, 28)),
      WorkerReview(id: 'r7', workerId: 'w3', customerName: 'Fatima Z.', rating: 5.0, comment: 'Very professional and clean work.', createdAt: DateTime(2026, 8, 14)),
    ],
  };

  @override
  Future<List<Worker>> getWorkersByServiceId(String serviceId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockWorkers.where((w) => w.skillIds.contains(serviceId)).toList();
  }

  @override
  Future<Worker> getWorkerById(String workerId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final worker = _mockWorkers.where((w) => w.id == workerId).firstOrNull;
    if (worker == null) {
      throw ServerFailure('Worker not found', code: 'not-found');
    }
    return worker;
  }

  @override
  Future<List<WorkerReview>> getReviewsForWorker(String workerId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockReviews[workerId] ?? [
      WorkerReview(id: 'def1', workerId: workerId, customerName: 'Satisfied Customer', rating: 5.0, comment: 'Very professional and reliable service. Highly recommended!', createdAt: DateTime(2026, 8, 1)),
      WorkerReview(id: 'def2', workerId: workerId, customerName: 'Verified User', rating: 4.5, comment: 'Good quality work done on time.', createdAt: DateTime(2026, 7, 15)),
    ];
  }
}
