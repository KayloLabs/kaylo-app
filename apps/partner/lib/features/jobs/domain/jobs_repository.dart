import 'cash_position.dart';
import 'job.dart';

abstract class JobsRepository {
  bool get supportsJobActions;
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

  /// Confirms the cash collected for [id]. The backend marks the payment,
  /// completes the job and books Kaylo's commission against the worker.
  Future<void> markCashCollected(String id, {double? amount});

  /// Records that the commission due has been paid to Kaylo.
  Future<void> settleCashDue({String? reference});
  Future<CashPosition> getCashPosition();
  Stream<CashPosition> watchCashPosition();

  bool get isOnline;
  Stream<bool> watchDutyStatus();
  Future<void> setDuty(bool online);
  void dispose();
}
