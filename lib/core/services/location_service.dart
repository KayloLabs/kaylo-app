import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../network/app_failure.dart';

/// A device position resolved to something a person can read.
class ResolvedLocation {
  final double latitude;
  final double longitude;

  /// Short label for headers: "Kannur, Kerala".
  final String label;

  /// Street-level line for address fields, when reverse geocoding had one.
  final String? addressLine;

  const ResolvedLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
    this.addressLine,
  });
}

/// Why locating failed. `code` is one of: services-disabled, denied,
/// denied-forever, timeout, unavailable.
class LocationFailure extends AppFailure {
  LocationFailure(
    super.message, {
    required String super.code,
    super.originalError,
  });
}

abstract class LocationService {
  Future<ResolvedLocation> locate();
}

/// GPS through geolocator (web, Android, iOS), then reverse geocoding
/// through OpenStreetMap's Nominatim, which works on every platform
/// without an API key. Geocoding is best effort: when it fails the
/// coordinates still come back as the label.
class GeolocatorLocationService implements LocationService {
  final http.Client _http;

  GeolocatorLocationService({http.Client? client})
    : _http = client ?? http.Client();

  @override
  Future<ResolvedLocation> locate() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationFailure(
        'Location services are turned off',
        code: 'services-disabled',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationFailure(
        'Location permission is blocked',
        code: 'denied-forever',
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw LocationFailure(
        'Location permission was not granted',
        code: 'denied',
      );
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      throw LocationFailure('Could not get a fix in time', code: 'timeout');
    } catch (e) {
      throw LocationFailure(
        'Location is unavailable right now',
        code: 'unavailable',
        originalError: e,
      );
    }

    return reverseGeocode(position.latitude, position.longitude);
  }

  Future<ResolvedLocation> reverseGeocode(double lat, double lng) async {
    final fallback = ResolvedLocation(
      latitude: lat,
      longitude: lng,
      label: '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
    );
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': '$lat',
        'lon': '$lng',
        'zoom': '16',
        'addressdetails': '1',
      });
      final response = await _http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              // Nominatim's usage policy asks for an identifying agent; the
              // browser sets its own on web and rejects a custom one.
              if (!kIsWeb) 'User-Agent': 'Kaylo/1.0 (KayloLabs/kaylo-app)',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return fallback;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final address =
          (json['address'] as Map?)?.cast<String, dynamic>() ?? const {};
      String? pick(List<String> keys) {
        for (final key in keys) {
          final value = address[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
        return null;
      }

      final locality = pick([
        'village',
        'town',
        'city',
        'municipality',
        'suburb',
        'county',
      ]);
      final label = [
        locality,
        pick(['state']),
      ].whereType<String>().join(', ');
      final line = [
        pick(['road', 'neighbourhood', 'hamlet']),
        pick(['suburb', 'village', 'town', 'city']),
        pick(['state_district', 'county']),
        pick(['postcode']),
      ].whereType<String>().toSet().join(', ');

      return ResolvedLocation(
        latitude: lat,
        longitude: lng,
        label: label.isEmpty ? fallback.label : label,
        addressLine: line.isEmpty ? null : line,
      );
    } catch (_) {
      return fallback;
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorLocationService();
});
