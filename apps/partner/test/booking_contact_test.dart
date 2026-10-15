import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_partner/features/jobs/domain/booking_destination.dart';
import 'package:kaylo_partner/features/jobs/data/supabase_jobs_repository.dart';
import 'supabase_jobs_repository_test.dart' show row;

void main() {
  const notes =
      'Kitchen sink\nMap: https://www.google.com/maps/search/?api=1&query=11.87,75.37';
  test('one-off checkout pin is available without a saved address', () {
    final job = partnerJobFromRow(row()..['notes'] = notes);
    expect(job.latitude, 11.87);
    expect(job.longitude, 75.37);
  });
  test('a valid saved pin takes priority; partial pairs never get mixed', () {
    final data = row()
      ..['notes'] = notes
      ..['latitude'] = 12.0
      ..['longitude'] = 76.0;
    expect(partnerJobFromRow(data).latitude, 12);
    data['longitude'] = null;
    expect(partnerJobFromRow(data).latitude, 11.87);
    expect(partnerJobFromRow(data).longitude, 75.37);
  });
  test('untrusted, malformed and out-of-range pins are rejected', () {
    for (final value in [
      'Map: https://example.com/maps/search/?query=11,75',
      'Map: https://www.google.com/maps/search/?query=NaN,75',
      'Map: https://www.google.com/maps/search/?query=91,75',
      'Map: https://www.google.com/maps/search/?query=11,181',
      'Map: https://www.google.com/maps/search/?query=11',
    ]) {
      expect(bookingPin(value), isNull);
    }
  });
  test('only unpaid cash work in progress requires collection', () {
    final data = row(status: 'in_progress')
      ..['payment_mode'] = 'cash'
      ..['customer_price'] = 500
      ..['payment_status'] = 'pending';
    final job = partnerJobFromRow(data);
    expect(job.needsCashCollection, isTrue);
    expect(job.customerPrice, 500);
    expect(job.payout, 425);
    data['payment_status'] = 'success';
    expect(partnerJobFromRow(data).needsCashCollection, isFalse);
    data['payment_status'] = 'pending';
    data['payment_mode'] = 'online';
    expect(partnerJobFromRow(data).needsCashCollection, isFalse);
    data['payment_mode'] = 'cash';
    data['status'] = 'completed';
    expect(partnerJobFromRow(data).needsCashCollection, isFalse);
  });
}
