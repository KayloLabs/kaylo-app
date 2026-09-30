import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'razorpay_checkout.dart';

RazorpayCheckout createRazorpayCheckout() => _WebCheckout();

Future<void>? _loading;

/// Razorpay's checkout.js, loaded once on first use.
Future<void> _ensureScript() => _loading ??= () async {
  if (web.window.hasProperty('Razorpay'.toJS).toDart) return;
  final loaded = Completer<void>();
  final script = web.HTMLScriptElement()
    ..src = 'https://checkout.razorpay.com/v1/checkout.js'
    ..async = true;
  script.addEventListener(
    'load',
    ((web.Event _) {
      if (!loaded.isCompleted) loaded.complete();
    }).toJS,
  );
  script.addEventListener(
    'error',
    ((web.Event _) {
      if (!loaded.isCompleted) {
        loaded.completeError(StateError('Razorpay checkout failed to load'));
      }
    }).toJS,
  );
  web.document.head!.appendChild(script);
  await loaded.future;
}();

class _WebCheckout implements RazorpayCheckout {
  @override
  Future<CheckoutResult> open(CheckoutRequest request) async {
    await _ensureScript();
    final done = Completer<CheckoutResult>();
    void finish(CheckoutResult result) {
      if (!done.isCompleted) done.complete(result);
    }

    final options = <String, Object?>{
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
      if (request.displayConfig != null) 'config': request.displayConfig,
    }.jsify() as JSObject;

    options.setProperty(
      'handler'.toJS,
      ((JSObject response) {
        String read(String key) =>
            (response.getProperty<JSString?>(key.toJS))?.toDart ?? '';
        finish(
          CheckoutSuccess(
            paymentId: read('razorpay_payment_id'),
            orderId: read('razorpay_order_id'),
            signature: read('razorpay_signature'),
          ),
        );
      }).toJS,
    );
    final modal = JSObject();
    modal.setProperty(
      'ondismiss'.toJS,
      (() => finish(const CheckoutCancelled())).toJS,
    );
    options.setProperty('modal'.toJS, modal);

    final constructor = web.window.getProperty<JSFunction>('Razorpay'.toJS);
    final razorpay = constructor.callAsConstructor<JSObject>(options);
    razorpay.callMethod(
      'on'.toJS,
      'payment.failed'.toJS,
      ((JSObject event) {
        final error = event.getProperty<JSObject?>('error'.toJS);
        final description = error
            ?.getProperty<JSString?>('description'.toJS)
            ?.toDart;
        finish(CheckoutFailed(description ?? 'The payment did not go through'));
      }).toJS,
    );
    razorpay.callMethod('open'.toJS);
    return done.future;
  }
}
