import 'features/care/presentation/widgets/incoming_call_overlay.dart';
import 'dart:async';
import 'features/booking/application/bookings_providers.dart';
import 'features/notifications/application/notifications_providers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'features/notifications/application/booking_reminders.dart';
import 'features/auth/application/current_user_provider.dart';
import 'core/router/routes.dart';
import 'firebase_options.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phones: draw behind the status and navigation bars. Screens keep
  // their content clear of them with SafeArea, and the bar icons follow
  // the theme through the AnnotatedRegion in KayloApp.
  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

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
  KayloFeedback.hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
  KayloFeedback.soundsEnabled = prefs.getBool('sounds_enabled') ?? true;

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

class KayloApp extends ConsumerStatefulWidget {
  const KayloApp({super.key});
  @override
  ConsumerState<KayloApp> createState() => _KayloAppState();
}

class _KayloAppState extends ConsumerState<KayloApp>
    with WidgetsBindingObserver {
  Timer? _refresh;
  (String, String)? _pendingNotification;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh = Timer.periodic(const Duration(minutes: 1), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _refreshBookings();
      }
    });
  }

  void _refreshBookings() {
    if (ref.read(currentUserIdProvider) == null) return;
    ref.invalidate(userBookingsProvider);
    ref.invalidate(notificationsProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshBookings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    ref.watch(pushRegistrationProvider);
    ref.read(bookingRemindersProvider).onOpen = (userId, bookingId) {
      _pendingNotification = (userId, bookingId);
      if (ref.read(currentUserIdProvider) == userId) {
        _pendingNotification = null;
        router.go(Routes.bookingDetails(bookingId));
      }
    };
    ref.listen(currentUserIdProvider, (_, userId) {
      final pending = _pendingNotification;
      if (pending != null && pending.$1 == userId) {
        _pendingNotification = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) router.go(Routes.bookingDetails(pending.$2));
        });
      }
    });
    ref.watch(bookingReminderSyncProvider);
    // Care Mode overrides the whole app with the senior-friendly shell:
    // careTheme is deliberately always-light for maximum legibility.
    final careMode = ref.watch(careModeProvider);

    return MaterialApp.router(
      // No debug ribbon in demos; release builds never show it anyway.
      debugShowCheckedModeBanner: false,
      title: 'Kaylo',
      theme: careMode ? AppTheme.careTheme : AppTheme.lightTheme,
      darkTheme: careMode ? AppTheme.careTheme : AppTheme.darkTheme,
      themeMode: careMode ? ThemeMode.light : ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        // Transparent bars whose icons flip with the theme; screens with
        // an AppBar still set their own status bar icons on top of this.
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(
                statusBarColor: Colors.transparent,
                systemStatusBarContrastEnforced: false,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarContrastEnforced: false,
              ),
          child: DevicePreview.appBuilder(
            context,
            IncomingCallOverlay(
              router: router,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      routerConfig: router,
    );
  }
}
