import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

Future<void>? _loading;

/// Injects the Maps JavaScript API script once, keyed from the build
/// (`--dart-define=GOOGLE_MAPS_API_KEY`), and completes when the API is
/// callable. google_maps_flutter_web only needs `google.maps` to exist
/// by the time a map widget is created.
Future<void> ensureGoogleMapsLoaded(String apiKey) =>
    _loading ??= _load(apiKey);

Future<void> _load(String apiKey) {
  if (_mapsPresent) return Future<void>.value();

  final completer = Completer<void>();
  const callback = '__kayloMapsReady';
  web.window.setProperty(
    callback.toJS,
    (() {
      if (!completer.isCompleted) completer.complete();
    }).toJS,
  );

  final script = web.HTMLScriptElement()
    ..src =
        'https://maps.googleapis.com/maps/api/js'
        '?key=${Uri.encodeQueryComponent(apiKey)}&callback=$callback'
    ..async = true;
  script.addEventListener(
    'error',
    ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('The Google Maps script failed to load'),
        );
      }
    }).toJS,
  );
  web.document.head!.appendChild(script);
  return completer.future;
}

/// True when index.html (or an earlier load) already provided the API.
bool get _mapsPresent {
  final google = web.window.getProperty<JSAny?>('google'.toJS);
  if (google == null || google.isUndefinedOrNull) return false;
  final maps = (google as JSObject).getProperty<JSAny?>('maps'.toJS);
  return maps != null && !maps.isUndefinedOrNull;
}
