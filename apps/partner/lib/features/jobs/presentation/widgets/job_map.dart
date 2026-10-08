import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_radius.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:latlong2/latlong.dart' as geo;

import '../../../../core/router/routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/partner_session.dart';
import '../../domain/job.dart';

/// An in-app map widget showing the job location, worker position,
/// and route polyline with OpenStreetMap tiles.
class JobMap extends ConsumerWidget {
  final Job job;
  final double? height;
  final bool interactive;
  final bool showTiles;
  final bool showExpandButton;
  final VoidCallback? onOpenGoogleMaps;
  final double padding;

  const JobMap({
    super.key,
    required this.job,
    this.height,
    this.interactive = false,
    this.showTiles = true,
    this.showExpandButton = true,
    this.onOpenGoogleMaps,
    this.padding = 32.0,
  });

  bool get _effectiveShowTiles {
    if (!showTiles) return false;
    if (WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding')) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final worker = ref.watch(partnerWorkerProfileProvider);

    final workerPoint = geo.LatLng(worker.latitude, worker.longitude);
    final customerPoint = geo.LatLng(job.latitude, job.longitude);

    final sameLocation = workerPoint.latitude == customerPoint.latitude &&
        workerPoint.longitude == customerPoint.longitude;

    final mapWidget = ClipRRect(
      borderRadius: BorderRadius.circular(interactive ? 0 : AppRadius.card),
      child: Stack(
        children: [
          osm.FlutterMap(
            options: osm.MapOptions(
              initialCenter: customerPoint,
              initialZoom: sameLocation ? 15.0 : 13.0,
              initialCameraFit: sameLocation
                  ? null
                  : osm.CameraFit.bounds(
                      bounds: osm.LatLngBounds.fromPoints([
                        workerPoint,
                        customerPoint,
                      ]),
                      padding: EdgeInsets.all(padding),
                    ),
              minZoom: 3,
              maxZoom: 19,
              backgroundColor: isDark
                  ? AppColors.surfaceTintDark
                  : AppColors.surfaceAlt,
              interactionOptions: osm.InteractionOptions(
                flags: interactive
                    ? osm.InteractiveFlag.all & ~osm.InteractiveFlag.rotate
                    : osm.InteractiveFlag.none,
              ),
            ),
            children: [
              if (_effectiveShowTiles)
                osm.TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.kaylo.partner',
                  maxNativeZoom: 19,
                  tileBuilder: isDark ? osm.darkModeTileBuilder : null,
                ),
              osm.PolylineLayer(
                polylines: [
                  osm.Polyline(
                    points: [workerPoint, customerPoint],
                    color: AppColors.brandPrimary,
                    strokeWidth: 3.5,
                  ),
                ],
              ),
              osm.MarkerLayer(
                markers: [
                  // Worker position marker (brand-coloured dot)
                  osm.Marker(
                    point: workerPoint,
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: Container(
                      key: const Key('worker_marker'),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Customer location marker (home pin)
                  osm.Marker(
                    point: customerPoint,
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: Icon(
                      key: const Key('customer_marker'),
                      Icons.location_on_rounded,
                      size: 40,
                      color: AppColors.brandPrimaryDark,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // OpenStreetMap credit
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  margin: const EdgeInsets.all(AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.surfaceDark : AppColors.surface)
                        .withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(
                      fontSize: 9,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Action buttons overlay (Open in Google Maps, Expand)
          if (showExpandButton || onOpenGoogleMaps != null)
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onOpenGoogleMaps != null) ...[
                    _MapActionButton(
                      icon: Icons.navigation_outlined,
                      label: l10n.openInGoogleMaps,
                      isDark: isDark,
                      onTap: () {
                        KayloFeedback.tap();
                        onOpenGoogleMaps!();
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (showExpandButton)
                    _MapActionButton(
                      icon: Icons.open_in_full_rounded,
                      label: l10n.expand,
                      isDark: isDark,
                      onTap: () {
                        KayloFeedback.selection();
                        context.push(Routes.jobMap(job.id));
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    if (height != null) {
      return SizedBox(height: height, child: mapWidget);
    }

    return mapWidget;
  }
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _MapActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.surfaceDark : AppColors.surface)
                .withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.brandPrimary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
