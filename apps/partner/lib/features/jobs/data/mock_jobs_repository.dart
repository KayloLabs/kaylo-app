import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/mock/partner_seed.dart';
import '../domain/cash_position.dart';
import '../domain/geo.dart';
import '../domain/job.dart';
import '../domain/jobs_repository.dart';

class MockJobsRepository implements JobsRepository {
  @override
  bool get supportsJobActions => true;
  final SharedPreferences? _prefs;

  static const _jobsKey = 'kaylo_partner_jobs_v1';
  static const _dutyKey = 'kaylo_partner_duty_status';
  static const _cashKey = 'kaylo_partner_cash_v1';

  final _jobsController = StreamController<List<Job>>.broadcast();
  final _dutyController = StreamController<bool>.broadcast();
  final _cashController = StreamController<CashPosition>.broadcast();
  CashPosition _cash = CashPosition.none;

  List<Job>? _jobs;
  bool _isOnline = true;
  Timer? _liveSimulationTimer;
  int _poolIndex = 0;

  MockJobsRepository([this._prefs]) {
    _init();
  }

  void _init() {
    _isOnline = _prefs?.getBool(_dutyKey) ?? true;
    final storedCash = _prefs?.getString(_cashKey);
    if (storedCash != null && storedCash.isNotEmpty) {
      try {
        _cash = CashPosition.fromJson(
          jsonDecode(storedCash) as Map<String, dynamic>,
        );
      } catch (_) {
        _cash = CashPosition.none;
      }
    }
    _ensureLoaded().then((_) {
      if (_isOnline) {
        _startLiveSimulation();
      }
    });
  }

  Future<List<Job>> _ensureLoaded() async {
    if (_jobs != null) return _jobs!;
    final raw = _prefs?.getString(_jobsKey);
    if (raw == null || raw.isEmpty) {
      _jobs = PartnerSeed.initialJobs();
      await _persist();
    } else {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _jobs = decoded
            .map((e) => Job.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _jobs = PartnerSeed.initialJobs();
      }
    }
    _broadcast();
    return _jobs!;
  }

  Future<void> _persist() async {
    if (_jobs == null) return;
    final encoded = jsonEncode(_jobs!.map((j) => j.toJson()).toList());
    await _prefs?.setString(_jobsKey, encoded);
    _broadcast();
  }

  void _broadcast() {
    if (_jobs != null && !_jobsController.isClosed) {
      _jobsController.add(List.unmodifiable(_jobs!));
    }
  }

  void _startLiveSimulation() {
    _liveSimulationTimer?.cancel();
    // Simulate incoming job request every 25 seconds when online
    _liveSimulationTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!_isOnline || _jobs == null) return;

      // Only generate if less than 4 pending requests
      final pendingCount = _jobs!.where((j) => j.isRequested).length;
      if (pendingCount >= 4) return;

      final pool = PartnerSeed.liveQueuePool;
      final template = pool[_poolIndex % pool.length];
      _poolIndex++;

      final lat = (template['latitude'] as num?)?.toDouble() ?? 11.8745;
      final lng = (template['longitude'] as num?)?.toDouble() ?? 75.3704;
      final dist =
          (distanceKm(
                    PartnerSeed.workerLatitude,
                    PartnerSeed.workerLongitude,
                    lat,
                    lng,
                  ) *
                  10)
              .roundToDouble() /
          10.0;

      final newJob = Job(
        id: 'job-live-${DateTime.now().millisecondsSinceEpoch}',
        serviceName: template['serviceName'] as String,
        serviceIcon: template['serviceIcon'] as String,
        customerName: template['customerName'] as String,
        customerPhone: template['customerPhone'] as String,
        addressLine: template['addressLine'] as String,
        latitude: lat,
        longitude: lng,
        distanceKm: dist,
        scheduledAt: DateTime.now().add(const Duration(minutes: 45)),
        payout: (template['payout'] as num).toDouble(),
        notes: template['notes'] as String,
        stage: JobStage.requested,
      );

