import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kaylo_core/network/supabase_providers.dart';
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
      // The person filter stays: workers' locations are readable too.
      // `*` keeps this working before migration 0009 adds is_default and
      // created_at; without them the first address counts as default.
      final rows = await _client
          .from('locations')
          .select()
          .eq('person_id', userId)
          .order('location_id');
      rows.sort((a, b) {
        final byDefault = (b['is_default'] == true ? 1 : 0) -
            (a['is_default'] == true ? 1 : 0);
        if (byDefault != 0) return byDefault;
        final at = a['created_at'] as String?, bt = b['created_at'] as String?;
        return at == null || bt == null ? 0 : at.compareTo(bt);
      });
      final anyDefault = rows.any((r) => r['is_default'] == true);
      return [
        for (final (index, row) in rows.indexed)
          SavedAddress(
            id: row['location_id'] as String,
            label: (row['nickname'] as String?) ?? 'Address',
            line: [
              row['street'],
              row['district'],
              row['pincode'],
            ].whereType<String>().where((s) => s.isNotEmpty).join(', '),
            latitude: (row['latitude'] as num?)?.toDouble(),
            longitude: (row['longitude'] as num?)?.toDouble(),
            isDefault: anyDefault ? row['is_default'] == true : index == 0,
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

  /// Uses locations.is_default (migration 0009): clears the flag on the
  /// customer's other addresses, then sets it on this one.
  @override
  Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      await _client
          .from('locations')
          .update({'is_default': false})
          .eq('person_id', userId)
          .neq('location_id', addressId);
      await _client
          .from('locations')
          .update({'is_default': true})
          .eq('location_id', addressId);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
