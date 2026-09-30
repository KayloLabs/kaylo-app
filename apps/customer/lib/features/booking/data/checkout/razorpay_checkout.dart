/// Razorpay's checkout sheet, one implementation per platform: the
/// razorpay_flutter plugin on Android and iOS, checkout.js on the web.
library;

export 'razorpay_checkout_stub.dart'
    if (dart.library.js_interop) 'razorpay_checkout_web.dart'
    if (dart.library.io) 'razorpay_checkout_mobile.dart';

/// What create-order returned: everything the sheet needs to open.
class CheckoutRequest {
  final String keyId;
  final String orderId;
  final int amountPaise;
  final String currency;
  final String name;
  final String description;
  final String prefillName;
  final String prefillContact;
  final String prefillEmail;

  /// 'upi' or 'card' to open the sheet on that method; null for
  /// Razorpay's default order.
  final String? preferredMethod;

  const CheckoutRequest({
    required this.keyId,
    required this.orderId,
    required this.amountPaise,
    required this.currency,
    required this.name,
    required this.description,
    this.prefillName = '',
    this.prefillContact = '',
    this.prefillEmail = '',
    this.preferredMethod,
  });

  /// Razorpay's `config.display` block that lists the preferred method
  /// first and keeps every other method below it.
  Map<String, dynamic>? get displayConfig {
    final method = preferredMethod;
    if (method == null) return null;
    return {
      'display': {
        'blocks': {
          'preferred': {
            'name': method == 'upi' ? 'Pay with UPI' : 'Pay by card',
            'instruments': [
              {'method': method},
            ],
          },
        },
        'sequence': ['block.preferred'],
        'preferences': {'show_default_blocks': true},
      },
    };
  }

  factory CheckoutRequest.fromJson(
    Map<String, dynamic> json, {
    String? preferredMethod,
  }) {
    final prefill = (json['prefill'] as Map?)?.cast<String, dynamic>() ?? {};
    return CheckoutRequest(
      keyId: json['key_id'] as String,
      orderId: json['order_id'] as String,
      amountPaise: (json['amount'] as num).toInt(),
      currency: json['currency'] as String? ?? 'INR',
      name: json['name'] as String? ?? 'Kaylo',
      description: json['description'] as String? ?? '',
      prefillName: prefill['name'] as String? ?? '',
      prefillContact: prefill['contact'] as String? ?? '',
      prefillEmail: prefill['email'] as String? ?? '',
      preferredMethod: preferredMethod,
    );
  }
}

sealed class CheckoutResult {
  const CheckoutResult();
}

class CheckoutSuccess extends CheckoutResult {
  final String paymentId;
  final String orderId;
  final String signature;

  const CheckoutSuccess({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });
}

class CheckoutFailed extends CheckoutResult {
  final String message;

  const CheckoutFailed(this.message);
}

class CheckoutCancelled extends CheckoutResult {
  const CheckoutCancelled();
}

abstract class RazorpayCheckout {
  /// Opens the sheet and completes when it closes, however it closed.
  Future<CheckoutResult> open(CheckoutRequest request);
}
