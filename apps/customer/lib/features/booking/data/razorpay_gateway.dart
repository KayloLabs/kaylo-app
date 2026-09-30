import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/payment_gateway.dart';
import 'checkout/razorpay_checkout.dart';

/// Razorpay, verified by our server: create-order gives the sheet its
/// order, the sheet collects the payment, verify-payment checks the
/// signature and marks the booking paid. The key secret never leaves
/// the server.
class RazorpayGateway implements PaymentGateway {
  final SupabaseClient _client;
  final RazorpayCheckout _checkout;

  RazorpayGateway(this._client, this._checkout);

  @override
  Future<PaymentOutcome> pay({
    required String bookingId,
    String? email,
    String? preferredMethod,
  }) async {
    final Map<String, dynamic> order;
    try {
      order = await _call('create-order', {
        'booking_id': bookingId,
        if (email != null && email.isNotEmpty) 'email': email,
      });
    } on _FunctionError catch (e) {
      return PaymentOutcome.notPaid(e.message);
    }

    final result = await _checkout.open(
      CheckoutRequest.fromJson(order, preferredMethod: preferredMethod),
    );
    switch (result) {
      case CheckoutCancelled():
        return const PaymentOutcome.notPaid('The payment was cancelled');
      case CheckoutFailed(:final message):
        return PaymentOutcome.notPaid(message);
      case CheckoutSuccess(:final paymentId, :final orderId, :final signature):
        try {
          final verified = await _call('verify-payment', {
            'razorpay_order_id': orderId,
            'razorpay_payment_id': paymentId,
            'razorpay_signature': signature,
          });
          return PaymentOutcome.paid(
            invoiceNumber: verified['invoice_number'] as String?,
            invoiceSent: verified['invoice_sent'] == true,
          );
        } on _FunctionError catch (e) {
          return PaymentOutcome.notPaid(e.message);
        }
    }
  }

  Future<Map<String, dynamic>> _call(
    String function,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _client.functions.invoke(function, body: body);
      return (res.data as Map).cast<String, dynamic>();
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['error'] is Map) {
        final message = (details['error'] as Map)['message'];
        if (message is String && message.isNotEmpty) throw _FunctionError(message);
      }
      throw _FunctionError('Could not reach the payment service (${e.status})');
    } catch (e) {
      throw _FunctionError('Could not reach the payment service');
    }
  }
}

class _FunctionError implements Exception {
  final String message;

  _FunctionError(this.message);
}
