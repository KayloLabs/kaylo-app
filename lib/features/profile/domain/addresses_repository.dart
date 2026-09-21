import 'saved_address.dart';

abstract class AddressesRepository {
  Future<List<SavedAddress>> getAddresses(String userId);
  Future<SavedAddress> addAddress(
    String userId, {
    required String label,
    required String line,
    double? latitude,
    double? longitude,
  });
  Future<void> removeAddress(String userId, String addressId);
  Future<void> setDefaultAddress(String userId, String addressId);
}
