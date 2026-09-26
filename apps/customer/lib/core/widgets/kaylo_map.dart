import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';
import '../maps/google_maps_loader.dart';

/// Kerala, centred, for a map that has nothing to show yet.
const LatLng keralaCenter = LatLng(10.55, 76.30);

/// Kannur town: where the seeded workers are and where the app starts
/// until the customer shares a location (UserLocation.fallback).
const LatLng kannurCenter = LatLng(11.8745, 75.3704);

/// Google Map in Kaylo's look: no stock controls, POI clutter hidden and
/// a night style in dark mode. Without a Maps key (GOOGLE_MAPS_API_KEY)
/// it renders a quiet placeholder instead of a blank grey tile, so every
/// screen keeps its layout and widget tests never create a platform view.
class KayloMap extends StatefulWidget {
  final LatLng center;
  final double zoom;
  final Set<Marker> markers;

  /// Pan, zoom and rotate. Off for previews, which also use Android's
  /// lite mode: a static map bitmap that is cheap and always crisp.
  final bool interactive;

  /// Animate to [center] and [zoom] when they change. On for a preview
  /// that follows a resolved location, off for a picker the customer
  /// pans themselves.
  final bool followCenter;

  /// Keeps the Google logo clear of overlays along the bottom.
  final EdgeInsets padding;

  final ValueChanged<GoogleMapController>? onMapCreated;
  final VoidCallback? onCameraMoveStarted;
  final ValueChanged<CameraPosition>? onCameraMove;
  final VoidCallback? onCameraIdle;

  const KayloMap({
    super.key,
    required this.center,
    this.zoom = 14,
    this.markers = const {},
    this.interactive = true,
    this.followCenter = true,
    this.padding = EdgeInsets.zero,
    this.onMapCreated,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
  });

  @override
  State<KayloMap> createState() => _KayloMapState();
}

class _KayloMapState extends State<KayloMap> {
  GoogleMapController? _controller;
  late final Future<void> _ready = googleMapsConfigured
      ? ensureGoogleMapsLoaded(googleMapsApiKey)
      : Future<void>.value();

  @override
  void didUpdateWidget(KayloMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.followCenter &&
        (widget.center != oldWidget.center || widget.zoom != oldWidget.zoom)) {
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(widget.center, widget.zoom),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!googleMapsConfigured) return const MapUnavailable();
    // Native platforms have the SDK from the start; only web waits for
    // the script.
    if (!kIsWeb) return _map(context);
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const MapUnavailable();
        if (snapshot.connectionState != ConnectionState.done) {
          return const _MapLoading();
        }
        return _map(context);
      },
    );
  }

  Widget _map(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.center,
        zoom: widget.zoom,
      ),
      markers: widget.markers,
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
      onMapCreated: (controller) {
        _controller = controller;
        widget.onMapCreated?.call(controller);
      },
      onCameraMoveStarted: widget.onCameraMoveStarted,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
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

/// What a map area shows when no Maps key was built in: a faint grid so
/// the space still reads as a map, and a small caption. Customer-facing
/// copy only; the setup instructions live in BACKEND.md.
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

/// Light map with points of interest and transit hidden: the pin and the
/// address card are the subject, not shop labels.
const _lightStyle =
    '[{"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},'
    '{"featureType":"transit","stylers":[{"visibility":"off"}]}]';

/// Night map in Kaylo's dark greens.
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
