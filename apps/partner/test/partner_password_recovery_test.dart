import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_partner/core/router/app_router.dart';
import 'package:kaylo_partner/core/router/routes.dart';
import 'package:kaylo_partner/features/auth/data/firebase_partner_auth_repository.dart';
import 'package:kaylo_partner/features/auth/data/partner_password_recovery.dart';
import 'package:kaylo_partner/features/auth/domain/partner_auth_repository.dart';
import 'package:kaylo_partner/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:kaylo_partner/l10n/generated/app_localizations.dart';
import 'package:kaylo_ui/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> showRecovery(WidgetTester tester, SendPartnerReset send) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sendPartnerResetProvider.overrideWithValue(send)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PartnerForgotPasswordScreen(initialPartnerId: 'KP-000123'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('recovery route is available without authentication', () {
    expect(
      partnerRedirect(
        const PartnerAccess(PartnerAccessStatus.signedOut),
        Routes.forgotPassword,
      ),
      isNull,
    );
  });
  testWidgets('validates real email before requesting recovery', (
    tester,
  ) async {
    var sends = 0;
    await showRecovery(tester, (_, _) async {
      sends++;
    });
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your registered email address.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('reset-email')),
      'kp-000123@partners.kaylo.app',
    );
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(sends, 0);
  });
  testWidgets(
    'sends normalized details once and shows inbox state and resend cooldown',
    (tester) async {
      final pending = Completer<void>();
      var sends = 0;
      await showRecovery(tester, (id, email) async {
        expect(id, 'KP-000123');
        expect(email, 'worker@example.com');
        sends++;
        await pending.future;
      });
      await tester.enterText(
        find.byKey(const Key('reset-email')),
        ' Worker@Example.com ',
      );
      await tester.tap(find.text('Send reset link'));
      await tester.pump();
      expect(sends, 1);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Check your inbox'), findsOneWidget);
      expect(find.text('Send again in 60s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 60));
      expect(find.text('Send another link'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('failed email delivery does not show success and allows retry', (
    tester,
  ) async {
    await showRecovery(tester, (_, _) async {
      throw const PartnerAuthException(PartnerAuthError.unavailable);
    });
    await tester.enterText(
      find.byKey(const Key('reset-email')),
      'worker@example.com',
    );
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(find.text('Check your inbox'), findsNothing);
    expect(find.text('Send reset link'), findsOneWidget);
  });
  testWidgets('mock mode does not pretend to send an email', (tester) async {
    await showRecovery(tester, (_, _) async {
      throw const PartnerResetDemoException();
    });
    await tester.enterText(
      find.byKey(const Key('reset-email')),
      'worker@example.com',
    );
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo mode does not send'), findsOneWidget);
    expect(find.text('Check your inbox'), findsNothing);
  });
  test('server-confirmed external reset reloads the access gate', () async {
    final result = await reconcileRecoveredPassword(
      {'must_change_password': true},
      confirmChange: () async {},
      reload: () async => {'must_change_password': false},
    );
    expect(result?['must_change_password'], false);
  });
  test(
    'temporary password keeps the gate; server failures never unlock it',
    () async {
      final state = {'must_change_password': true};
      final result = await reconcileRecoveredPassword(
        state,
        confirmChange: () async {
          throw const FunctionException(status: 409);
        },
        reload: () async => throw StateError('must not reload'),
      );
      expect(result, same(state));
      await expectLater(
        reconcileRecoveredPassword(
          state,
          confirmChange: () async {
            throw const FunctionException(status: 503);
          },
          reload: () async => {'must_change_password': false},
        ),
        throwsA(isA<FunctionException>()),
      );
    },
  );
  test(
    'already cleared or unissued account never attempts password confirmation',
    () async {
      for (final state in [
        null,
        {'must_change_password': false},
      ]) {
        expect(
          await reconcileRecoveredPassword(
            state,
            confirmChange: () async => throw StateError('must not confirm'),
            reload: () async => throw StateError('must not reload'),
          ),
          same(state),
        );
      }
    },
  );
}
