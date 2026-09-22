import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/storage_service.dart';

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

  const UserLocation({
    required this.label,
    this.addressLine,
    this.latitude,
    this.longitude,
  });

  /// Until the customer shares a location, every account is in Kannur,
  /// where the seeded workers are.
  static const fallback = UserLocation(label: 'Kannur, Kerala');

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
  );

  Map<String, dynamic> toJson() => {
    'label': label,
    'addressLine': addressLine,
    'latitude': latitude,
    'longitude': longitude,
  };
}

final userLocationProvider =
    NotifierProvider<UserLocationNotifier, UserLocation>(
      UserLocationNotifier.new,
    );

class UserLocationNotifier extends Notifier<UserLocation> {
  @override
  UserLocation build() {
    // Widget tests build screens without SharedPreferences; the fallback
    // keeps them (and a fresh install) working.
    try {
      final raw = ref
          .read(sharedPreferencesProvider)
          .getString('active_location');
      if (raw != null) {
        return UserLocation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
    return UserLocation.fallback;
  }

  Future<void> set(UserLocation location) async {
    state = location;
    await ref
        .read(storageServiceProvider)
        .saveActiveLocation(jsonEncode(location.toJson()));
  }

  Future<void> setLabel(String label) => set(UserLocation(label: label));
}
