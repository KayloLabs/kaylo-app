import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/models/app_user.dart';
import 'package:kaylo/core/services/location_service.dart';
import 'package:kaylo/core/services/storage_service.dart';
import 'package:kaylo/features/auth/application/current_user_provider.dart';
import 'package:kaylo/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock repositories answer after short delays and loaders animate
/// forever, so plain pumps replace pumpAndSettle throughout.
Future<void> settle(WidgetTester tester, {int frames = 8}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Phone width, tall enough that lazy lists build every row, so taps on
/// widgets near the bottom of a screen land without scrolling.
void useTallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
}

final testUser = AppUser(
  id: 'mock_uid_1',
  firstName: 'Nimal',
  lastName: 'User',
  phone: '+91 9847012345',
);

/// A signed-in, mock-backed app around [routes], with in-memory
/// SharedPreferences so storage-backed providers work.
Future<Widget> testApp({
  required String initialLocation,
  required List<RouteBase> routes,
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(initialLocation: initialLocation, routes: routes);
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUserProvider.overrideWithValue(testUser),
      currentUserIdProvider.overrideWithValue(testUser.id),
      ...overrides,
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

GoRoute stubRoute(String path, String text) => GoRoute(
      path: path,
      builder: (_, _) => Scaffold(body: Text(text)),
    );

/// GPS stand-in: resolves instantly to a fixed Kannur address.
class FakeLocationService implements LocationService {
  final ResolvedLocation result;

  FakeLocationService({
    this.result = const ResolvedLocation(
      latitude: 11.8745,
      longitude: 75.3704,
      label: 'Kannur, Kerala',
      addressLine: 'Fort Road, Kannur, Kannur, 670001',
    ),
  });

  @override
  Future<ResolvedLocation> locate() async => result;
}

/// GPS stand-in that fails with a given code.
class FailingLocationService implements LocationService {
  final String code;

  FailingLocationService(this.code);

  @override
  Future<ResolvedLocation> locate() async =>
      throw LocationFailure('nope', code: code);
}
