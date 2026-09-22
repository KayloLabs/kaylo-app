import 'package:kaylo_core/models/worker.dart';
import 'models/worker_review.dart';

abstract class WorkersRepository {
  Future<List<Worker>> getWorkersByServiceId(String serviceId);
  Future<Worker> getWorkerById(String workerId);
  Future<List<WorkerReview>> getReviewsForWorker(String workerId);

  /// Workers whose name or district matches [query]; empty for a blank
  /// query. Backs the workers section of the search screen.
  Future<List<Worker>> searchWorkers(String query);
}
