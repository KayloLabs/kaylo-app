import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/widgets/kaylo_bottom_nav.dart';
import 'package:kaylo/features/auth/application/current_user_provider.dart';
import 'package:kaylo/features/care/application/care_calls.dart';
import 'package:kaylo/features/care/presentation/screens/prescriptions_screen.dart';
import 'package:kaylo/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('hold and slide selects a tab only after release', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => KayloBottomNav(navigationShell: shell),
          branches: [
            for (var i = 0; i < 5; i++)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: i == 0 ? '/' : '/tab$i',
                    builder: (_, _) => Center(child: Text('Page $i')),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [incomingCareCallsProvider.overrideWith((ref) async => [])],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.home)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(find.byIcon(Icons.person_outline)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Page 0'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Page 4'), findsOneWidget);
    final cancelled = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.person)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await cancelled.moveTo(tester.getCenter(find.byIcon(Icons.home_outlined)));
    await cancelled.cancel();
    await tester.pumpAndSettle();
    expect(find.text('Page 4'), findsOneWidget);
  });

  testWidgets(
    'typed prescription requires text and saves to the signed-in account',
    (tester) async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(prescriptionChannel, (call) async {
            calls.add(call);
            if (call.method == 'list') return [];
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(prescriptionChannel, null),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentUserIdProvider.overrideWithValue('test-owner')],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PrescriptionsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Type record'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save prescription'));
      await tester.tap(find.text('Save prescription'));
      await tester.pumpAndSettle();
      expect(calls.where((c) => c.method == 'save'), isEmpty);
      await tester.enterText(
        find.byType(TextField).at(1),
        'Previous prescription record',
      );
      await tester.ensureVisible(find.text('Save prescription'));
      await tester.tap(find.text('Save prescription'));
      await tester.pumpAndSettle();
      final save = calls.singleWhere((c) => c.method == 'save');
      expect(save.arguments['userId'], 'test-owner');
      expect(save.arguments['text'], 'Previous prescription record');
      expect(save.arguments['scanned'], false);
    },
  );
}