      _jobs!.insert(0, newJob);
      _persist();
    });
  }

  void _stopLiveSimulation() {
    _liveSimulationTimer?.cancel();
    _liveSimulationTimer = null;
  }

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> watchDutyStatus() async* {
    yield _isOnline;
    yield* _dutyController.stream;
  }

  @override
  Future<void> setDuty(bool online) async {
    _isOnline = online;
    await _prefs?.setBool(_dutyKey, online);
    if (!_dutyController.isClosed) {
      _dutyController.add(_isOnline);
    }
    if (_isOnline) {
      _startLiveSimulation();
    } else {
      _stopLiveSimulation();
    }
  }

  @override
  Future<List<Job>> getJobs() async {
    final list = await _ensureLoaded();
    return List.unmodifiable(list);
  }

  @override
  Stream<List<Job>> watchJobs() async* {
    final initial = await _ensureLoaded();
    yield List.unmodifiable(initial);
    yield* _jobsController.stream;
  }

  @override
  Stream<List<Job>> watchIncomingRequests() async* {
    await for (final list in watchJobs()) {
      yield list.where((j) => j.isRequested).toList();
    }
  }

  @override
  Stream<Job?> watchActiveJob() async* {
    await for (final list in watchJobs()) {
      try {
        yield list.firstWhere((j) => j.isActive);
      } catch (_) {
        yield null;
      }
    }
  }

  @override
  Stream<List<Job>> watchHistory() async* {
    await for (final list in watchJobs()) {
      final history = list.where((j) => j.isCompleted || j.isCancelled).toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      yield history;
    }
  }

  @override
  Future<Job?> getJobById(String id) async {
    final list = await _ensureLoaded();
    try {
      return list.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> acceptJob(String id) async {
    final list = await _ensureLoaded();
    final index = list.indexWhere((j) => j.id == id);
    if (index != -1) {
      final accepted = list.removeAt(index).copyWith(stage: JobStage.accepted);
      // Surface the job just accepted as the current active job.
      list.insert(0, accepted);
      await _persist();
    }
  }

  @override
  Future<void> advanceJob(String id) async {
    final list = await _ensureLoaded();
    final index = list.indexWhere((j) => j.id == id);
    if (index != -1) {
      final next = list[index].stage.next;
      if (next != null) {
        list[index] = list[index].copyWith(stage: next);
        await _persist();
      }
    }
  }

  @override
  Future<void> rejectJob(String id) async {
    final list = await _ensureLoaded();
    final index = list.indexWhere((j) => j.id == id);
    if (index != -1) {
      list.removeAt(index);
      await _persist();
    }
  }

  @override
  Future<void> cancelJob(String id) async {
    final list = await _ensureLoaded();
    final index = list.indexWhere((j) => j.id == id);
    if (index != -1) {
      list[index] = list[index].copyWith(stage: JobStage.cancelled);
      await _persist();
    }
  }

  /// The customer's price for a mock job: the payout grossed up by Kaylo's
  /// commission and rounded to ten rupees, as the seed prices are.
  double _customerPrice(Job job) {
    final gross = job.payout / (1 - _cash.commissionRate);
    return (gross / 10).round() * 10.0;
  }

  Future<void> _saveCash(CashPosition next) async {
    _cash = next;
    await _prefs?.setString(_cashKey, jsonEncode(next.toJson()));
    if (!_cashController.isClosed) _cashController.add(next);
  }

  @override
  Future<void> markCashCollected(String id, {double? amount}) async {
    final list = await _ensureLoaded();
    final index = list.indexWhere((j) => j.id == id);
    if (index == -1) throw StateError('This job is not yours');
    final collected = amount ?? _customerPrice(list[index]);
    if (collected <= 0) throw StateError('Amount must be positive');
    final fee = double.parse(
      (collected * _cash.commissionRate).toStringAsFixed(2),
    );
    await _saveCash(
      _cash.copyWith(
        cashInHand: _cash.cashInHand + collected,
        dueToKaylo: _cash.dueToKaylo + fee,
      ),
    );
  }

  @override
  Future<void> settleCashDue({String? reference}) async {
    if (_cash.dueToKaylo <= 0) throw StateError('Nothing to settle');
    await _saveCash(_cash.copyWith(cashInHand: 0, dueToKaylo: 0));
  }

  @override
  Future<CashPosition> getCashPosition() async => _cash;

  @override
  Stream<CashPosition> watchCashPosition() async* {
    yield _cash;
    yield* _cashController.stream;
  }

  @override
  void dispose() {
    _stopLiveSimulation();
    _jobsController.close();
    _dutyController.close();
    _cashController.close();
  }
}
