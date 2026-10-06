/// Artwork used only when displaying existing care bookings.
abstract final class ServiceArtwork {
  static const doctor = 'assets_kaylo/3d_transparent/icon_doctor.png';
  static const caregiver = 'assets_kaylo/3d_transparent/icon_caregiver.png';

  static String resolve({
    required String name,
    required String category,
    required String fallback,
  }) {
    if (category == 'care') {
      final normalized = name.toLowerCase();
      if (normalized.contains('doctor')) return doctor;
      if (normalized.contains('caregiver')) return caregiver;
    }
    return fallback;
  }
}
