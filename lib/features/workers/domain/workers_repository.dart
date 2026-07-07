import '../../../core/models/worker.dart';

abstract class WorkersRepository {
  Future<List<Worker>> getWorkersByServiceId(String serviceId);
  Future<Worker> getWorkerById(String workerId);
}
