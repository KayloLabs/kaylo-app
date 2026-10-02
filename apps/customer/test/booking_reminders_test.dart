import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/features/notifications/application/booking_reminders.dart';
import 'package:kaylo_core/models/booking.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  test('reminders stay on the work day and handle date-only care visits', () {
    final now = DateTime(2026, 10, 2, 12);
    expect(
      bookingReminderTime(DateTime(2026, 10, 3, 14), now),
      DateTime(2026, 10, 3, 8),
    );
    expect(
      bookingReminderTime(DateTime(2026, 10, 3, 7), now),
      DateTime(2026, 10, 3, 6),
    );
    expect(
      bookingReminderTime(DateTime(2026, 10, 3), now),
      DateTime(2026, 10, 3, 8),
    );
    expect(
      bookingReminderTime(DateTime(2026, 10, 3, 0, 30), now),
      DateTime(2026, 10, 3),
    );
    expect(
      bookingReminderTime(DateTime(2026, 10, 2, 13), now),
      DateTime(2026, 10, 2, 13),
    );
    expect(bookingReminderTime(DateTime(2026, 10, 1, 10), now), isNull);
  });
  test(
    'notification identities separate accounts and confirmation from reminder',
    () {
      expect(
        bookingNotificationId('u', 'b', 'visit'),
        bookingNotificationId('u', 'b', 'visit'),
      );
      expect(
        bookingNotificationId('u', 'b', 'visit'),
        isNot(bookingNotificationId('v', 'b', 'visit')),
      );
      expect(
        bookingNotificationId('u', 'b', 'visit'),
        isNot(bookingNotificationId('u', 'b', 'receipt')),
      );
    },
  );
  test(
    'one confirmation, reschedule replacement, cancellation and sign-out cleanup',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = BookingReminders(await SharedPreferences.getInstance());
      final calls = <MethodCall>[];
      final pending = <int, Map<String, dynamic>>{};
      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            final args = call.arguments;
            switch (call.method) {
              case 'initialize':
              case 'requestNotificationsPermission':
                return true;
              case 'getNotificationAppLaunchDetails':
                return {'notificationLaunchedApp': false};
              case 'pendingNotificationRequests':
                return pending.values.toList();
              case 'zonedSchedule':
                pending[args['id']] = {
                  'id': args['id'],
                  'title': args['title'],
                  'body': args['body'],
                  'payload': args['payload'],
                };
              case 'cancel':
                pending.remove(args['id']);
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final date = DateTime.now().add(const Duration(days: 2));
      final booking = Booking(
        id: 'visit-1',
        userId: 'user-1',
        serviceId: 'plumb',
        scheduledAt: date,
        status: BookingStatus.confirmed,
        totalAmount: 100,
      );
      await service.received(booking, 'Plumbing');
      await service.received(booking, 'Plumbing');
      expect(calls.where((c) => c.method == 'show'), hasLength(1));
      expect(pending, hasLength(1));
      final moved = booking.copyWith(
        scheduledAt: date.add(const Duration(days: 1)),
      );
      await service.sync(
        'user-1',
        [moved],
        {'plumb': 'Plumbing'},
        notificationsEnabled: true,
      );
      expect(pending, hasLength(1));
      expect(
        calls
            .lastWhere((c) => c.method == 'zonedSchedule')
            .arguments['scheduledDateTime'],
        contains('${moved.scheduledAt.toUtc().year}'),
      );
      await service.sync(
        'user-1',
        [booking.copyWith(status: BookingStatus.cancelled)],
        {},
        notificationsEnabled: true,
      );
      expect(pending, isEmpty);
      await service.sync('user-1', [booking], {}, notificationsEnabled: true);
      await service.sync(null, null, {}, notificationsEnabled: true);
      expect(pending, isEmpty);
      await service.sync('user-1', [booking], {}, notificationsEnabled: false);
      expect(pending, isEmpty);
    },
  );
}
