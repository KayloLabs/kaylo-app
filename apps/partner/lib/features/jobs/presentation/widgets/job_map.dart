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
import '../../application/partner_location.dart';
import 'package:kaylo_ui/theme/app_shadows.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final worker = ref.watch(partnerLocationProvider).asData?.value;
    if (job.latitude == null || job.longitude == null) {
      return SizedBox(
        height: height,
        child: Center(child: Text(l10n.mapLocationUnavailable)),
      );
    }

    final workerPoint = worker == null
        ? null
        : geo.LatLng(worker.latitude, worker.longitude);
    final customerPoint = geo.LatLng(job.latitude!, job.longitude!);

    final sameLocation =
        workerPoint == null ||
        workerPoint.latitude == customerPoint.latitude &&
            workerPoint.longitude == customerPoint.longitude;

    final mapWidget = ClipRRect(
      borderRadius: BorderRadius.circular(interactive ? 0 : AppRadius.card),
      child: Stack(
        children: [
          osm.FlutterMap(
            key: ValueKey((workerPoint, customerPoint)),
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
              if (showTiles && ref.watch(jobMapTilesProvider))
                osm.TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.kaylo.partner',
                  maxNativeZoom: 19,
                  tileBuilder: isDark ? osm.darkModeTileBuilder : null,
                ),
              osm.MarkerLayer(
                markers: [
                  // Worker position marker (brand-coloured dot)
                  if (workerPoint != null)
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
                          boxShadow: [AppShadows.getSm(context)],
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
                    ),
                  ),
                ],
              ),
              if (job.isRequested)
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(6),
                    color: Theme.of(context).colorScheme.surface,
                    child: Text(
                      l10n.mapApproximateArea,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.surfaceDark : AppColors.surface)
                .withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 0.5,
            ),
            boxShadow: [AppShadows.getSm(context)],
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
