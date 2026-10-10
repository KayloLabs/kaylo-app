import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/kaylo_core.dart';
import 'package:kaylo_ui/kaylo_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/providers/locale_provider.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  try {
    await FirebaseBootstrap.initialize(DefaultFirebaseOptions.currentPlatform);
  } on UnsupportedError {
    // No Firebase options for this platform (desktop, or not configured
    // yet); the app still runs, without push, crash reports or analytics.
  }

  if (supabaseConfigured) {
    // The worker signs in with Firebase; Supabase verifies the Firebase
    // ID token instead of running its own auth (migration 0005).
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      accessToken: FirebaseBootstrap.isReady && !useMock
          ? FirebaseBootstrap.supabaseAccessToken
          : null,
    );
  }
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: DevicePreview(
        // Phone-frame emulator whenever we run in a desktop browser, the
        // same as the customer app; real devices get the app full-screen.
        // FRAMELESS=true drops the frame on web too, for screenshots.
        enabled: kIsWeb && !const bool.fromEnvironment('FRAMELESS'),
        builder: (context) => const KayloPartnerApp(),
      ),
    ),
  );
}

/// The worker-side app. Shares theme, widgets, models and backend access
/// with the customer app through kaylo_ui and kaylo_core; its own
/// features (jobs inbox, job detail, availability, earnings) are routed
/// here through [partnerRouterProvider].
class KayloPartnerApp extends ConsumerWidget {
  const KayloPartnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(partnerRouterProvider);
    return MaterialApp.router(
      // No debug ribbon in demos; release builds never show it anyway.
      debugShowCheckedModeBanner: false,
      title: 'Kaylo Partner',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      builder: DevicePreview.appBuilder,
      routerConfig: router,
      locale: ref.watch(partnerLocaleProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
