import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/core/models/service_item.dart';
import 'package:kaylo/features/booking/domain/booking_draft.dart';

void main() {
  final service = ServiceItem(
    id: '4',
    name: 'Plumbing',
    description: 'Repairs',
    iconPath: 'assets_kaylo/3d/icon_plumb.png',
    basePrice: 500,
    category: 'home',
  );

  BookingDraft draftFor(String timeSlot) => BookingDraft(
    service: service,
    date: DateTime(2026, 9, 24),
    timeSlot: timeSlot,
    address: 'Kaloor, Kochi',
    total: 550,
  );

  test('uses the selected slot start time when scheduling a booking', () {
    expect(draftFor('09:00 AM - 12:00 PM').scheduledAt.hour, 9);
    expect(draftFor('01:00 PM - 04:00 PM').scheduledAt.hour, 13);
    expect(draftFor('04:00 PM - 07:00 PM').scheduledAt.hour, 16);
  });
}
