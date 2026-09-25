import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_bootstrap.dart';

/// A push message the app can act on: booking updates, chat, promos.
class PushMessage {
  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  const PushMessage({this.title, this.body, this.data = const {}});
}

abstract class NotificationService {
  /// Asks the OS for permission where needed (iOS, web) and prepares
  /// the token. Safe to call more than once.
  Future<void> initialize();

  /// The device's push token, or null when push is unavailable here.
  Future<String?> getToken();

  /// Fires when the platform rotates the token; the new value must be
  /// registered again.
  Stream<String> get onTokenRefresh;

  /// Messages received while the app is in the foreground.
  Stream<PushMessage> get onMessage;

  /// 'android', 'ios' or 'web', for the device_tokens row.
  String get platform;
}

/// Firebase Cloud Messaging on Android, iOS and web.
class FcmNotificationService implements NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  Future<void> initialize() async {
    await _messaging.requestPermission();
    if (!kIsWeb && Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      // Simulators without APNs, or a web build without a VAPID key.
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get onMessage => FirebaseMessaging.onMessage.map(
        (m) => PushMessage(
          title: m.notification?.title,
          body: m.notification?.body,
          data: m.data,
        ),
      );

  @override
  String get platform => kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
}

/// Used where Firebase is not initialized (mock runs, desktop builds).
class NotificationServiceStub implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<PushMessage> get onMessage => const Stream.empty();

  @override
  String get platform => 'android';
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  if (FirebaseBootstrap.isReady) return FcmNotificationService();
  return NotificationServiceStub();
});
