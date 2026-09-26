/// Loads the Google Maps JavaScript API on web with the key from the
/// build, so index.html never carries it. Native platforms bundle the
/// Maps SDK and this is a no-op there.
library;

export 'google_maps_loader_stub.dart'
    if (dart.library.js_interop) 'google_maps_loader_web.dart';
