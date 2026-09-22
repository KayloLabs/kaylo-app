import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaylo_core/models/booking.dart';
import 'package:kaylo_core/models/service_item.dart';
import 'package:kaylo_core/models/worker.dart';
import '../../../../core/router/routes.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/avatar_circle.dart';
import 'package:kaylo_ui/widgets/error_state.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/price_tag.dart';
import 'package:kaylo_ui/widgets/rating_stars.dart';
import 'package:kaylo_ui/widgets/section_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../home/application/home_providers.dart';
import '../../../messages/application/messages_providers.dart';
import '../../../farm/domain/farm_booking_draft.dart';
import '../../../farm/domain/farm_service_info.dart';
import '../../../farm/presentation/widgets/farm_labels.dart';
import '../../application/bookings_providers.dart';
import '../widgets/booking_labels.dart';

class BookingDetailsScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final booking = ref.watch(bookingByIdProvider(bookingId));
    final catalog =
        ref.watch(fullCatalogProvider).whenOrNull(data: (s) => s) ?? const [];

    return booking.when(
      data: (booking) => _Details(
        booking: booking,
        service: catalog.where((s) => s.id == booking.serviceId).firstOrNull,
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.bookingDetails)),
        body: const Center(child: KayloLoader()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.bookingDetails)),
        body: ErrorState(
          title: l10n.somethingWentWrong,
          message: error.toString(),
          onRetry: () => ref.invalidate(userBookingsProvider),
        ),
      ),
    );
  }
}

class _Details extends ConsumerWidget {
  final Booking booking;
  final ServiceItem? service;

  const _Details({required this.booking, required this.service});

