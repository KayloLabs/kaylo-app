import 'dart:convert';

import '../../../core/services/storage_service.dart';
import '../domain/addresses_repository.dart';
import '../domain/saved_address.dart';

/// Addresses kept on the device, so the demo survives a reload. Seeds one
/// home address the first time so the booking flow has something to pick.
class LocalAddressesRepository implements AddressesRepository {
  final StorageService _storage;

  LocalAddressesRepository(this._storage);

  static const _seed = [
    SavedAddress(
      id: 'addr-home',
      label: 'Home',
      line: 'Thekkedath House, Kaloor, Kannur 670001',
      isDefault: true,
    ),
  ];

  Future<List<SavedAddress>> _load() async {
    final raw = await _storage.getAddresses();
    if (raw == null) return List.of(_seed);
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list)
        SavedAddress.fromJson((item as Map).cast<String, dynamic>()),
    ];
  }

  Future<void> _save(List<SavedAddress> addresses) => _storage.saveAddresses(
        jsonEncode([for (final a in addresses) a.toJson()]),
      );

  @override
  Future<List<SavedAddress>> getAddresses(String userId) => _load();

  @override
  Future<SavedAddress> addAddress(
    String userId, {
    required String label,
    required String line,
    double? latitude,
    double? longitude,
  }) async {
    final addresses = await _load();
    final address = SavedAddress(
      id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      line: line,
      latitude: latitude,
      longitude: longitude,
      isDefault: addresses.isEmpty,
    );
    await _save([...addresses, address]);
    return address;
  }

  @override
  Future<void> removeAddress(String userId, String addressId) async {
    final addresses = await _load()
      ..removeWhere((a) => a.id == addressId);
    if (addresses.isNotEmpty && !addresses.any((a) => a.isDefault)) {
      addresses[0] = addresses[0].copyWith(isDefault: true);
    }
    await _save(addresses);
  }

  @override
  Future<void> setDefaultAddress(String userId, String addressId) async {
    final addresses = await _load();
    await _save([
      for (final a in addresses) a.copyWith(isDefault: a.id == addressId),
    ]);
  }
}
