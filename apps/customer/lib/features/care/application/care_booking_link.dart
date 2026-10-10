import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/models/service_item.dart';

import '../domain/models/appointment.dart';
import '../domain/models/caregiver.dart';
import 'care_providers.dart';

/// Which kind of Care booking a service produces. Doctors and caregivers
/// are chosen by the customer at booking time, so the "worker will be
/// assigned" wording of home and farm jobs never applies to them.
enum CareKind { doctor, caregiver, other }

CareKind? careKindOf(ServiceItem? service) {
  if (service == null || service.category != 'care') return null;
  final name = service.name.toLowerCase();
  if (name.contains('doctor')) return CareKind.doctor;
  if (name.contains('caregiver')) return CareKind.caregiver;
  return CareKind.other;
}

bool isCareService(ServiceItem? service) => service?.category == 'care';

/// The doctor appointment or caregiver booking behind a Care booking row,
/// found through the booking id both records carry.
class CareBookingInfo {
  final DoctorAppointment? appointment;
  final CaregiverBookingRecord? caregiverBooking;

  const CareBookingInfo({this.appointment, this.caregiverBooking});

  static const none = CareBookingInfo();

  bool get isEmpty => appointment == null && caregiverBooking == null;

  /// What the record says it is, which beats guessing from the service name.
  CareKind? get kind => appointment != null
      ? CareKind.doctor
      : caregiverBooking != null
      ? CareKind.caregiver
      : null;
}

final careBookingInfoProvider = FutureProvider.family<CareBookingInfo, String>((
  ref,
  bookingId,
) async {
  final appointments = await ref.watch(doctorAppointmentsProvider.future);
  final appointment = appointments
      .where((a) => a.bookingId == bookingId)
      .firstOrNull;
  if (appointment != null) return CareBookingInfo(appointment: appointment);

  final caregiverBookings = await ref.watch(caregiverBookingsProvider.future);
  final caregiverBooking = caregiverBookings
      .where((b) => b.bookingId == bookingId)
      .firstOrNull;
  if (caregiverBooking != null) {
    return CareBookingInfo(caregiverBooking: caregiverBooking);
  }
  return CareBookingInfo.none;
});
