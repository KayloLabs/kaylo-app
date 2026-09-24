import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase for the platform services both apps use: Authentication
/// (phone OTP), Cloud Messaging, Crashlytics and Analytics. The data
/// stays in Supabase, which accepts the Firebase ID token as a
/// third-party JWT (see supabase/migrations/0005).
class FirebaseBootstrap {
  FirebaseBootstrap._();

  /// True once [initialize] succeeded on this platform. Screens and
  /// providers use it to fall back gracefully where Firebase is not
  /// configured (desktop builds, a checkout without config files).
  static bool get isReady => Firebase.apps.isNotEmpty;

  /// Initializes Firebase with the app's generated options and routes
  /// uncaught errors to Crashlytics on mobile. Throws
  /// [UnsupportedError] when the current platform has no options, which
  /// callers treat as "run without Firebase".
  static Future<void> initialize(FirebaseOptions options) async {
    await Firebase.initializeApp(options: options);
    if (kIsWeb) return;

    final crashlytics = FirebaseCrashlytics.instance;
    // Debug sessions would drown the dashboard in developer crashes.
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  /// What Supabase verifies instead of its own session: the current
  /// Firebase user's ID token, refreshed by the SDK as needed. Null when
  /// nobody is signed in, so anonymous catalog reads still work.
  static Future<String?> supabaseAccessToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken();
    } catch (_) {
      return null;
    }
  }
}
