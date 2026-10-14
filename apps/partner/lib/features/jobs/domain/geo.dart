import 'dart:math' as math;

/// Computes the great-circle distance between two geographic coordinates
/// in kilometers using the Haversine formula.
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;

  final dLat = _degToRad(lat2 - lat1);
  final dLng = _degToRad(lng2 - lng1);

  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);

  final c = 2 * math.asin(math.sqrt(a));
  return earthRadiusKm * c;
}

/// Calculates estimated travel time in minutes based on distance and average speed.
int etaMinutes(double distanceKm, {double speedKmh = 25.0}) {
  if (distanceKm <= 0) return 0;
  return ((distanceKm / speedKmh) * 60).round();
}

double _degToRad(double degree) => degree * (math.pi / 180.0);
