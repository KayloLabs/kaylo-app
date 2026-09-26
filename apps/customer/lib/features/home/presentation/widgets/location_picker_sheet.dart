import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_core/services/location_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import '../../../../core/widgets/kaylo_map.dart';
import '../../../../core/widgets/use_my_location_button.dart'
    show locationErrorMessage;
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/user_location_provider.dart';

/// Lets the customer set their active location: drop the pin on the
/// map, jump to GPS, or search a town. Resolves true when a location
/// was saved.
Future<bool> showLocationPickerSheet(BuildContext context) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    // Over the whole app so the floating bottom nav stays underneath.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const LocationPickerSheet(),
  );
  return saved ?? false;
}

/// Map-first picker in the style of delivery apps: the map moves under a
/// fixed pin, the address beneath it refreshes once the map settles, a
/// button jumps to GPS, and a search field covers places the customer
/// cannot pan to. Without a Maps key the map area is a placeholder and
/// the other two paths still work.
class LocationPickerSheet extends ConsumerStatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  ConsumerState<LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<LocationPickerSheet> {
  final _town = TextEditingController();
  final _townFocus = FocusNode();
  GoogleMapController? _map;
  Timer? _debounce;

  /// Sequence number so a slow lookup cannot overwrite a newer one.
  int _lookup = 0;

  /// Where the pin is: the camera target.
  LatLng? _target;

  /// What Confirm saves.
  UserLocation? _selected;

  bool _resolving = false;
  bool _locating = false;
  bool _moving = false;
  bool _moved = false;

  /// The camera settles once right after the map is created and again
  /// after every programmatic move; those positions already have their
  /// address, so their idle callback must not trigger a lookup.
  bool _skipNextIdle = true;

  @override
  void initState() {
    super.initState();
    final current = ref.read(userLocationProvider);
    _selected = current;
    final lat = current.latitude;
    final lng = current.longitude;
    if (lat != null && lng != null) _target = LatLng(lat, lng);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _town.dispose();
    _townFocus.dispose();
    super.dispose();
  }

  LocationService get _service => ref.read(locationServiceProvider);

  void _onCameraMoveStarted() {
    _debounce?.cancel();
    if (!_moving || !_moved) {
      setState(() {
        _moving = true;
        _moved = true;
      });
    }
  }

  void _onCameraMove(CameraPosition position) => _target = position.target;

  void _onCameraIdle() {
    if (_moving) setState(() => _moving = false);
    if (_skipNextIdle) {
      _skipNextIdle = false;
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _resolveTarget);
  }

  Future<void> _resolveTarget() async {
    final target = _target;
    if (target == null) return;
    final id = ++_lookup;
    setState(() => _resolving = true);
    final resolved = await _service.resolve(target.latitude, target.longitude);
    if (!mounted || id != _lookup) return;
    setState(() {
      _resolving = false;
      _selected = UserLocation.fromResolved(resolved);
    });
  }

  Future<void> _moveTo(ResolvedLocation location, {double zoom = 16}) async {
    _skipNextIdle = true;
    final target = LatLng(location.latitude, location.longitude);
    _target = target;
    setState(() {
      _selected = UserLocation.fromResolved(location);
      _moved = true;
    });
    await _map?.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }

