import 'payment_method.dart';

abstract class PaymentMethodsRepository {
  Future<List<SavedPaymentMethod>> getPaymentMethods();
  Stream<List<SavedPaymentMethod>> watchPaymentMethods();
  Future<SavedPaymentMethod> addPaymentMethod({
    required PaymentMethodType type,
    required String label,
    required String detail,
    bool isDefault = false,
  });
  Future<void> removePaymentMethod(String id);
  Future<void> setDefaultPaymentMethod(String id);
}
