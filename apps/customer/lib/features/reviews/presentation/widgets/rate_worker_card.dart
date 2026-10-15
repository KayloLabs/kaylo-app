import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/models/booking.dart';
import 'package:kaylo_core/network/app_failure.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_core/services/sound_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';
import 'package:kaylo_ui/widgets/rating_stars.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../workers/application/workers_providers.dart';
import '../../application/reviews_providers.dart';
import '../../domain/booking_review.dart';

/// After a completed booking: an invitation to rate the worker, or the
/// review already written with a way to change it.
class RateWorkerCard extends ConsumerWidget {
  final Booking booking;
  const RateWorkerCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final review = ref.watch(bookingReviewProvider(booking.id));

    void open([BookingReview? existing]) {
      KayloFeedback.press();
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => RateWorkerSheet(booking: booking, existing: existing),
      );
    }

    return review.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (existing) => KayloCard(
        child: existing == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.rateYourWorker,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.rateWorkerHint,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: secondary),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  KayloButton(
                    text: l10n.rateYourWorker,
                    icon: Icons.star_rounded,
                    onPressed: open,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.yourReview,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: () => open(existing),
                        child: Text(l10n.editReview),
                      ),
                    ],
                  ),
                  RatingStars(rating: existing.rating.toDouble(), size: 18),
                  if (existing.text != null) ...[
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      existing.text!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class RateWorkerSheet extends ConsumerStatefulWidget {
  final Booking booking;
  final BookingReview? existing;
  const RateWorkerSheet({super.key, required this.booking, this.existing});

  @override
  ConsumerState<RateWorkerSheet> createState() => _RateWorkerSheetState();
}

class _RateWorkerSheetState extends ConsumerState<RateWorkerSheet> {
  late int _rating = widget.existing?.rating ?? 0;
  late final _text = TextEditingController(text: widget.existing?.text ?? '');
  bool _saving = false;
  late bool _hideName = widget.existing?.hideName ?? false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_rating == 0) {
      KayloFeedback.alert();
      KayloSnackbar.showError(context, l10n.ratingRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(reviewsRepositoryProvider)
          .submit(
            bookingId: widget.booking.id,
            workerId: widget.booking.workerId!,
            rating: _rating,
            text: _text.text,
            hideName: _hideName,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      KayloFeedback.alert();
      KayloSnackbar.showError(
        context,
        error is AppFailure ? error.message : l10n.somethingWentWrong,
      );
      return;
    }
    if (!mounted) return;
    ref.invalidate(bookingReviewProvider(widget.booking.id));
    ref.invalidate(workerReviewsProvider(widget.booking.workerId!));
    ref.invalidate(workerDetailProvider(widget.booking.workerId!));
    KayloFeedback.success();
    ref.read(soundServiceProvider).playSuccess();
    KayloSnackbar.showSuccess(context, l10n.reviewSubmitted);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.l,
        AppSpacing.l,
        AppSpacing.l + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.rateYourWorker,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                Semantics(
                  label: l10n.starLabel(star),
                  button: true,
                  selected: star <= _rating,
                  child: IconButton(
                    iconSize: 40,
                    color: star <= _rating
                        ? AppColors.secondaryAccent
                        : AppColors.textSecondary,
                    icon: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                    ),
                    onPressed: _saving
                        ? null
                        : () {
                            KayloFeedback.selection();
                            setState(() => _rating = star);
                          },
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          KayloTextField(
            label: l10n.yourReview,
            hintText: l10n.reviewTextHint,
            controller: _text,
            maxLength: 400,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.hideReviewName),
            subtitle: Text(l10n.hideReviewNameHint),
            value: _hideName,
            onChanged: _saving
                ? null
                : (value) => setState(() => _hideName = value ?? false),
          ),
          const SizedBox(height: AppSpacing.l),
          KayloButton(
            text: l10n.submitReview,
            icon: Icons.send_rounded,
            isLoading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}
