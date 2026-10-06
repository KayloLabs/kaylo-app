import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kaylo_core/models/booking.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../auth/application/current_user_provider.dart';
import '../../auth/application/session_controller.dart';
import '../../booking/application/bookings_providers.dart';
import '../../home/application/home_providers.dart';

final notificationsEnabledProvider =
    NotifierProvider<NotificationsPreference, bool>(
      NotificationsPreference.new,
    );

class NotificationsPreference extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool('notifications_enabled') ??
      true;
  Future<void> setEnabled(bool value) async {
    state = value;
    await ref
        .read(sharedPreferencesProvider)
        .setBool('notifications_enabled', value);
  }
}

/// At 8am on the visit day, or one hour before an earlier appointment.
/// Same-day bookings get a reminder at the appointment if that lead time passed.
DateTime? bookingReminderTime(DateTime scheduledAt, DateTime now) {
  final local = scheduledAt.toLocal();
  // Caregiver dates can be date-only (midnight); remind at 8 on that day.
  final visit = local.hour == 0 && local.minute == 0
      ? DateTime(local.year, local.month, local.day, 9)
      : local;
  if (!visit.isAfter(now)) return null;
  final morning = DateTime(visit.year, visit.month, visit.day, 8);
  final start = DateTime(visit.year, visit.month, visit.day);
  final before = visit.subtract(const Duration(hours: 1));
  final lead = before.isBefore(start) ? start : before;
  final planned = morning.isBefore(lead) ? morning : lead;
  return planned.isAfter(now) ? planned : visit;
}

/// Stable across process restarts. The payload supplies the full identity.
int bookingNotificationId(String user, String booking, String kind) {
  var hash = 0x811c9dc5;
  for (final byte in '$user:$booking:$kind'.codeUnits) {
    hash = ((hash ^ byte) * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

class BookingReminders {
  BookingReminders(this.prefs);
  final SharedPreferences prefs;
  final plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;
  Future<void> _queue = Future.value();
  void Function(String userId, String bookingId)? onOpen;
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  bool get enabled => prefs.getBool('notifications_enabled') ?? true;
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'kaylo_bookings',
      'Bookings & visit reminders',
      channelDescription:
          'Booking confirmations and reminders on the day of your service',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
    ),
    iOS: DarwinNotificationDetails(),
  );

  void _open(String? payload) {
    final parts = payload?.split('|');
    if (parts?.length == 3 && parts![0] == 'booking') {
      onOpen?.call(parts[1], parts[2]);
    }
  }

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    if (!supported) return;
    tz.setLocalLocation(tz.UTC);
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => _open(response.payload),
    );
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _open(launch?.notificationResponse?.payload);
    }
  }

  Future<void> requestPermission() async {
    if (!supported) return;
    await initialize();
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Serializes OS operations so a slow refresh cannot restore a cancelled alarm.
  Future<void> _serial(Future<void> Function() work) {
    _queue = _queue.then((_) => work()).catchError((
      Object error,
      StackTrace stack,
    ) {
      // Notification availability must never turn a paid checkout into a failure.
      debugPrint('Booking notification unavailable: ${error.runtimeType}');
    });
    return _queue;
  }

  Future<void> received(Booking booking, String name) => _serial(() async {
    if (!supported || !enabled) return;
    await requestPermission();
    final key = 'booking_notice:${booking.userId}:${booking.id}';
    if (prefs.getBool(key) != true) {
      await plugin.show(
        bookingNotificationId(booking.userId, booking.id, 'receipt'),
        booking.status == BookingStatus.confirmed
            ? 'Booking confirmed'
            : 'Booking request received',
        '$name · ${DateFormat('EEE, d MMM · h:mm a').format(booking.scheduledAt.toLocal())}',
        _details,
        payload: 'booking|${booking.userId}|${booking.id}',
      );
      await prefs.setBool(key, true);
    }
    await _schedule(booking, name);
  });

  Future<void> _schedule(Booking booking, String name) async {
    final when = bookingReminderTime(booking.scheduledAt, DateTime.now());
    if (when == null) return;
    // One-shot UTC instant retains the booking's actual time across zones.
    await plugin.zonedSchedule(
      bookingNotificationId(booking.userId, booking.id, 'visit'),
      'Your Kaylo service is today',
      '$name · ${DateFormat.jm().format(booking.scheduledAt.toLocal())}',
      tz.TZDateTime.from(when.toUtc(), tz.UTC),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'booking|${booking.userId}|${booking.id}',
    );
  }

  Future<void> sync(
    String? userId,
    List<Booking>? bookings,
    Map<String, String> names, {
    required bool notificationsEnabled,
  }) => _serial(() async {
    if (!supported) return;
    await initialize();
    final pending = await plugin.pendingNotificationRequests();
    if (userId == null || !notificationsEnabled) {
      for (final item in pending.where(
        (n) => n.payload?.startsWith('booking|') == true,
      )) {
        await plugin.cancel(item.id);
      }
      return;
    }
    // Preserve this user's alarms during a transient fetch failure/loading state.
    if (bookings == null) {
      for (final item in pending.where(
        (n) =>
            n.payload?.startsWith('booking|') == true &&
            !n.payload!.startsWith('booking|$userId|'),
      )) {
        await plugin.cancel(item.id);
      }
      return;
    }
    final upcoming =
        bookings
            .where(
              (b) =>
                  bookingReminderTime(b.scheduledAt, DateTime.now()) != null &&
                  (b.status == BookingStatus.confirmed ||
                      (b.status == BookingStatus.pending &&
                          prefs.getBool('booking_notice:$userId:${b.id}') ==
                              true)),
            )
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    // iOS allows 64 pending requests. Leave headroom for other app reminders.
    final nearest = upcoming.take(60).toList();
    final wanted = nearest
        .map((b) => bookingNotificationId(userId, b.id, 'visit'))
        .toSet();
    for (final item in pending.where(
      (n) =>
          n.payload?.startsWith('booking|') == true &&
          (!n.payload!.startsWith('booking|$userId|') ||
              !wanted.contains(n.id)),
    )) {
      await plugin.cancel(item.id);
    }
    for (final booking in nearest) {
      await _schedule(
        booking,
        names[booking.serviceId] ?? 'Your booked service',
      );
    }
  });
}

final bookingRemindersProvider = Provider<BookingReminders>(
  (ref) => BookingReminders(ref.read(sharedPreferencesProvider)),
);

final bookingReminderSyncProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserIdProvider);
  if (user == null && ref.watch(sessionControllerProvider).isLoading) return;
  final enabled = ref.watch(notificationsEnabledProvider);
  final bookings = user == null
      ? null
      : ref.watch(userBookingsProvider).asData?.value;
  final catalog = user == null
      ? null
      : ref.watch(fullCatalogProvider).asData?.value;
  unawaited(
    ref.read(bookingRemindersProvider).sync(user, bookings, {
      for (final service in catalog ?? []) service.id: service.name,
    }, notificationsEnabled: enabled),
  );
});
