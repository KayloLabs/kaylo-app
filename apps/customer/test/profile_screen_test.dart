import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/auth/application/session_controller.dart';
import 'package:kaylo/features/auth/data/mock_auth_repository.dart';
import 'package:kaylo/features/auth/domain/auth_repository.dart';
import 'package:kaylo/features/booking/presentation/screens/bookings_screen.dart';
import 'package:kaylo/features/profile/presentation/screens/profile_screen.dart';
import 'package:kaylo/features/profile/presentation/screens/settings_screen.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_app.dart';

/// The profile and settings screens read the session, so these tests
/// sign in through the mock repository with a persisted demo session.
/// The repository is built lazily, inside the session controller, so its
/// first emission is not lost before anyone listens.
Future<Widget> _signedInApp(
  String initialLocation, {
  void Function(BuildContext)? onBuild,
}) async {
  final app = await testApp(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: Routes.profile,
        builder: (context, _) {
          onBuild?.call(context);
          return const ProfileScreen();
        },
        routes: [
          GoRoute(
            path: Routes.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.bookings,
        builder: (_, state) => BookingsScreen(
          completedOnly: state.uri.queryParameters['status'] == 'completed',
        ),
      ),
      stubRoute(Routes.addresses, 'saved-addresses-screen'),
    ],
    overrides: [
      authRepositoryProvider.overrideWith(
        (ref) => MockAuthRepository(ref.read(storageServiceProvider)),
      ),
    ],
  );
  // The harness's in-memory prefs; a stored token is what the mock
  // repository treats as a session to restore.
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', 'mock_token');
  return app;
}

void main() {
  testWidgets('profile shows the session user and real counts', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await _signedInApp(Routes.profile));
    await settle(tester);

    expect(find.text('Nimal User'), findsOneWidget);
    expect(find.text('+91 9847012345'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('4.9'), findsNothing, reason: 'no invented rating');
    // Mock data: 5 bookings (two of them Care), 2 completed, 1 address.
    expect(find.text('5'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('editing the name updates the profile header', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await _signedInApp(Routes.profile));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.edit_rounded));
    await settle(tester);
    expect(find.text('Edit profile'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Anjali');
    await tester.enterText(find.byType(TextFormField).last, 'Menon');
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(find.text('Profile updated'), findsOneWidget);
    expect(find.text('Anjali Menon'), findsOneWidget);
    expect(find.text('Nimal User'), findsNothing);
  });

  testWidgets('Bookings statistic opens all bookings', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await _signedInApp(Routes.profile));
    await settle(tester);

    await tester.tap(find.text('Bookings'));
    await settle(tester);
    expect(find.text('b1'), findsOneWidget);
    expect(find.text('b2'), findsOneWidget);
    expect(find.text('b3'), findsOneWidget);
  });

  testWidgets('Completed statistic excludes upcoming and other statuses', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(await _signedInApp(Routes.profile));
    await settle(tester);

    await tester.tap(find.text('Completed'));
    await settle(tester);
    expect(find.text('b1'), findsOneWidget);
    expect(find.text('b2'), findsOneWidget);
    expect(find.text('b3'), findsNothing);
    expect(find.text('Upcoming'), findsNothing);

    await tester.tap(find.text('All bookings'));
    await settle(tester);
    expect(find.text('b3'), findsOneWidget);
  });

  testWidgets('Saved statistic opens the addresses it counts', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await _signedInApp(Routes.profile));
    await settle(tester);

    await tester.tap(find.text('Saved'));
    await settle(tester);
    expect(find.text('saved-addresses-screen'), findsOneWidget);
  });

  testWidgets('settings shows the account and opens the editor', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await _signedInApp('${Routes.profile}/${Routes.settings}'),
    );
    await settle(tester);

    expect(find.text('Nimal User'), findsOneWidget);
    await tester.tap(find.text('Nimal User'));
    await settle(tester);
    expect(find.text('Edit profile'), findsOneWidget);
  });

  testWidgets('a rename is what the next launch shows', (tester) async {
    useTallPhone(tester);
    late ProviderContainer container;
    await tester.pumpWidget(
      await _signedInApp(
        Routes.profile,
        onBuild: (context) => container = ProviderScope.containerOf(context),
      ),
    );
    await settle(tester);

    // The mock answers after a delay, so pump instead of awaiting.
    unawaited(
      container
          .read(sessionControllerProvider.notifier)
          .updateProfile(firstName: 'Reloaded', lastName: 'Name'),
    );
    await settle(tester);
    expect(find.text('Reloaded Name'), findsOneWidget);

    // A fresh repository on the same storage, as after an app restart.
    final prefs = await SharedPreferences.getInstance();
    final again = MockAuthRepository(SharedPreferencesStorageService(prefs));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    expect(again.currentUser?.fullName, 'Reloaded Name');
  });
}
