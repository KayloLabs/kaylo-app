import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/services/location_service.dart';
import '../../../../data/mock/partner_seed.dart';

final partnerLocationProvider = FutureProvider<ResolvedLocation?>((ref) async {
  if (useMockData) {
    return const ResolvedLocation(
      latitude: PartnerSeed.workerLatitude,
      longitude: PartnerSeed.workerLongitude,
      label: 'Kannur',
    );
  }
  try {
    return await ref.read(locationServiceProvider).locate();
  } catch (_) {
    return null;
  }
});
// Override in tests to avoid network tiles. No test-binding detection in product code.
final jobMapTilesProvider = Provider<bool>((ref) => true);
