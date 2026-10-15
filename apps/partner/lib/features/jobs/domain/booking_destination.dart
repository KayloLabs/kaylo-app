/// Older customer checkouts preserved one-off pins in their notes rather than
/// attaching a saved address. Accept only the exact Maps link format we wrote.
({double latitude, double longitude})? bookingPin(String notes) {
  for (final line in notes.split('\n')) {
    if (!line.startsWith('Map: ')) continue;
    final uri = Uri.tryParse(line.substring(5).trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'www.google.com' ||
        uri.path != '/maps/search/') {
      continue;
    }
    final parts = uri.queryParameters['query']?.split(',');
    if (parts == null || parts.length != 2) continue;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null ||
        lng == null ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat.abs() > 90 ||
        lng.abs() > 180) {
      continue;
    }
    return (latitude: lat, longitude: lng);
  }
  return null;
}
