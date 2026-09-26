import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as geo;

import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';
import '../maps/google_maps_loader.dart';

export 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

/// Kerala, centred, for a map that has nothing to show yet.
const LatLng keralaCenter = LatLng(10.55, 76.30);

/// Kannur town: where the seeded workers are and where the app starts
/// until the customer shares a location (UserLocation.fallback).
const LatLng kannurCenter = LatLng(11.8745, 75.3704);

/// Which engine draws the map. Google Maps when a key was built in
/// (GOOGLE_MAPS_API_KEY), otherwise OpenStreetMap tiles, which need no
/// key. `none` is for widget tests: a placeholder instead of tiles
/// fetched over the network or a platform view.
enum MapBackend { google, openStreetMap, none }

final mapBackendProvider = Provider<MapBackend>(
  (ref) => googleMapsConfigured ? MapBackend.google : MapBackend.openStreetMap,
);

/// A pin drawn on the map.
class KayloMapMarker {
  final LatLng position;

  const KayloMapMarker(this.position);
}

/// Moves the camera of the [KayloMap] it is attached to.
class KayloMapController {
  _KayloMapState? _state;

  Future<void> animateTo(LatLng target, {double? zoom}) =>
      _state?._animateTo(target, zoom) ?? Future<void>.value();
}

/// A map in Kaylo's look, on whichever engine [mapBackendProvider]
/// picks: no stock controls, POI clutter hidden, a night look in dark
/// mode. Camera callbacks behave the same on both engines, so the
/// picker never knows which one is drawing.
class KayloMap extends ConsumerStatefulWidget {
  final LatLng center;
  final double zoom;
  final List<KayloMapMarker> markers;

  /// Pan and zoom. Off for previews, which on Google also use Android's
  /// lite mode: a static map bitmap that is cheap and always crisp.
  final bool interactive;

  /// Animate to [center] and [zoom] when they change. On for a preview
  /// that follows a resolved location, off for a picker the customer
  /// pans themselves (those move the camera through [controller]).
  final bool followCenter;

  /// Keeps attribution and the Google logo clear of overlays.
  final EdgeInsets padding;

  final KayloMapController? controller;
  final VoidCallback? onCameraMoveStarted;
  final ValueChanged<LatLng>? onCameraMove;
  final VoidCallback? onCameraIdle;

  const KayloMap({
    super.key,
    required this.center,
    this.zoom = 14,
    this.markers = const [],
    this.interactive = true,
    this.followCenter = true,
    this.padding = EdgeInsets.zero,
    this.controller,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
  });

  @override
  ConsumerState<KayloMap> createState() => _KayloMapState();
}

