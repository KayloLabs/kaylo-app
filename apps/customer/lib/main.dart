import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_preview/device_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'l10n/generated/app_localizations.dart';

import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/firebase/firebase_bootstrap.dart';
import 'core/router/app_router.dart';
import 'core/providers/care_mode_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_mode_provider.dart';
import 'features/notifications/application/push_registration.dart';
import 'firebase_options.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseBootstrap.initialize(DefaultFirebaseOptions.currentPlatform);
  } on UnsupportedError {
    // No Firebase options for this platform (desktop, or not configured
    // yet): sign-in falls back to Supabase OTP, no push or crash reports.
  }

  if (supabaseConfigured) {
    // Accepts either the legacy anon key or the new publishable key.
    // With Firebase signing people in, Supabase verifies the Firebase ID
    // token instead of running its own auth (third-party auth).
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      accessToken: FirebaseBootstrap.isReady && !useMock
          ? FirebaseBootstrap.supabaseAccessToken
          : null,
    );
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: DevicePreview(
        // Phone-frame emulator whenever we run in a desktop browser;
        // real devices get the app full-screen. FRAMELESS=true drops the
        // frame on web too, for automated screenshots.
        enabled: kIsWeb && !const bool.fromEnvironment('FRAMELESS'),
        builder: (context) => const KayloApp(),
      ),
    ),
  );
}

class KayloApp extends ConsumerWidget {
  const KayloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    ref.watch(pushRegistrationProvider);
    // Care Mode overrides the whole app with the senior-friendly shell:
    // careTheme is deliberately always-light for maximum legibility.
    final careMode = ref.watch(careModeProvider);

    return MaterialApp.router(
      title: 'Kaylo',
      theme: careMode ? AppTheme.careTheme : AppTheme.lightTheme,
      darkTheme: careMode ? AppTheme.careTheme : AppTheme.darkTheme,
      themeMode: careMode ? ThemeMode.light : ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: DevicePreview.appBuilder,
      routerConfig: router,
    );
  }
}
