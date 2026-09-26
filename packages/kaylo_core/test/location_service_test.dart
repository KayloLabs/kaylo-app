import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaylo_core/services/location_service.dart';

/// Nominatim stand-in: answers /reverse and /search from canned JSON.
GeolocatorLocationService _service({
  Map<String, dynamic>? reverse,
  List<Map<String, dynamic>> search = const [],
  int status = 200,
}) {
  return GeolocatorLocationService(
    client: MockClient((request) async {
      final body = request.url.path == '/reverse'
          ? jsonEncode(reverse ?? {})
          : jsonEncode(search);
      return http.Response(body, status);
    }),
  );
}

void main() {
  group('resolve', () {
    test('builds a town label and a street line', () async {
      final service = _service(
        reverse: {
          'name': 'Fort Road',
          'address': {
            'road': 'Fort Road',
            'town': 'Kannur',
            'state_district': 'Kannur',
            'state': 'Kerala',
            'postcode': '670001',
          },
        },
      );

      final result = await service.resolve(11.8745, 75.3704);

      expect(result.label, 'Kannur, Kerala');
      expect(result.addressLine, 'Fort Road, Kannur, 670001');
      expect(result.latitude, 11.8745);
    });

    test('ignores the nearest feature name for a pin in the open', () async {
      // A pin on farmland: no locality keys, only a nearby feature name.
      final service = _service(
        reverse: {
          'name': 'Some Estate',
          'address': {'state_district': 'Wayanad', 'state': 'Kerala'},
        },
      );

      final result = await service.resolve(11.7, 76.1);

      expect(result.label, 'Wayanad, Kerala');
      expect(result.addressLine, isNull);
    });

    test('falls back to coordinates when the lookup fails', () async {
      final service = _service(status: 503);

      final result = await service.resolve(11.87451, 75.37042);

      expect(result.label, '11.8745, 75.3704');
      expect(result.addressLine, isNull);
    });
  });

  group('search', () {
    test('names a district match after the feature, not the state', () async {
      // Nominatim's top hit for "Palakkad" is the district boundary.
      final service = _service(
        search: [
          {
            'lat': '10.7867',
            'lon': '76.6548',
            'name': 'Palakkad',
            'address': {'state_district': 'Palakkad', 'state': 'Kerala'},
          },
        ],
      );

      final result = await service.search('Palakkad');

      expect(result, isNotNull);
      expect(result!.label, 'Palakkad, Kerala');
      expect(result.addressLine, isNull);
      expect(result.latitude, 10.7867);
      expect(result.longitude, 76.6548);
    });

    test('prefers a town key over the feature name', () async {
      final service = _service(
        search: [
          {
            'lat': '11.8745',
            'lon': '75.3704',
            'name': 'Kannur Municipality',
            'address': {'town': 'Kannur', 'state': 'Kerala'},
          },
        ],
      );

      final result = await service.search('Kannur');

      expect(result!.label, 'Kannur, Kerala');
    });

    test('returns null for no match, blank input or an error', () async {
      expect(await _service().search('Nowhere'), isNull);
      expect(await _service().search('   '), isNull);
      expect(await _service(status: 500).search('Kannur'), isNull);
    });
  });
}
