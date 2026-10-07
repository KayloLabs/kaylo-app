import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/kaylo_core.dart';
import 'package:kaylo_ui/kaylo_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const KayloPartnerApp(),
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
      title: 'Kaylo Partner',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      locale: ref.watch(partnerLocaleProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
