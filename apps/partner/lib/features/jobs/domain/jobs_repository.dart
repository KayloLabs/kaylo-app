import 'job.dart';

abstract class JobsRepository {
  Future<List<Job>> getJobs();
  Stream<List<Job>> watchJobs();
  Stream<List<Job>> watchIncomingRequests();
  Stream<Job?> watchActiveJob();
  Stream<List<Job>> watchHistory();
  Future<Job?> getJobById(String id);

  Future<void> acceptJob(String id);
  Future<void> rejectJob(String id);
  Future<void> advanceJob(String id);
  Future<void> cancelJob(String id);

  bool get isOnline;
  Stream<bool> watchDutyStatus();
  Future<void> setDuty(bool online);
  void dispose();
}