  Future<void> _locateMe() async {
    final l10n = AppLocalizations.of(context)!;
    KayloFeedback.tap();
    _lookup++; // Drops any pin lookup still in flight.
    setState(() => _locating = true);
    try {
      final resolved = await _service.locate();
      if (!mounted) return;
      KayloFeedback.press();
      await _moveTo(resolved);
    } on LocationFailure catch (failure) {
      if (mounted) {
        KayloSnackbar.showError(
          context,
          locationErrorMessage(l10n, failure.code),
        );
      }
    } catch (_) {
      if (mounted) KayloSnackbar.showError(context, l10n.locationUnavailable);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _searchTown() async {
    final l10n = AppLocalizations.of(context)!;
    final town = _town.text.trim();
    if (town.isEmpty) {
      KayloSnackbar.showError(context, l10n.townRequired);
      return;
    }
    _townFocus.unfocus();
    final id = ++_lookup;
    setState(() => _resolving = true);
    final found = await _service.search(town);
    if (!mounted || id != _lookup) return;
    if (found == null) {
      // Not on the map, but the typed name is still a usable label.
      setState(() {
        _resolving = false;
        _selected = UserLocation(label: town);
      });
      return;
    }
    setState(() => _resolving = false);
    await _moveTo(found, zoom: 14);
  }

  Future<void> _finish(UserLocation location) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(userLocationProvider.notifier).set(location);
    if (!mounted) return;
    KayloFeedback.press();
    Navigator.of(context).pop(true);
    KayloSnackbar.showSuccess(context, l10n.locationUpdated(location.label));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceModalDark : AppColors.surface;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // While typing a town the address card and Confirm step aside so the
    // map keeps some height above the keyboard on small phones.
    final typing = keyboard > 0;
    final selected = _selected;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: ColoredBox(
        color: surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.m,
                AppSpacing.s,
                AppSpacing.s,
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.yourLocation,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: KayloMap(
                      center: _target ?? kannurCenter,
                      zoom: _target == null ? 12 : 15,
                      followCenter: false,
                      padding: const EdgeInsets.only(bottom: AppSpacing.s),
                      onMapCreated: (controller) => _map = controller,
                      onCameraMoveStarted: _onCameraMoveStarted,
                      onCameraMove: _onCameraMove,
                      onCameraIdle: _onCameraIdle,
                    ),
                  ),
                  if (googleMapsConfigured) ...[
                    IgnorePointer(
                      child: Center(child: _MapPin(lifted: _moving)),
                    ),
                    Positioned(
                      top: AppSpacing.m,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: _moved ? 0 : 1,
                            duration: const Duration(milliseconds: 250),
                            child: _HintChip(text: l10n.moveMapToPlacePin),
                          ),
                        ),
                      ),
                    ),
                  ],
                  Positioned(
                    right: AppSpacing.l,
                    bottom: AppSpacing.l,
                    child: _LocateButton(
                      busy: _locating,
                      tooltip: l10n.useMyLocation,
                      onTap: _locateMe,
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.l,
                  AppSpacing.xl,
                  AppSpacing.l + keyboard,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!typing) ...[
                      _SelectedLocation(
                        location: selected,
                        resolving: _resolving,
                      ),
                      const SizedBox(height: AppSpacing.l),
                      KayloButton(
                        text: l10n.confirmLocation,
                        icon: Icons.check_rounded,
                        isLoading: _resolving,
                        onPressed: selected == null
                            ? null
                            : () => _finish(selected),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.m,
                            ),
                            child: Text(
                              l10n.or,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.m),
                    ],
                    TextField(
                      controller: _town,
                      focusNode: _townFocus,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchTown(),
                      decoration: InputDecoration(
                        hintText: l10n.searchTownHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(
                          tooltip: l10n.searchTownHint,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          onPressed: _searchTown,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The address under the pin. The leading circle turns into a spinner
/// while a lookup runs so the row keeps its height.
class _SelectedLocation extends StatelessWidget {
  final UserLocation? location;
  final bool resolving;

  const _SelectedLocation({required this.location, required this.resolving});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final addressLine = location?.addressLine;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: resolving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brandPrimary,
                      ),
                    )
                  : const Icon(
                      Icons.place_rounded,
                      color: AppColors.brandPrimary,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.selectedLocation,
                  style: theme.textTheme.labelSmall?.copyWith(color: secondary),
                ),
                const SizedBox(height: 2),
                Text(
                  resolving ? l10n.findingAddress : (location?.label ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!resolving && addressLine != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    addressLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed pin whose tip sits on the camera target. It lifts a little while
/// the map moves and settles back when it stops, the delivery-app cue
/// that the map, not the pin, is what you drag.
class _MapPin extends StatelessWidget {
  final bool lifted;

  const _MapPin({required this.lifted});

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 160);
    // The box is centred on the map; the pin tip lands on its centre.
    return SizedBox(
      width: 56,
      height: 96,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 46,
            child: AnimatedContainer(
              duration: duration,
              width: lifted ? 18 : 10,
              height: lifted ? 6 : 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: lifted ? 0.16 : 0.28),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Positioned(
            top: 4,
            child: AnimatedSlide(
              duration: duration,
              curve: Curves.easeOut,
              offset: Offset(0, lifted ? -0.18 : 0),
              child: Icon(
                Icons.location_on_rounded,
                size: 48,
                color: AppColors.brandPrimary,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  final String text;

  const _HintChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.open_with_rounded, size: 14, color: Colors.white),
          const SizedBox(width: AppSpacing.s),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Round "locate me" button floating over the map.
class _LocateButton extends StatelessWidget {
  final bool busy;
  final String tooltip;
  final VoidCallback onTap;

  const _LocateButton({
    required this.busy,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: busy ? null : onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brandPrimary,
                      ),
                    )
                  : const Icon(
                      Icons.my_location_rounded,
                      color: AppColors.brandPrimary,
                      size: 22,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
