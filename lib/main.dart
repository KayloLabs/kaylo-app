import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_preview/device_preview.dart';

import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/application/home_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: M2 Initialize Firebase
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: DevicePreview(
        enabled: useMock,
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

    return MaterialApp.router(
      title: 'Kaylo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      routerConfig: router,
    );
  }
}
