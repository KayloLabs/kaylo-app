import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../core/network/supabase_providers.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/application/current_user_provider.dart';
import '../data/local_addresses_repository.dart';
import '../data/supabase_addresses_repository.dart';
import '../domain/addresses_repository.dart';
import '../domain/saved_address.dart';

final addressesRepositoryProvider = Provider<AddressesRepository>((ref) {
  if (useMockData) {
    return LocalAddressesRepository(ref.watch(storageServiceProvider));
  }
  return SupabaseAddressesRepository(ref.watch(supabaseClientProvider));
});

/// Default address first.
final savedAddressesProvider =
    FutureProvider.autoDispose<List<SavedAddress>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final addresses =
      await ref.watch(addressesRepositoryProvider).getAddresses(userId);
  return [...addresses]..sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));
});

final addressesControllerProvider = Provider<AddressesController>((ref) {
  return AddressesController(ref);
});

class AddressesController {
  final Ref _ref;

  AddressesController(this._ref);

  AddressesRepository get _repo => _ref.read(addressesRepositoryProvider);
  String get _userId => _ref.read(currentUserIdProvider) ?? '';

  Future<SavedAddress> add({
    required String label,
    required String line,
    double? latitude,
    double? longitude,
  }) async {
    final address = await _repo.addAddress(
      _userId,
      label: label,
      line: line,
      latitude: latitude,
      longitude: longitude,
    );
    _ref.invalidate(savedAddressesProvider);
    return address;
  }

  Future<void> remove(String addressId) async {
    await _repo.removeAddress(_userId, addressId);
    _ref.invalidate(savedAddressesProvider);
  }

  Future<void> setDefault(String addressId) async {
    await _repo.setDefaultAddress(_userId, addressId);
    _ref.invalidate(savedAddressesProvider);
  }
}
