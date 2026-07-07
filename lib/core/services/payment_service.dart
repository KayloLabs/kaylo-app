abstract class PaymentService {
  Future<bool> initializePayment({
    required String amount,
    required String orderId,
    required String currency,
  });
  
  Future<bool> processPayment();
}

// M4 will implement this with Razorpay later.
class PaymentServiceStub implements PaymentService {
  @override
  Future<bool> initializePayment({
    required String amount,
    required String orderId,
    required String currency,
  }) async {
    // Stub implementation
    return true;
  }

  @override
  Future<bool> processPayment() async {
    // Stub implementation
    return true;
  }
}
