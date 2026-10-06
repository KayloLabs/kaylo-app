import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/features/payments/application/payment_methods_providers.dart';
import 'package:kaylo/features/payments/data/mock_payment_methods_repository.dart';
import 'package:kaylo/features/payments/domain/payment_method.dart';
import 'package:kaylo/features/payments/presentation/screens/payment_methods_screen.dart';
import 'package:kaylo/l10n/generated/app_localizations.dart';
import 'package:kaylo_ui/theme/app_theme.dart';

void main() {
  group('MockPaymentMethodsRepository Tests', () {
    test('seeds with default UPI and Card', () async {
      final repo = MockPaymentMethodsRepository();
      final methods = await repo.getPaymentMethods();

      expect(methods.length, 2);
      expect(methods[0].type, PaymentMethodType.upi);
      expect(methods[0].isDefault, isTrue);
      expect(methods[1].type, PaymentMethodType.card);
      expect(methods[1].isDefault, isFalse);
    });

    test('addPaymentMethod adds a new method and updates stream', () async {
      final repo = MockPaymentMethodsRepository();
      final newMethod = await repo.addPaymentMethod(
        type: PaymentMethodType.upi,
        label: 'PhonePe UPI',
        detail: 'user@ybl',
      );

      final methods = await repo.getPaymentMethods();
      expect(methods.length, 3);
      expect(methods.any((m) => m.id == newMethod.id), isTrue);
    });

    test('setDefaultPaymentMethod switches default flag', () async {
      final repo = MockPaymentMethodsRepository();
      final methods = await repo.getPaymentMethods();
      final cardId = methods[1].id;

      await repo.setDefaultPaymentMethod(cardId);
      final updated = await repo.getPaymentMethods();

      expect(updated.firstWhere((m) => m.id == cardId).isDefault, isTrue);
      expect(updated.firstWhere((m) => m.id != cardId).isDefault, isFalse);
    });

    test('removePaymentMethod deletes item and falls back to remaining default',
        () async {
      final repo = MockPaymentMethodsRepository();
      final initial = await repo.getPaymentMethods();
      final defaultId = initial.firstWhere((m) => m.isDefault).id;

      await repo.removePaymentMethod(defaultId);
      final updated = await repo.getPaymentMethods();

      expect(updated.length, 1);
      expect(updated.first.isDefault, isTrue);
    });
  });

  group('PaymentMethodsScreen Widget Tests', () {
    testWidgets('renders seeded payment methods and Add button',
        (tester) async {
      final repo = MockPaymentMethodsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paymentMethodsRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PaymentMethodsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Payment Methods'), findsOneWidget);
      expect(find.text('Google Pay UPI'), findsOneWidget);
      expect(find.text('anjali@okhdfcbank'), findsOneWidget);
      expect(find.text('HDFC Bank Debit Card'), findsOneWidget);
      expect(find.text('Add payment method'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
    });
  });
}