  bool get _isActive =>
      (booking.status == BookingStatus.pending ||
          booking.status == BookingStatus.confirmed) &&
      booking.scheduledAt.isAfter(DateTime.now());

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelBookingTitle),
        content: Text(l10n.cancelBookingMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepBooking),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.cancelBooking),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    KayloFeedback.alert();
    await ref.read(bookingsControllerProvider).cancel(booking.id);
    if (context.mounted) KayloSnackbar.showInfo(context, l10n.bookingCancelled);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final loc = MaterialLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final accent = categoryAccent(service?.category ?? 'home');
    final info = service == null ? null : farmInfoFor(service!);
    // Quantity is not stored on the booking; it falls out of the amount
    // whenever the total is a whole number of units.
    final quantity = service == null || service!.basePrice <= 0
        ? null
        : (booking.totalAmount / service!.basePrice);
    final wholeQuantity =
        quantity != null && quantity == quantity.roundToDouble()
        ? quantity.round()
        : null;

    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: secondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
    Widget text(String value) => Text(
      value,
      textAlign: TextAlign.end,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingDetails)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.l,
          140,
        ),
        children: [
          KayloCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: service != null
                      ? Image.asset(service!.iconPath, fit: BoxFit.contain)
                      : Icon(Icons.handyman_rounded, color: accent),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service?.name ?? l10n.service,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        booking.id,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: secondary),
                      ),
                    ],
                  ),
                ),
                BookingStatusChip(status: booking.status),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          if (booking.status == BookingStatus.cancelled)
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_rounded, color: AppColors.error),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      l10n.bookingCancelledBanner,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            KayloCard(child: _StatusTimeline(status: booking.status)),
          const SizedBox(height: AppSpacing.xxl),

          SectionHeader(title: l10n.orderSummary),
          const SizedBox(height: AppSpacing.m),
          KayloCard(
            child: Column(
              children: [
                row(l10n.date, text(loc.formatFullDate(booking.scheduledAt))),
                row(
                  l10n.time,
                  text(
                    loc.formatTimeOfDay(
                      TimeOfDay.fromDateTime(booking.scheduledAt),
                    ),
                  ),
                ),
                if (wholeQuantity != null && info != null)
                  row(
                    l10n.quantity,
                    text(farmUnitCount(l10n, info.unit, wholeQuantity)),
                  ),
                if (booking.notes != null && booking.notes!.isNotEmpty)
                  row(
                    service?.category == 'farm'
                        ? l10n.farmAddress
                        : l10n.serviceAddress,
                    text(booking.notes!),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Divider(height: 1),
                ),
                row(l10n.total, PriceTag(amount: booking.totalAmount)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          SectionHeader(title: l10n.assignedWorker),
          const SizedBox(height: AppSpacing.m),
          if (booking.workerId == null)
            KayloCard(
              child: Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, color: secondary),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      l10n.noWorkerYet,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          else
            ref
                .watch(bookingWorkerProvider(booking.workerId!))
                .when(
                  data: (worker) => _WorkerCard(worker: worker),
                  loading: () => const KayloCard(
                    child: SizedBox(
                      height: 48,
                      child: Center(child: KayloLoader(size: 28)),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
        ],
      ),
      bottomNavigationBar: _isActive
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.s,
                AppSpacing.l,
                AppSpacing.l,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KayloButton(
                    text: l10n.reschedule,
                    icon: Icons.edit_calendar_rounded,
                    variant: KayloButtonVariant.secondary,
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => _RescheduleSheet(booking: booking),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: () => _cancel(context, ref),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: Text(l10n.cancelBooking),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

/// Four-step progress strip; the current step glows, done steps are
/// ticked, later ones stay hollow.
class _StatusTimeline extends StatelessWidget {
  final BookingStatus status;

  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = [
      l10n.stepRequested,
      l10n.stepConfirmed,
      l10n.stepInProgress,
      l10n.stepCompleted,
    ];
    final current = switch (status) {
      BookingStatus.pending => 0,
      BookingStatus.confirmed => 1,
      BookingStatus.inProgress => 2,
      BookingStatus.completed => 3,
      BookingStatus.cancelled => -1,
    };
    final idle = isDark ? AppColors.borderDark : AppColors.border;

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < current
                        ? AppColors.brandPrimary
                        : i == current
                        ? AppColors.brandPrimary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: i <= current ? AppColors.brandPrimary : idle,
                      width: 2,
                    ),
                  ),
                  child: i < current
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : i == current
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  steps[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: i == current
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: i <= current
                        ? (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary)
                        : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          if (i < steps.length - 1)
            Container(
              width: 18,
              height: 2,
              margin: const EdgeInsets.only(bottom: 28),
              color: i < current ? AppColors.brandPrimary : idle,
            ),
        ],
      ],
    );
  }
}

class _WorkerCard extends ConsumerWidget {
  final Worker worker;

  const _WorkerCard({required this.worker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thread = ref
        .watch(chatThreadsProvider)
        .whenOrNull(
          data: (t) => t.where((x) => x.workerId == worker.id).firstOrNull,
        );

    return KayloCard(
      child: Row(
        children: [
          AvatarCircle(fallbackText: worker.name, radius: 26),
          const SizedBox(width: AppSpacing.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        worker.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (worker.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 18,
                        color: AppColors.brandPrimary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                RatingStars(
                  rating: worker.rating,
                  reviewCount: worker.reviewsCount,
                  size: 14,
                ),
                Text(
                  worker.location,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (thread != null)
            IconButton.filledTonal(
              tooltip: l10n.messageWorker,
              onPressed: () {
                KayloFeedback.tap();
                context.push(Routes.chat(thread.id));
              },
              icon: const Icon(Icons.chat_bubble_rounded),
            ),
        ],
      ),
    );
  }
}

class _RescheduleSheet extends ConsumerStatefulWidget {
  final Booking booking;

  const _RescheduleSheet({required this.booking});

  @override
  ConsumerState<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends ConsumerState<_RescheduleSheet> {
  late DateTime _date;
  late FarmTimeSlot _slot;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final at = widget.booking.scheduledAt;
    _date = DateTime(at.year, at.month, at.day);
    _slot = FarmTimeSlot.closestTo(at);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    final scheduledAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _slot.startMinutes ~/ 60,
      _slot.startMinutes % 60,
    );
    try {
      await ref
          .read(bookingsControllerProvider)
          .reschedule(widget.booking.id, scheduledAt);
      if (!mounted) return;
      KayloFeedback.press();
      Navigator.of(context).pop();
      KayloSnackbar.showSuccess(context, l10n.bookingRescheduled);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        KayloSnackbar.showError(context, l10n.somethingWentWrong);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loc = MaterialLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.reschedule, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.l),
          KayloCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.m,
            ),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _date.isBefore(now) ? now : _date,
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: now.add(const Duration(days: 60)),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.brandPrimary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    loc.formatFullDate(_date),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  l10n.change,
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final slot in FarmTimeSlot.all)
                ChoiceChip(
                  label: Text(formatTimeSlot(context, slot)),
                  selected: identical(slot, _slot),
                  showCheckmark: false,
                  selectedColor: AppColors.brandPrimary,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: identical(slot, _slot)
                        ? Colors.white
                        : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary),
                  ),
                  shape: const StadiumBorder(),
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                  onSelected: (_) {
                    KayloFeedback.tap();
                    setState(() => _slot = slot);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          KayloButton(text: l10n.save, isLoading: _saving, onPressed: _save),
          const SizedBox(height: AppSpacing.s),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
