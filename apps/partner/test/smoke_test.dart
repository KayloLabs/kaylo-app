import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_partner/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('partner app boots with the shared theme and a home screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'kaylo_partner_issued_session': 'KP-000123',
      'kaylo_partner_password_changed': true,
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const KayloPartnerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kaylo Partner'), findsOneWidget);
    expect(find.text('New Requests (2)'), findsOneWidget);
  });
}
