import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The customer's active location label, shown in the dashboard header
/// and attached to SOS alerts.
///
/// TODO(M2): read it from the persons/locations tables once Location
/// Setup writes `activeLocation`; until then every account is in Kannur.
final userLocationProvider = Provider<String>((ref) => 'Kannur, Kerala');
