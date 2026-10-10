import 'dart:async';

import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/worker_profile.dart';

/// The worker's own row through the three RPCs of migration 0022. Every
/// write re-reads the profile, so one stream serves every screen.
class SupabaseWorkerProfileRepository implements WorkerProfileRepository {
  final SupabaseClient _client;
  final _refresh = StreamController<void>.broadcast();

  SupabaseWorkerProfileRepository(this._client);

  @override
  Stream<WorkerProfile?> watchProfile() async* {
    yield await getProfile();
    await for (final _ in _refresh.stream) {
      yield await getProfile();
    }
  }

  @override
  Future<WorkerProfile?> getProfile() async {
    try {
      final row = await _client.rpc('my_worker_profile');
      if (row == null) return null;
      return _withPhoto(
        WorkerProfile.fromJson(Map<String, dynamic>.from(row as Map)),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<WorkerProfile> updateProfile(WorkerProfileEdit edit) async {
    try {
      final row = await _client.rpc(
        'update_worker_profile',
        params: {'p_details': edit.toJson()},
      );
      final profile = WorkerProfile.fromJson(
        Map<String, dynamic>.from(row as Map),
      );
      if (!_refresh.isClosed) _refresh.add(null);
      return _withPhoto(profile);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<WorkerProfile> _withPhoto(WorkerProfile profile) async {
    final path = profile.photoUrl;
    if (path == null || !path.startsWith('applications/')) return profile;
    // Application photos remain private. Only this issued worker's RLS session
    // may obtain the short-lived URL used by their profile screen.
    try {
      final url = await _client.storage
          .from('worker-documents')
          .createSignedUrl(path, 3600);
      return profile.copyWith(photoUrl: url);
    } catch (_) {
      return profile.copyWith(photoUrl: '');
    }
  }

  @override
  Future<void> setAvailable(bool available) async {
    try {
      await _client.rpc(
        'set_worker_available',
        params: {'p_available': available},
      );
      if (!_refresh.isClosed) _refresh.add(null);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<ServiceOption>> listServices() async {
    try {
      final rows = await _client
          .from('services')
          .select('service_id, service_name')
          .eq('is_active', true)
          .order('service_name', ascending: true);
      return rows.map(ServiceOption.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  void dispose() {
    _refresh.close();
  }
}
