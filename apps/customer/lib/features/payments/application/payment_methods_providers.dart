import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/services/storage_service.dart';

import '../data/mock_payment_methods_repository.dart';
import '../domain/payment_method.dart';
import '../domain/payment_methods_repository.dart';

final paymentMethodsRepositoryProvider =
    Provider<PaymentMethodsRepository>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return MockPaymentMethodsRepository(prefs);
  } catch (_) {
    return MockPaymentMethodsRepository();
  }
});

final paymentMethodsStreamProvider =
    StreamProvider<List<SavedPaymentMethod>>((ref) {
  final repo = ref.watch(paymentMethodsRepositoryProvider);
  return repo.watchPaymentMethods();
});

final defaultPaymentMethodProvider = Provider<SavedPaymentMethod?>((ref) {
  final methods =
      ref.watch(paymentMethodsStreamProvider).asData?.value ?? [];
  try {
    return methods.firstWhere((m) => m.isDefault);
  } catch (_) {
    return methods.firstOrNull;
  }
});
