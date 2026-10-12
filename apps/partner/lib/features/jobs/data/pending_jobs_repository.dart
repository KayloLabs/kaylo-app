import 'dart:async';
import '../domain/cash_position.dart';
import '../domain/job.dart';
import '../domain/jobs_repository.dart';

/// Until the job model PRs land, live builds must not display demo customers,
/// earnings or accept fictitious requests. Mock builds keep their full demo.
class LiveJobsPending implements Exception {
  const LiveJobsPending();
}

class PendingJobsRepository implements JobsRepository {
  @override
  bool get supportsJobActions => false;
  PendingJobsRepository({required bool initiallyOnline})
    : _online = initiallyOnline;
  bool _online;
  final _duty = StreamController<bool>.broadcast();
  @override
  bool get isOnline => _online;
  @override
  Future<List<Job>> getJobs() async => throw const LiveJobsPending();
  @override
  Future<Job?> getJobById(String id) async => throw const LiveJobsPending();
  @override
  Stream<List<Job>> watchJobs() => Stream.error(const LiveJobsPending());
  @override
  Stream<List<Job>> watchIncomingRequests() => watchJobs();
  @override
  Stream<List<Job>> watchHistory() => watchJobs();
  @override
  Stream<Job?> watchActiveJob() => Stream.error(const LiveJobsPending());
  @override
  Future<void> acceptJob(String id) async => throw const LiveJobsPending();
  @override
  Future<void> rejectJob(String id) async => throw const LiveJobsPending();
  @override
  Future<void> advanceJob(String id) async => throw const LiveJobsPending();
  @override
  Future<void> cancelJob(String id) async => throw const LiveJobsPending();
  @override
  Future<void> markCashCollected(String id, {double? amount}) async =>
      throw const LiveJobsPending();
  @override
  Future<void> settleCashDue({String? reference}) async =>
      throw const LiveJobsPending();
  @override
  Future<CashPosition> getCashPosition() async => throw const LiveJobsPending();
  @override
  Stream<CashPosition> watchCashPosition() =>
      Stream.error(const LiveJobsPending());
  @override
  Stream<bool> watchDutyStatus() async* {
    yield _online;
    yield* _duty.stream;
  }

  @override
  Future<void> setDuty(bool online) async {
    // DutySwitch writes the real profile and rolls this state back on failure.
    _online = online;
    if (!_duty.isClosed) _duty.add(online);
  }

  @override
  void dispose() => _duty.close();
}
