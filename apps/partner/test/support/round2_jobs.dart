import 'dart:async';
import 'package:kaylo_partner/features/jobs/domain/cash_position.dart';
import 'package:kaylo_partner/features/jobs/domain/job.dart';
import 'package:kaylo_partner/features/jobs/domain/jobs_repository.dart';

Job round2Job(String id, {JobStage stage = JobStage.accepted}) => Job(
  id: id,
  serviceName: 'Plumbing',
  serviceIcon: 'plumbing',
  customerName: 'Anjali Menon',
  customerPhone: '9000000000',
  addressLine: 'Test address',
  distanceKm: 2.4,
  scheduledAt: DateTime(2026, 10, 10, 12),
  payout: 450,
  notes: '',
  stage: stage,
);

class Round2JobsRepository extends JobsRepository {
  @override
  bool get supportsJobActions => true;
  final _changes = StreamController<List<Job>>.broadcast();
  List<Job> jobs;
  Round2JobsRepository(this.jobs);
  void add(Job job) {
    jobs = [...jobs, job];
    _changes.add(jobs);
  }

  void setStage(String id, JobStage stage) {
    jobs = jobs.map((j) => j.id == id ? j.copyWith(stage: stage) : j).toList();
    _changes.add(jobs);
  }

  @override
  Future<List<Job>> getJobs() async => jobs;
  @override
  Future<Job?> getJobById(String id) async {
    for (final job in jobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  @override
  Stream<List<Job>> watchJobs() => Stream.multi((sink) {
    final sub = _changes.stream.listen(
      sink.add,
      onError: sink.addError,
      onDone: sink.close,
    );
    sink.add(jobs);
    sink.onCancel = sub.cancel;
  });
  @override
  Stream<List<Job>> watchIncomingRequests() =>
      watchJobs().map((jobs) => jobs.where((j) => j.isRequested).toList());
  @override
  Stream<Job?> watchActiveJob() => watchJobs().map((jobs) {
    for (final job in jobs) {
      if (job.isActive) return job;
    }
    return null;
  });
  @override
  Stream<List<Job>> watchHistory() => watchJobs().map(
    (jobs) => jobs.where((j) => j.isCompleted || j.isCancelled).toList(),
  );
  @override
  Future<void> acceptJob(String id) async => setStage(id, JobStage.accepted);
  @override
  Future<void> rejectJob(String id) async => setStage(id, JobStage.cancelled);
  @override
  Future<void> markCashCollected(String id, {double? amount}) async {}
  @override
  Future<void> settleCashDue({String? reference}) async {}
  @override
  Future<CashPosition> getCashPosition() async => CashPosition.none;
  @override
  Stream<CashPosition> watchCashPosition() => Stream.value(CashPosition.none);
  @override
  Future<void> advanceJob(String id) async {
    final job = await getJobById(id);
    if (job?.stage.next != null) setStage(id, job!.stage.next!);
  }

  @override
  Future<void> cancelJob(String id) async => setStage(id, JobStage.cancelled);
  @override
  bool get isOnline => true;
  @override
  Stream<bool> watchDutyStatus() => Stream.value(true);
  @override
  Future<void> setDuty(bool online) async {}
  @override
  void dispose() => _changes.close();
}
