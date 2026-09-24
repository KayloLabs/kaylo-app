// Placeholder until `flutterfire configure --project=<id>` is run in
// apps/customer, which replaces this file with the real per-platform
// options. Until then the app starts without Firebase (mock or
// Supabase-only auth), exactly like a desktop build would.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase is not configured for this app yet: run flutterfire configure.',
    );
  }
}
