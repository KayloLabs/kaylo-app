import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/models/app_user.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/auth/application/current_user_provider.dart';
import 'package:kaylo/features/care/presentation/screens/care_home_screen.dart';
import 'package:kaylo/features/care/application/sos_phone_calls.dart';
import 'package:kaylo/features/care/domain/care_models.dart';
import 'package:kaylo/features/care/data/mock_care_repository.dart';
import 'package:kaylo/features/care/application/care_providers.dart';
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

class FakeSosPhoneCalls implements SosPhoneCalls {
  final events = StreamController<SosCallState>.broadcast();
  int starts = 0;
  List<EmergencyContact> contacts = [];
  @override
  bool get supported => true;
  @override
  Stream<SosCallState> get updates => events.stream;
  @override
  Future<SosCallState> start(List<EmergencyContact> value) async {
    starts++;
    contacts = value;
    return SosCallState(
      status: 'calling',
      attempted: 1,
      total: value.length,
      name: 'Arjun Nair',
    );
  }

  @override
  Future<SosCallState> stop() async => SosCallState(
    status: 'stopped',
    attempted: starts > 0 ? 1 : 0,
    total: contacts.length,
  );
}

Widget app({required String initialLocation, FakeSosPhoneCalls? calls}) {
  final phoneCalls = calls ?? FakeSosPhoneCalls();
  addTearDown(phoneCalls.events.close);
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
      sosPhoneCallsProvider.overrideWithValue(phoneCalls),
      careRepositoryProvider.overrideWithValue(
        MockCareRepository(
          emergencyContacts: const [
            EmergencyContact(
              id: 'c1',
              name: 'Arjun Nair',
              relation: 'Son',
              phone: '0000000001',
              isPrimary: true,
            ),
            EmergencyContact(
              id: 'c2',
              name: 'Dr. Priya Mathew',
              relation: 'Doctor',
              phone: '0000000002',
            ),
            EmergencyContact(
              id: 'c3',
              name: 'Sneha Nair',
              relation: 'Daughter',
              phone: '0000000003',
            ),
            EmergencyContact(
              id: 'c4',
              name: 'Other contact',
              relation: 'Family',
              phone: '0000000004',
            ),
          ],
          sosHistory: [
            SosAlert(
              id: 'sos-1',
              triggeredAt: DateTime.now().subtract(const Duration(days: 3)),
              status: SosStatus.resolved,
              notifiedContacts: 4,
              primaryContactName: 'Arjun Nair',
            ),
          ],
        ),
      ),
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
  testWidgets(
    'selected phone contact is reviewed before saving; cancellation keeps input',
    (tester) async {
      useTallPhone(tester);
      const channel = MethodChannel('kaylo/phone_contacts');
      var picks = 0;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'pick');
        picks++;
        return picks == 1
            ? {'name': 'Selected contact', 'phone': '+91 98765 43210'}
            : null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await tester.pumpWidget(app(initialLocation: Routes.careSos));
      await settle(tester);
      await tester.ensureVisible(find.text('Add contact'));
      await tester.tap(find.text('Add contact'));
      await settle(tester);
      await tester.tap(find.text('Choose from phone contacts'));
      await settle(tester);
      final fields = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .toList();
      expect(fields[0].controller!.text, 'Selected contact');
      expect(fields[2].controller!.text, '+91 98765 43210');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(EmergencySosScreen)),
      );
      final repo = container.read(careRepositoryProvider);
      var contacts = await tester.runAsync(() => repo.getContacts(_user.id));
      expect(contacts!.any((c) => c.name == 'Selected contact'), isFalse);
      await tester.tap(find.text('Choose from phone contacts'));
      await settle(tester);
      expect(fields[0].controller!.text, 'Selected contact');
      await tester.tap(find.text('Save'));
      await settle(tester);
      contacts = await tester.runAsync(() => repo.getContacts(_user.id));
      expect(
        contacts!.singleWhere((c) => c.name == 'Selected contact').phone,
        '+91 98765 43210',
      );
      expect(picks, 2);
    },
  );

  test('sample builds never preload contacts for real SOS calls', () async {
    final repo = MockCareRepository();
    expect(await repo.getContacts('demo'), isEmpty);
    expect(await repo.getSosHistory('demo'), isEmpty);
  });

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

  testWidgets('SOS starts SIM calls without claiming contacts were notified', (
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

    expect(find.text('Help is on the way'), findsNothing);
    expect(find.text('1 of 4 calls attempted'), findsOneWidget);
    expect(find.text('Calling Arjun Nair'), findsOneWidget);

    await tester.tap(find.text('Stop remaining calls'));
    await settle(tester);
    expect(find.text('1 alert sent'), findsOneWidget);
    expect(
      find.text(
        'Remaining calls stopped. An ongoing call can be ended in your phone app.',
      ),
      findsOneWidget,
    );
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
      find.text('Keep holding for 3 seconds to start calling'),
      findsOneWidget,
    );
  });

  testWidgets('each SOS hold requires three uninterrupted seconds', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(app(initialLocation: Routes.careSos));
    await settle(tester);
    final button = find.text('Press and hold');
    final first = await tester.startGesture(tester.getCenter(button));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Help is on the way'), findsNothing);
    await first.up();
    await tester.pump();
    final second = await tester.startGesture(tester.getCenter(button));
    for (var i = 0; i < 22; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Help is on the way'), findsNothing);
    await second.up();
    await settle(tester);
    expect(find.text('1 alert sent'), findsOneWidget);
  });

  testWidgets('switching away from Kaylo cancels a partially completed hold', (
    tester,
  ) async {
    useTallPhone(tester);
    final calls = FakeSosPhoneCalls();
    await tester.pumpWidget(app(initialLocation: Routes.careSos, calls: calls));
    await settle(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Press and hold')),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    for (var i = 0; i < 22; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await settle(tester);
    expect(calls.starts, 0);
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
