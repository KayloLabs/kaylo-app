import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/models/app_user.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/auth/application/current_user_provider.dart';
import 'package:kaylo/features/care/presentation/screens/care_home_screen.dart';
import 'package:kaylo/features/care/presentation/screens/emergency_sos_screen.dart';
import 'package:kaylo/features/care/presentation/screens/medicine_reminders_screen.dart';
import 'package:kaylo/features/care/presentation/screens/sos_history_screen.dart';
import 'package:kaylo/l10n/generated/app_localizations.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
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

final _user = AppUser(
  id: 'mock_uid_1',
  firstName: 'Nimal',
  lastName: 'User',
  phone: '+91 9847012345',
);

Widget app({required String initialLocation}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: Routes.careHome,
        builder: (_, _) => const CareHomeScreen(),
        routes: [
          GoRoute(
            path: 'medicines',
            builder: (_, _) => const MedicineRemindersScreen(),
          ),
          GoRoute(
            path: 'sos',
            builder: (_, _) => const EmergencySosScreen(),
            routes: [
              GoRoute(
                path: 'history',
                builder: (_, _) => const SosHistoryScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(_user),
      currentUserIdProvider.overrideWithValue(_user.id),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('hub shows pending doses and marking one taken updates it', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(app(initialLocation: Routes.careHome));
    await settle(tester);

    expect(find.text('2 doses pending'), findsOneWidget);

    await tester.tap(find.text('Medicine Reminders'));
    await settle(tester);

    expect(find.text("Today's medicines"), findsOneWidget);
    expect(find.text('Vitamin D3 and calcium'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.radio_button_unchecked_rounded).first);
    await settle(tester);

    expect(find.text('1 dose pending'), findsOneWidget);
  });

  testWidgets('adding a reminder lists it', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(app(initialLocation: Routes.careMedicines));
    await settle(tester);

    await tester.tap(find.text('Add reminder'));
    await settle(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Sugar tablet');
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(find.text('Sugar tablet'), findsOneWidget);
  });

  testWidgets('SOS lists contacts, and holding the button sends an alert', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(app(initialLocation: Routes.careSos));
    await settle(tester);

    expect(find.text('Arjun Nair'), findsOneWidget);
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('1 alert sent'), findsOneWidget);

    // The guard ring is ticker-driven, so the hold must be pumped frame
    // by frame rather than skipped in one jump.
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Press and hold')),
    );
    for (var i = 0; i < 34; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await settle(tester);

    expect(find.text('Help is on the way'), findsOneWidget);
    expect(find.text('4 contacts alerted with your location'), findsOneWidget);
    expect(find.text('Calling Arjun Nair'), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await settle(tester);
    expect(find.text('2 alerts sent'), findsOneWidget);
  });

  testWidgets('releasing the SOS button early does not send', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(app(initialLocation: Routes.careSos));
    await settle(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Press and hold')),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await settle(tester);

    expect(find.text('Help is on the way'), findsNothing);
    expect(
      find.text('Keep holding for 3 seconds to send an alert'),
      findsOneWidget,
    );
  });

  testWidgets('SOS history lists past alerts', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(app(initialLocation: Routes.careSosHistory));
    await settle(tester);

    expect(find.text('Resolved'), findsOneWidget);
    expect(find.text('4 contacts notified'), findsOneWidget);
    expect(find.text('Primary contact: Arjun Nair'), findsOneWidget);
  });
}
