import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'razorpay_checkout.dart';

RazorpayCheckout createRazorpayCheckout() => _MobileCheckout();

/// The razorpay_flutter plugin: its native sheet on Android and iOS.
class _MobileCheckout implements RazorpayCheckout {
  @override
  Future<CheckoutResult> open(CheckoutRequest request) {
    final razorpay = Razorpay();
    final done = Completer<CheckoutResult>();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      final paymentId = r.paymentId, orderId = r.orderId, signature = r.signature;
      if (paymentId == null || orderId == null || signature == null) {
        _finish(done, const CheckoutFailed('Razorpay returned no payment id'));
        return;
      }
      _finish(
        done,
        CheckoutSuccess(paymentId: paymentId, orderId: orderId, signature: signature),
      );
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      _finish(
        done,
        r.code == Razorpay.PAYMENT_CANCELLED
            ? const CheckoutCancelled()
            : CheckoutFailed(r.message ?? 'The payment did not go through'),
      );
    });
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
      _finish(
        done,
        CheckoutFailed('${r.walletName ?? 'That wallet'} is not supported yet'),
      );
    });

    razorpay.open({
      'key': request.keyId,
      'order_id': request.orderId,
      'amount': request.amountPaise,
      'currency': request.currency,
      'name': request.name,
      'description': request.description,
      'prefill': {
        'name': request.prefillName,
        'contact': request.prefillContact,
        'email': request.prefillEmail,
      },
      'theme': {'color': '#2F7A4F'},
      'retry': {'enabled': true, 'max_count': 2},
      if (request.displayConfig != null) 'config': request.displayConfig,
    });
    return done.future.whenComplete(razorpay.clear);
  }

  void _finish(Completer<CheckoutResult> done, CheckoutResult result) {
    if (!done.isCompleted) done.complete(result);
  }
}
