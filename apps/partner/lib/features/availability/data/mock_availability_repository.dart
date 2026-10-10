import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/availability.dart';

/// Hours and days off in shared preferences for the sample build.
class MockAvailabilityRepository implements AvailabilityRepository {
  static const hoursKey = 'kaylo_partner_weekly_hours_v1';
  static const timeOffKey = 'kaylo_partner_time_off_v1';

  final SharedPreferences? _prefs;
  final _hoursController = StreamController<WeeklyHours?>.broadcast();
  final _timeOffController = StreamController<List<TimeOff>>.broadcast();
  WeeklyHours? _hours;
  List<TimeOff>? _timeOff;

  MockAvailabilityRepository([this._prefs]);

  WeeklyHours _loadHours() {
    if (_hours != null) return _hours!;
    final raw = _prefs?.getString(hoursKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _hours = WeeklyHours.fromJson(jsonDecode(raw) as List<dynamic>);
      } catch (_) {
        _hours = WeeklyHours.defaults();
      }
    } else {
      _hours = WeeklyHours.defaults();
    }
    return _hours!;
  }

  List<TimeOff> _loadTimeOff() {
    if (_timeOff != null) return _timeOff!;
    final raw = _prefs?.getString(timeOffKey);
    _timeOff = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        _timeOff = [
          for (final t in jsonDecode(raw) as List<dynamic>)
            TimeOff.fromJson(Map<String, dynamic>.from(t as Map)),
        ];
      } catch (_) {
        _timeOff = [];
      }
    }
    return _timeOff!;
  }

  List<TimeOff> _upcoming() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final list = [
      for (final t in _loadTimeOff())
        if (!t.endsOn.isBefore(today)) t,
    ]..sort((a, b) => a.startsOn.compareTo(b.startsOn));
    return List.unmodifiable(list);
  }

  @override
  Stream<WeeklyHours?> watchWeeklyHours() async* {
    yield _loadHours();
    yield* _hoursController.stream;
  }

  @override
  Future<void> saveWeeklyHours(WeeklyHours hours) async {
    if (!hours.isValid) {
      throw ArgumentError('End time must be after the start');
    }
    _hours = hours;
    await _prefs?.setString(hoursKey, jsonEncode(hours.toJson()));
    if (!_hoursController.isClosed) _hoursController.add(_hours);
  }

  @override
  Stream<List<TimeOff>> watchTimeOff() async* {
    yield _upcoming();
    yield* _timeOffController.stream;
  }

  Future<void> _persistTimeOff() async {
    await _prefs?.setString(
      timeOffKey,
      jsonEncode([for (final t in _timeOff!) t.toJson()]),
    );
    if (!_timeOffController.isClosed) _timeOffController.add(_upcoming());
  }

  @override
  Future<TimeOff> addTimeOff({
    required DateTime startsOn,
    required DateTime endsOn,
    String? reason,
  }) async {
    final start = DateTime(startsOn.year, startsOn.month, startsOn.day);
    final end = DateTime(endsOn.year, endsOn.month, endsOn.day);
    if (end.isBefore(start)) {
      throw ArgumentError('The last day cannot be before the first');
    }
    final entry = TimeOff(
      id: 'off-${DateTime.now().microsecondsSinceEpoch}',
      startsOn: start,
      endsOn: end,
      reason: (reason ?? '').trim().isEmpty ? null : reason!.trim(),
    );
    _loadTimeOff().add(entry);
    await _persistTimeOff();
    return entry;
  }

  @override
  Future<void> removeTimeOff(String id) async {
    _loadTimeOff().removeWhere((t) => t.id == id);
    await _persistTimeOff();
  }

  @override
  void dispose() {
    _hoursController.close();
    _timeOffController.close();
  }
}
