import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/booking.dart';
import '../../../core/network/supabase_providers.dart';
import '../domain/bookings_repository.dart';

/// Bookings against the `bookings` table. The app model's single
/// `scheduledAt` maps to the schema's `booking_date` + `booking_time`,
/// and `totalAmount` maps to `estimated_cost` (until `final_cost` lands
/// with payments in R2).
class SupabaseBookingsRepository implements BookingsRepository {
  final SupabaseClient _client;

  SupabaseBookingsRepository(this._client);

  @override
  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final rows = await _client
          .from('bookings')
          .select()
          .eq('customer_id', userId)
          .order('created_at', ascending: false);
      return rows.map(_bookingFromRow).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    try {
      final row = await _client
          .from('bookings')
          .insert({
            'customer_id': booking.userId,
            'worker_id': booking.workerId,
            'service_id': booking.serviceId,
            'booking_date': _dateString(booking.scheduledAt),
            'booking_time': _timeString(booking.scheduledAt),
            'status': _statusToDb(booking.status),
            'estimated_cost': booking.totalAmount,
            'location_id': booking.locationId,
            'notes': booking.notes,
          })
          .select()
          .single();
      return _bookingFromRow(row);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _client
          .from('bookings')
          .update({'status': _statusToDb(status)})
          .eq('booking_id', bookingId);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Booking _bookingFromRow(Map<String, dynamic> row) {
    return Booking(
      id: row['booking_id'] as String,
      userId: row['customer_id'] as String,
      serviceId: row['service_id'] as String,
      workerId: row['worker_id'] as String?,
      scheduledAt: DateTime.parse(
          '${row['booking_date']}T${row['booking_time']}'),
      status: _statusFromDb(row['status'] as String),
      totalAmount: ((row['estimated_cost'] as num?) ?? 0).toDouble(),
      locationId: row['location_id'] as String?,
      notes: row['notes'] as String?,
      finalCost: (row['final_cost'] as num?)?.toDouble(),
    );
  }

  String _dateString(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  String _timeString(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:00';

  String _statusToDb(BookingStatus status) => switch (status) {
        BookingStatus.pending => 'pending',
        BookingStatus.confirmed => 'confirmed',
        BookingStatus.inProgress => 'in_progress',
        BookingStatus.completed => 'completed',
        BookingStatus.cancelled => 'cancelled',
      };

  BookingStatus _statusFromDb(String value) => switch (value) {
        'confirmed' => BookingStatus.confirmed,
        'in_progress' => BookingStatus.inProgress,
        'completed' => BookingStatus.completed,
        'cancelled' => BookingStatus.cancelled,
        _ => BookingStatus.pending,
      };
}
