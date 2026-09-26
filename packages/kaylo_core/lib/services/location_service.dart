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
  /// Where the device is now, as a readable place.
  Future<ResolvedLocation> locate();

  /// A readable place for coordinates, for a pin dropped on the map.
  /// Never throws: when the lookup fails the coordinates become the label.
  Future<ResolvedLocation> resolve(double latitude, double longitude);

  /// The best match for a typed place name, or null when nothing matched.
  Future<ResolvedLocation?> search(String query);
}

/// GPS through geolocator (web, Android, iOS), then geocoding through
/// OpenStreetMap's Nominatim, which works on every platform without an
/// API key. Geocoding is best effort: when it fails the coordinates
/// still come back as the label.
class GeolocatorLocationService implements LocationService {
  static const _host = 'nominatim.openstreetmap.org';

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

    return resolve(position.latitude, position.longitude);
  }

  @override
  Future<ResolvedLocation> resolve(double latitude, double longitude) async {
    final fallback = ResolvedLocation(
      latitude: latitude,
      longitude: longitude,
      label: '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
    );
    try {
      final uri = Uri.https(_host, '/reverse', {
        'format': 'jsonv2',
        'lat': '$latitude',
        'lon': '$longitude',
        'zoom': '16',
        'addressdetails': '1',
      });
      final response = await _get(uri);
      if (response.statusCode != 200) return fallback;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _fromNominatim(json, latitude, longitude) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Future<ResolvedLocation?> search(String query) async {
    final text = query.trim();
    if (text.isEmpty) return null;
    try {
      final uri = Uri.https(_host, '/search', {
        'q': text,
        'format': 'jsonv2',
        'limit': '1',
        'addressdetails': '1',
        // Kaylo serves Kerala: keep matches in India so a town name does
        // not land on a street with the same name elsewhere.
        'countrycodes': 'in',
      });
      final response = await _get(uri);
      if (response.statusCode != 200) return null;
      final results = jsonDecode(response.body) as List<dynamic>;
      if (results.isEmpty) return null;
      final json = results.first as Map<String, dynamic>;
      final lat = double.tryParse('${json['lat']}');
      final lng = double.tryParse('${json['lon']}');
      if (lat == null || lng == null) return null;
      return _fromNominatim(json, lat, lng, preferName: true) ??
          ResolvedLocation(latitude: lat, longitude: lng, label: text);
    } catch (_) {
      return null;
    }
  }

  Future<http.Response> _get(Uri uri) => _http
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

  /// Builds the label and address line from a Nominatim result (shared
  /// by reverse and forward lookups). Null when the response had no
  /// usable place name.
  ///
  /// [preferName] is for search results: a town query often matches the
  /// district or municipality boundary, whose `address` has no town
  /// key, so the matched feature's own name is the locality. Reverse
  /// lookups never use it, since there `name` is whatever building or
  /// road is nearest.
  ResolvedLocation? _fromNominatim(
    Map<String, dynamic> json,
    double lat,
    double lng, {
    bool preferName = false,
  }) {
    final address =
        (json['address'] as Map?)?.cast<String, dynamic>() ?? const {};
    String? pick(List<String> keys) {
      for (final key in keys) {
        final value = address[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return null;
    }

    final name = (json['name'] as String?)?.trim();
    final locality =
        pick(['village', 'town', 'city', 'municipality', 'suburb']) ??
        (preferName && name != null && name.isNotEmpty ? name : null) ??
        pick(['county', 'state_district']);
    final label = [
      locality,
      pick(['state']),
    ].whereType<String>().join(', ');
    if (label.isEmpty) return null;

    final line = [
      pick(['road', 'neighbourhood', 'hamlet']),
      pick(['suburb', 'village', 'town', 'city']),
      pick(['state_district', 'county']),
      pick(['postcode']),
    ].whereType<String>().toSet().join(', ');

    return ResolvedLocation(
      latitude: lat,
      longitude: lng,
      label: label,
      // A line that only repeats the label ("Palakkad" under "Palakkad,
      // Kerala") says nothing new.
      addressLine: line.isEmpty || label.contains(line) ? null : line,
    );
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorLocationService();
});
