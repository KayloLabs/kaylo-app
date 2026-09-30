import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Asks the server to email the "Booking received" note for a booking
/// paid after the service (paid ones get the invoice instead). Never
/// throws: the booking stands whether or not the mail goes out.
Future<bool> sendBookingReceivedEmail(
  SupabaseClient client, {
  required String bookingId,
  String? email,
}) async {
  try {
    await client.functions.invoke(
      'booking-email',
      body: {
        'booking_id': bookingId,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
    return true;
  } catch (e) {
    debugPrint('Kaylo: booking email not sent: $e');
    return false;
  }
}
