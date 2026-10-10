import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_partner/main.dart';
import 'package:kaylo_partner/core/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPartnerLocaleNotifier extends PartnerLocaleNotifier {
  @override
  Locale build() {
    return const Locale('ml');
  }
}

void main() {
  testWidgets('app language changes to Malayalam when locale is ml', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'kaylo_partner_issued_session': 'KP-000123',
      'kaylo_partner_password_changed': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          partnerLocaleProvider.overrideWith(() => MockPartnerLocaleNotifier()),
        ],
        child: const KayloPartnerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The Jobs tab should show the Malayalam label from the ARB file (jobsTabLabel)
    expect(find.text('ജോലികൾ'), findsOneWidget);
  });
}
