import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../domain/addresses_repository.dart';
import '../domain/saved_address.dart';

/// Addresses against the `locations` table. The app keeps a single
/// address line, stored in `street`; `nickname` carries the label. The
/// default is the first row by insertion until the schema gains a flag.
class SupabaseAddressesRepository implements AddressesRepository {
  final SupabaseClient _client;

  SupabaseAddressesRepository(this._client);

  @override
  Future<List<SavedAddress>> getAddresses(String userId) async {
    try {
      final rows = await _client
          .from('locations')
          .select('location_id, nickname, street, district, pincode, latitude, longitude')
          .eq('person_id', userId)
          .order('location_id');
      return [
        for (final (index, row) in rows.indexed)
          SavedAddress(
            id: row['location_id'] as String,
            label: (row['nickname'] as String?) ?? 'Address',
            line: [row['street'], row['district'], row['pincode']]
                .whereType<String>()
                .where((s) => s.isNotEmpty)
                .join(', '),
            latitude: (row['latitude'] as num?)?.toDouble(),
            longitude: (row['longitude'] as num?)?.toDouble(),
            isDefault: index == 0,
          ),
      ];
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<SavedAddress> addAddress(
    String userId, {
    required String label,
    required String line,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final row = await _client
          .from('locations')
          .insert({
            'person_id': userId,
            'nickname': label,
            'street': line,
            'latitude': latitude,
            'longitude': longitude,
          })
          .select('location_id')
          .single();
      return SavedAddress(
        id: row['location_id'] as String,
        label: label,
        line: line,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> removeAddress(String userId, String addressId) async {
    try {
      await _client.from('locations').delete().eq('location_id', addressId);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  /// The schema has no default flag yet, so this is a no-op live.
  @override
  Future<void> setDefaultAddress(String userId, String addressId) async {}
}
