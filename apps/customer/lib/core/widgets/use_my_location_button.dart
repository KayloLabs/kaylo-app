import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_core/services/location_service.dart';
import '../theme/app_colors.dart';
import 'kaylo_snackbar.dart';

/// Human-readable reason a GPS lookup failed, keyed on LocationFailure.code.
String locationErrorMessage(AppLocalizations l10n, String? code) =>
    switch (code) {
      'services-disabled' => l10n.locationServicesOff,
      'denied' => l10n.locationDenied,
      'denied-forever' => l10n.locationDeniedForever,
      'timeout' => l10n.locationTimeout,
      _ => l10n.locationUnavailable,
    };

/// "Use my location" chip: asks for permission, reads GPS, reverse
/// geocodes, and hands the result back. Errors surface as a snackbar so
/// callers only deal with the success path.
class UseMyLocationButton extends ConsumerStatefulWidget {
  final ValueChanged<ResolvedLocation> onResolved;

  /// Chip (default) for inline use next to a field; false renders a
  /// full-width primary button for setup screens.
  final bool compact;

  const UseMyLocationButton({
    super.key,
    required this.onResolved,
    this.compact = true,
  });

  @override
  ConsumerState<UseMyLocationButton> createState() =>
      _UseMyLocationButtonState();
}

class _UseMyLocationButtonState extends ConsumerState<UseMyLocationButton> {
  bool _busy = false;

  Future<void> _locate() async {
    final l10n = AppLocalizations.of(context)!;
    KayloFeedback.tap();
    setState(() => _busy = true);
    try {
      final resolved = await ref.read(locationServiceProvider).locate();
      if (!mounted) return;
      KayloFeedback.press();
      widget.onResolved(resolved);
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
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spinner = SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: widget.compact ? AppColors.brandPrimary : Colors.white,
      ),
    );

    if (widget.compact) {
      return ActionChip(
        avatar: _busy
            ? spinner
            : const Icon(
                Icons.my_location_rounded,
                size: 18,
                color: AppColors.brandPrimary,
              ),
        label: Text(_busy ? l10n.locating : l10n.useMyLocation),
        onPressed: _busy ? null : _locate,
      );
    }

    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
        icon: _busy ? spinner : const Icon(Icons.my_location_rounded),
        label: Text(_busy ? l10n.locating : l10n.useMyLocation),
        onPressed: _busy ? null : _locate,
      ),
    );
  }
}
