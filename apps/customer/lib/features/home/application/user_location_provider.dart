import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaylo_core/services/location_service.dart';
import 'package:kaylo_core/services/storage_service.dart';
import '../../profile/domain/saved_address.dart';
import '../../auth/application/current_user_provider.dart';

/// The customer's active location: what the dashboard header shows and
/// what SOS alerts share. Captured by Location Setup or the header pill,
/// persisted locally.
///
/// TODO(M2): mirror it to the persons/locations tables so it follows the
/// account across devices.
class UserLocation {
  final String label;
  final String? addressLine;
  final double? latitude;
  final double? longitude;
  final String? savedAddressId;

  const UserLocation({
    required this.label,
    this.addressLine,
    this.latitude,
    this.longitude,
    this.savedAddressId,
  });

  /// Until the customer shares a location, every account is in Kannur,
  /// where the seeded workers are.
  static const fallback = UserLocation(label: 'Kannur, Kerala');

  String get fullAddress =>
      addressLine?.trim().isNotEmpty == true ? addressLine!.trim() : label;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get bookingNotes => hasCoordinates
      ? '$fullAddress\nMap: https://www.google.com/maps/search/?api=1&query=$latitude,$longitude'
      : fullAddress;

  factory UserLocation.fromSavedAddress(SavedAddress address) => UserLocation(
    label: address.label,
    addressLine: address.line,
    latitude: address.latitude,
    longitude: address.longitude,
    savedAddressId: address.id,
  );

  bool get isFallback => identical(this, fallback);

  factory UserLocation.fromResolved(ResolvedLocation resolved) => UserLocation(
    label: resolved.label,
    addressLine: resolved.addressLine,
    latitude: resolved.latitude,
    longitude: resolved.longitude,
  );

  factory UserLocation.fromJson(Map<String, dynamic> json) => UserLocation(
    label: json['label'] as String,
    addressLine: json['addressLine'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    savedAddressId: json['savedAddressId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'label': label,
    'addressLine': addressLine,
    'latitude': latitude,
    'longitude': longitude,
    'savedAddressId': savedAddressId,
  };
}

final userLocationProvider =
    NotifierProvider<UserLocationNotifier, UserLocation>(
      UserLocationNotifier.new,
    );

class UserLocationNotifier extends Notifier<UserLocation> {
  @override
  UserLocation build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return UserLocation.fallback;
    // A saved address belongs to its owner. Never restore the former shared
    // active_location value into a different signed-in account.
    try {
      final raw = ref
          .read(sharedPreferencesProvider)
          .getString('active_location:$userId');
      if (raw != null) {
        return UserLocation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
    return UserLocation.fallback;
  }

  Future<void> set(UserLocation location) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      'active_location:$userId',
      jsonEncode(location.toJson()),
    );
    if (ref.read(currentUserIdProvider) == userId) state = location;
  }

  Future<void> setLabel(String label) => set(UserLocation(label: label));
}
