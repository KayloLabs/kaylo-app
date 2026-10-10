import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/mock/partner_seed.dart';
import '../domain/worker_profile.dart';

/// The sample worker, kept in shared preferences so edits survive a
/// restart. The on-duty flag shares its key with the mock jobs feed, so
/// the switch and the profile always agree.
class MockWorkerProfileRepository implements WorkerProfileRepository {
  static const profileKey = 'kaylo_partner_profile_v1';
  static const dutyKey = 'kaylo_partner_duty_status';

  final SharedPreferences? _prefs;
  final _controller = StreamController<WorkerProfile?>.broadcast();
  WorkerProfile? _profile;

  MockWorkerProfileRepository([this._prefs]);

  WorkerProfile _load() {
    if (_profile != null) return _profile!;
    final raw = _prefs?.getString(profileKey);
    var profile = PartnerSeed.worker;
    if (raw != null && raw.isNotEmpty) {
      try {
        profile = WorkerProfile.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        profile = PartnerSeed.worker;
      }
    }
    _profile = profile.copyWith(
      isAvailable: _prefs?.getBool(dutyKey) ?? profile.isAvailable,
    );
    return _profile!;
  }

  Future<void> _persist() async {
    await _prefs?.setString(profileKey, jsonEncode(_profile!.toJson()));
    if (!_controller.isClosed) _controller.add(_profile);
  }

  @override
  Stream<WorkerProfile?> watchProfile() async* {
    yield _load();
    yield* _controller.stream;
  }

  @override
  Future<WorkerProfile?> getProfile() async => _load();

  @override
  Future<WorkerProfile> updateProfile(WorkerProfileEdit edit) async {
    final current = _load();
    final name = edit.name?.trim();
    if (name != null && name.isEmpty) {
      throw ArgumentError('Name is required');
    }
    if (edit.serviceIds != null && edit.serviceIds!.isEmpty) {
      throw ArgumentError('Choose at least one service');
    }
    final radius = edit.travelRadiusKm;
    if (radius != null && (radius < 1 || radius > 100)) {
      throw ArgumentError('Travel radius must be between 1 and 100 km');
    }
    final options = PartnerSeed.serviceOptions;
    _profile = current.copyWith(
      name: name,
      district: edit.district,
      travelRadiusKm: radius,
      bio: edit.bio == null ? null : (edit.bio!.trim().isEmpty ? '' : edit.bio),
      services: edit.serviceIds == null
          ? null
          : [
              for (final id in edit.serviceIds!)
                options.firstWhere(
                  (o) => o.id == id,
                  orElse: () => ServiceOption(id: id, name: id),
                ),
            ],
      upiId: edit.upiId?.trim(),
    );
    await _persist();
    return _profile!;
  }

  @override
  Future<void> setAvailable(bool available) async {
    _profile = _load().copyWith(isAvailable: available);
    await _prefs?.setBool(dutyKey, available);
    if (!_controller.isClosed) _controller.add(_profile);
  }

  @override
  Future<List<ServiceOption>> listServices() async =>
      PartnerSeed.serviceOptions;

  @override
  void dispose() {
    _controller.close();
  }
}