class _KayloMapState extends ConsumerState<KayloMap>
    with SingleTickerProviderStateMixin {
  // Google engine
  GoogleMapController? _google;
  late final Future<void> _googleReady = googleMapsConfigured
      ? ensureGoogleMapsLoaded(googleMapsApiKey)
      : Future<void>.value();

  // OpenStreetMap engine. flutter_map moves instantly, so programmatic
  // moves are tweened here; and it reports positions, not gestures, so
  // "idle" is a short quiet period after the last position change.
  final _osm = osm.MapController();
  // Created on the first programmatic move, never in dispose: a ticker
  // cannot be created while the widget is being torn down.
  AnimationController? _osmAnimation;
  Timer? _osmIdle;
  bool _osmMoving = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(KayloMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
    if (widget.followCenter &&
        (widget.center != oldWidget.center || widget.zoom != oldWidget.zoom)) {
      _animateTo(widget.center, widget.zoom);
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _osmIdle?.cancel();
    _osmAnimation?.dispose();
    _osm.dispose();
    super.dispose();
  }

  Future<void> _animateTo(LatLng target, double? zoom) async {
    switch (ref.read(mapBackendProvider)) {
      case MapBackend.google:
        final controller = _google;
        if (controller == null) return;
        await controller.animateCamera(
          zoom == null
              ? CameraUpdate.newLatLng(target)
              : CameraUpdate.newLatLngZoom(target, zoom),
        );
      case MapBackend.openStreetMap:
        await _osmAnimateTo(target, zoom);
      case MapBackend.none:
        break;
    }
  }

  Future<void> _osmAnimateTo(LatLng target, double? zoom) async {
    final osm.MapCamera from;
    try {
      from = _osm.camera;
    } on Object {
      return; // Not laid out yet; the initial camera already applies.
    }
    final lat = Tween(begin: from.center.latitude, end: target.latitude);
    final lng = Tween(begin: from.center.longitude, end: target.longitude);
    final level = Tween(begin: from.zoom, end: zoom ?? from.zoom);
    final animation = _osmAnimation ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    void tick() {
      final t = Curves.easeOutCubic.transform(animation.value);
      _osm.move(
        geo.LatLng(lat.transform(t), lng.transform(t)),
        level.transform(t),
      );
    }

    animation.addListener(tick);
    try {
      await animation.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Disposed mid-move; nothing left to animate.
    } finally {
      animation.removeListener(tick);
    }
  }

  void _onOsmPositionChanged(osm.MapCamera camera, bool _) {
    widget.onCameraMove?.call(
      LatLng(camera.center.latitude, camera.center.longitude),
    );
    if (!_osmMoving) {
      _osmMoving = true;
      widget.onCameraMoveStarted?.call();
    }
    _osmIdle?.cancel();
    _osmIdle = Timer(const Duration(milliseconds: 180), () {
      _osmMoving = false;
      widget.onCameraIdle?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (ref.watch(mapBackendProvider)) {
      case MapBackend.none:
        return const MapUnavailable();
      case MapBackend.openStreetMap:
        return _osmMap(context);
      case MapBackend.google:
        // Native platforms have the SDK from the start; only web waits
        // for the script.
        if (!kIsWeb) return _googleMap(context);
        return FutureBuilder<void>(
          future: _googleReady,
          builder: (context, snapshot) {
            if (snapshot.hasError) return const MapUnavailable();
            if (snapshot.connectionState != ConnectionState.done) {
              return const _MapLoading();
            }
            return _googleMap(context);
          },
        );
    }
  }

  Widget _osmMap(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return osm.FlutterMap(
      mapController: _osm,
      options: osm.MapOptions(
        initialCenter: geo.LatLng(
          widget.center.latitude,
          widget.center.longitude,
        ),
        initialZoom: widget.zoom,
        minZoom: 3,
        maxZoom: 19,
        backgroundColor: isDark
            ? AppColors.surfaceTintDark
            : AppColors.surfaceAlt,
        interactionOptions: osm.InteractionOptions(
          flags: widget.interactive
              ? osm.InteractiveFlag.all & ~osm.InteractiveFlag.rotate
              : osm.InteractiveFlag.none,
        ),
        // Google settles once right after creation; mirror that so the
        // picker's first-idle handling holds on both engines.
        onMapReady: () => widget.onCameraIdle?.call(),
        onPositionChanged: _onOsmPositionChanged,
      ),
      children: [
        osm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.kaylo.app',
          maxNativeZoom: 19,
          tileBuilder: isDark ? osm.darkModeTileBuilder : null,
        ),
        if (widget.markers.isNotEmpty)
          osm.MarkerLayer(
            markers: [
              for (final marker in widget.markers)
                osm.Marker(
                  point: geo.LatLng(
                    marker.position.latitude,
                    marker.position.longitude,
                  ),
                  width: 44,
                  height: 44,
                  // The pin's tip, not its centre, sits on the point.
                  alignment: Alignment.topCenter,
                  child: const _OsmPin(),
                ),
            ],
          ),
        // OpenStreetMap's licence asks for this credit on every map.
        Padding(
          padding: widget.padding,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.s),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceDark : AppColors.surface)
                    .withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '© OpenStreetMap contributors',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _googleMap(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.center,
        zoom: widget.zoom,
      ),
      markers: {
        for (final (index, marker) in widget.markers.indexed)
          Marker(
            markerId: MarkerId('marker$index'),
            position: marker.position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
      },
      style: isDark ? _darkStyle : _lightStyle,
      padding: widget.padding,
      liteModeEnabled: !widget.interactive,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      tiltGesturesEnabled: false,
      rotateGesturesEnabled: widget.interactive,
      scrollGesturesEnabled: widget.interactive,
      zoomGesturesEnabled: widget.interactive,
      onMapCreated: (controller) => _google = controller,
      onCameraMoveStarted: widget.onCameraMoveStarted,
      onCameraMove: (position) => widget.onCameraMove?.call(position.target),
      onCameraIdle: widget.onCameraIdle,
    );
  }
}

class _OsmPin extends StatelessWidget {
  const _OsmPin();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.location_on_rounded,
      size: 44,
      color: AppColors.brandPrimary,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class _MapLoading extends StatelessWidget {
  const _MapLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? AppColors.surfaceTintDark : AppColors.surfaceAlt,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.brandPrimary,
          ),
        ),
      ),
    );
  }
}

/// What a map area shows with no engine (widget tests, or a Google
/// script that failed to load): a faint grid so the space still reads
/// as a map, and a small caption.
class MapUnavailable extends StatelessWidget {
  const MapUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return ColoredBox(
      color: isDark ? AppColors.surfaceTintDark : AppColors.surfaceAlt,
      child: CustomPaint(
        painter: _GridPainter(color: ink.withValues(alpha: 0.14)),
        child: SizedBox.expand(
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.s,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.surfaceDark : AppColors.surface)
                      .withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 14, color: ink),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      l10n.mapUnavailable,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = color
      ..strokeWidth = 1;
    final thick = Paint()
      ..color = color
      ..strokeWidth = 2.5;
    const step = 28.0;
    var index = 0;
    for (var x = step; x < size.width; x += step, index++) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        index % 4 == 2 ? thick : thin,
      );
    }
    index = 0;
    for (var y = step; y < size.height; y += step, index++) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        index % 4 == 1 ? thick : thin,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.color != color;
}

/// Light Google map with points of interest and transit hidden: the pin
/// and the address card are the subject, not shop labels.
const _lightStyle =
    '[{"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},'
    '{"featureType":"transit","stylers":[{"visibility":"off"}]}]';

/// Night Google map in Kaylo's dark greens.
const _darkStyle =
    '[{"elementType":"geometry","stylers":[{"color":"#1d1f1e"}]},'
    '{"elementType":"labels.text.fill","stylers":[{"color":"#9aa39d"}]},'
    '{"elementType":"labels.text.stroke","stylers":[{"color":"#1d1f1e"}]},'
    '{"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},'
    '{"featureType":"transit","stylers":[{"visibility":"off"}]},'
    '{"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c302e"}]},'
    '{"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#242726"}]},'
    '{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0f1a14"}]},'
    '{"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#1a211d"}]}]';
