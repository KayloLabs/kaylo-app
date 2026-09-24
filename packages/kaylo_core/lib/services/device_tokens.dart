import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the signed-in person's push token in `device_tokens` so the
/// backend can reach this device. Upserts on the token, so a reinstall
/// or a token rotation replaces the old row instead of piling up.
class DeviceTokenRegistrar {
  final SupabaseClient _client;

  const DeviceTokenRegistrar(this._client);

  Future<void> register({
    required String personId,
    required String token,
    required String platform,
    required String app,
  }) async {
    await _client.from('device_tokens').upsert(
      {
        'person_id': personId,
        'token': token,
        'platform': platform,
        'app': app,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'token',
    );
  }

  Future<void> unregister(String token) async {
    await _client.from('device_tokens').delete().eq('token', token);
  }
}
