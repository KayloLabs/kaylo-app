import '../../../core/models/worker.dart';
import 'models/worker_review.dart';

abstract class WorkersRepository {
  Future<List<Worker>> getWorkersByServiceId(String serviceId);
  Future<Worker> getWorkerById(String workerId);
  Future<List<WorkerReview>> getReviewsForWorker(String workerId);
}
