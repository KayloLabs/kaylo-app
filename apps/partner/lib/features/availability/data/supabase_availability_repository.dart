import 'dart:async';

import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/availability.dart';

/// `worker_weekly_hours` and `worker_time_off` (migration 0023). Both
/// tables fill in the worker's id themselves and row-level security
/// limits every read to the caller, so no id is sent from here.
class SupabaseAvailabilityRepository implements AvailabilityRepository {
  final SupabaseClient _client;
  final _hoursRefresh = StreamController<void>.broadcast();
  final _timeOffRefresh = StreamController<void>.broadcast();

  SupabaseAvailabilityRepository(this._client);

  Future<WeeklyHours?> _fetchHours() async {
    try {
      final rows = await _client
          .from('worker_weekly_hours')
          .select('weekday, works, start_time, end_time')
          .order('weekday', ascending: true);
      if (rows.isEmpty) return null;
      return WeeklyHours.fromJson(rows);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Stream<WeeklyHours?> watchWeeklyHours() async* {
    yield await _fetchHours();
    await for (final _ in _hoursRefresh.stream) {
      yield await _fetchHours();
    }
  }

  @override
  Future<void> saveWeeklyHours(WeeklyHours hours) async {
    if (!hours.isValid) {
      throw ArgumentError('End time must be after the start');
    }
    try {
      // Replace the week in two plain statements rather than an upsert:
      // the conflict target would need the worker id the table fills in.
      await _client.from('worker_weekly_hours').delete().gte('weekday', 1);
      await _client.from('worker_weekly_hours').insert(hours.toJson());
      if (!_hoursRefresh.isClosed) _hoursRefresh.add(null);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<TimeOff>> _fetchTimeOff() async {
    try {
      final rows = await _client
          .from('worker_time_off')
          .select('time_off_id, starts_on, ends_on, reason')
          .gte('ends_on', TimeOff.dateString(DateTime.now()))
          .order('starts_on', ascending: true);
      return rows.map(TimeOff.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Stream<List<TimeOff>> watchTimeOff() async* {
    yield await _fetchTimeOff();
    await for (final _ in _timeOffRefresh.stream) {
      yield await _fetchTimeOff();
    }
  }

  @override
  Future<TimeOff> addTimeOff({
    required DateTime startsOn,
    required DateTime endsOn,
    String? reason,
  }) async {
    try {
      final row = await _client
          .from('worker_time_off')
          .insert({
            'starts_on': TimeOff.dateString(startsOn),
            'ends_on': TimeOff.dateString(endsOn),
            'reason': (reason ?? '').trim().isEmpty ? null : reason!.trim(),
          })
          .select('time_off_id, starts_on, ends_on, reason')
          .single();
      if (!_timeOffRefresh.isClosed) _timeOffRefresh.add(null);
      return TimeOff.fromJson(row);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> removeTimeOff(String id) async {
    try {
      await _client.from('worker_time_off').delete().eq('time_off_id', id);
      if (!_timeOffRefresh.isClosed) _timeOffRefresh.add(null);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  void dispose() {
    _hoursRefresh.close();
    _timeOffRefresh.close();
  }
}
