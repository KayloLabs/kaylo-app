import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kaylo_core/models/service_item.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo/features/auth/application/current_user_provider.dart';
import 'package:kaylo/features/farm/domain/farm_booking_draft.dart';
import 'package:kaylo/features/home/application/user_location_provider.dart';
import 'package:kaylo/features/profile/domain/saved_address.dart';

void main() {
  test('saved address retains its identity, full address and pin', () {
    final location = UserLocation.fromSavedAddress(
      const SavedAddress(
        id: 'farm-42',
        label: 'Farm',
        line: 'East road, Palakkad',
        latitude: 10.7,
        longitude: 76.6,
      ),
    );
    final restored = UserLocation.fromJson(location.toJson());
    expect(restored.savedAddressId, 'farm-42');
    expect(restored.fullAddress, 'East road, Palakkad');
    expect(restored.bookingNotes, contains('query=10.7,76.6'));
  });

  test(
    'changing a booking address clears stale coordinates and saved address id',
    () {
      final draft = FarmBookingDraft(
        service: ServiceItem(
          id: '1',
          name: 'Plumbing',
          description: '',
          iconPath: '',
          category: 'home',
          basePrice: 400,
        ),
        date: DateTime(2026, 10, 4),
        slot: FarmTimeSlot.all.first,
        quantity: 1,
        address: 'Old house',
        locationId: 'old-id',
        latitude: 11,
        longitude: 75,
      );
      expect(
        draft.copyWith(quantity: 2).bookingNotes,
        contains('query=11.0,75.0'),
      );
      final edited = draft.copyWith(address: 'New house', clearLocation: true);
      expect(edited.locationId, isNull);
      expect(edited.latitude, isNull);
      expect(edited.longitude, isNull);
      expect(edited.bookingNotes, 'New house');
    },
  );

  test(
    'active address persists only for its owner and ignores global legacy id',
    () async {
      SharedPreferences.setMockInitialValues({
        'active_location': jsonEncode(
          const UserLocation(
            label: 'Other account',
            savedAddressId: 'unsafe-id',
          ).toJson(),
        ),
      });
      final prefs = await SharedPreferences.getInstance();
      ProviderContainer scope(String id) => ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserIdProvider.overrideWithValue(id),
        ],
      );
      final first = scope('first');
      final second = scope('second');
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      expect(first.read(userLocationProvider).isFallback, isTrue);
      await first
          .read(userLocationProvider.notifier)
          .set(
            const UserLocation(
              label: 'Home',
              addressLine: 'My street',
              savedAddressId: 'first-home',
            ),
          );
      expect(second.read(userLocationProvider).isFallback, isTrue);
      final restored = scope('first');
      addTearDown(restored.dispose);
      expect(restored.read(userLocationProvider).savedAddressId, 'first-home');
      expect(prefs.containsKey('active_location:second'), isFalse);
    },
  );
}
