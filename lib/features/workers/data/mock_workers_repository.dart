import '../../../core/models/worker.dart';
import '../domain/workers_repository.dart';
import '../../../core/network/app_failure.dart';

class MockWorkersRepository implements WorkersRepository {
  final List<Worker> _mockWorkers = [
    Worker(id: 'w1', name: 'Raju K.', profileImageUrl: '', rating: 4.8, reviewsCount: 120, skillIds: ['1'], location: 'Kochi', trustScore: 95, isVerified: true, hourlyRate: 350, totalJobs: 132),
    Worker(id: 'w2', name: 'Manoj P.', profileImageUrl: '', rating: 4.5, reviewsCount: 85, skillIds: ['1', '4'], location: 'Ernakulam', trustScore: 88, isVerified: true, hourlyRate: 300, totalJobs: 96),
    Worker(id: 'w3', name: 'Suresh B.', profileImageUrl: '', rating: 4.9, reviewsCount: 200, skillIds: ['5'], location: 'Thrissur', trustScore: 98, isVerified: true, hourlyRate: 400, totalJobs: 214),
  ];

  @override
  Future<List<Worker>> getWorkersByServiceId(String serviceId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockWorkers.where((w) => w.skillIds.contains(serviceId)).toList();
  }

  @override
  Future<Worker> getWorkerById(String workerId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final worker = _mockWorkers.where((w) => w.id == workerId).firstOrNull;
    if (worker == null) {
      throw ServerFailure('Worker not found', code: 'not-found');
    }
    return worker;
  }
}
