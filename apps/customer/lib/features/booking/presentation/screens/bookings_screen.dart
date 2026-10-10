import '../../../../core/config/service_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaylo_core/models/booking.dart';
import 'package:kaylo_core/models/service_item.dart';
import '../../../../core/router/routes.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_radius.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_core/utils/money.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import 'package:kaylo_ui/widgets/error_state.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/section_header.dart';
import 'package:kaylo_ui/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../home/application/home_providers.dart';
import '../../../care/application/care_booking_link.dart';
import '../../application/bookings_providers.dart';
import '../widgets/booking_labels.dart';

/// Bookings tab: everything the customer has booked, split into what is
/// still ahead and what is done. M4 extends this with tracking and
/// reviews; the list itself is shared by every booking flow.
class BookingsScreen extends ConsumerWidget {
  final bool completedOnly;

  const BookingsScreen({super.key, this.completedOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bookings = ref.watch(userBookingsProvider);
    final catalog = ref.watch(fullCatalogProvider).whenOrNull(data: (s) => s);
    final byId = {for (final s in catalog ?? const <ServiceItem>[]) s.id: s};
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(userBookingsProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.m,
              AppSpacing.l,
              120, // clearance for the bottom nav
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.myBookings,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.myBookingsSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.xs,
                children: [
                  ChoiceChip(
                    label: Text(l10n.allBookings),
                    selected: !completedOnly,
                    onSelected: (_) {
                      KayloFeedback.selection();
                      context.go(Routes.bookings);
                    },
                  ),
                  ChoiceChip(
                    label: Text(l10n.statCompleted),
                    selected: completedOnly,
                    onSelected: (_) {
                      KayloFeedback.selection();
                      context.go('${Routes.bookings}?status=completed');
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              ...bookings.when(
                data: (list) {
                  final completed =
                      list
                          .where((b) => b.status == BookingStatus.completed)
                          .toList()
                        ..sort(
                          (a, b) => b.scheduledAt.compareTo(a.scheduledAt),
                        );
                  if (completedOnly) {
                    if (completed.isEmpty) {
                      return [
                        EmptyState(
                          title: l10n.noCompletedBookings,
                          description: l10n.noCompletedBookingsDescription,
                          icon: Icons.task_alt_rounded,
                          actionText: l10n.allBookings,
                          onActionPressed: () => context.go(Routes.bookings),
                        ),
                      ];
                    }
                    return [
                      for (final b in completed) ...[
                        _BookingCard(booking: b, service: byId[b.serviceId]),
                        const SizedBox(height: AppSpacing.m),
                      ],
                    ];
                  }
                  if (list.isEmpty) {
                    return [
                      EmptyState(
                        title: l10n.noBookingsTitle,
                        description: l10n.noBookingsDescription,
                        icon: Icons.event_available_rounded,
                        actionText: l10n.bookAService,
                        onActionPressed: () =>
                            context.push(Routes.homeServices),
                      ),
                    ];
                  }
                  final now = DateTime.now();
                  bool isUpcoming(Booking b) =>
                      b.status != BookingStatus.completed &&
                      b.status != BookingStatus.cancelled &&
                      !b.scheduledAt.isBefore(now);
                  final upcoming = list.where(isUpcoming).toList()
                    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
                  final past = list.where((b) => !isUpcoming(b)).toList()
                    ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

                  return [
                    if (upcoming.isNotEmpty) ...[
                      SectionHeader(title: l10n.upcoming),
                      const SizedBox(height: AppSpacing.m),
                      for (final b in upcoming) ...[
                        _BookingCard(booking: b, service: byId[b.serviceId]),
                        const SizedBox(height: AppSpacing.m),
                      ],
                      const SizedBox(height: AppSpacing.m),
                    ],
                    if (past.isNotEmpty) ...[
                      SectionHeader(title: l10n.past),
                      const SizedBox(height: AppSpacing.m),
                      for (final b in past) ...[
                        _BookingCard(booking: b, service: byId[b.serviceId]),
                        const SizedBox(height: AppSpacing.m),
                      ],
                    ],
                  ];
                },
                loading: () => [
                  for (var i = 0; i < 3; i++) ...[
                    const ShimmerBox(
                      width: double.infinity,
                      height: 132,
                      radius: AppRadius.card,
                    ),
                    const SizedBox(height: AppSpacing.m),
                  ],
                ],
                error: (error, _) => [
                  ErrorState(
                    title: l10n.somethingWentWrong,
                    message: error.toString(),
                    onRetry: () => ref.invalidate(userBookingsProvider),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final Booking booking;
  final ServiceItem? service;

  const _BookingCard({required this.booking, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final loc = MaterialLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final accent = switch (service?.category) {
      'farm' => AppColors.farmAccent,
      'care' => AppColors.careAccent,
      _ => AppColors.homeAccent,
    };

    Widget detail(IconData icon, String value) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: secondary),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: secondary),
            ),
          ),
        ],
      ),
    );

    return KayloCard(
      onTap: () {
        KayloFeedback.tap();
        context.push(Routes.bookingDetails(booking.id));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: service != null
                    ? Image.asset(
                        ServiceArtwork.resolve(
                          name: service!.name,
                          category: service!.category,
                          fallback: service!.iconPath,
                        ),
                        fit: BoxFit.contain,
                      )
                    : Icon(Icons.handyman_rounded, color: accent),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service?.name ?? l10n.service,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      booking.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          detail(
            Icons.schedule_rounded,
            '${loc.formatMediumDate(booking.scheduledAt)}, '
            '${loc.formatTimeOfDay(TimeOfDay.fromDateTime(booking.scheduledAt))}',
          ),
          detail(Icons.payments_rounded, formatRupees(booking.totalAmount)),
          // Care bookings name the doctor or caregiver the customer chose.
          if (isCareService(service))
            ...ref
                .watch(careBookingInfoProvider(booking.id))
                .maybeWhen(
                  data: (info) => [
                    if (info.appointment != null)
                      detail(
                        Icons.medical_services_rounded,
                        '${info.appointment!.doctorName} · '
                        '${info.appointment!.specialty}',
                      ),
                    if (info.caregiverBooking != null)
                      detail(
                        Icons.volunteer_activism_rounded,
                        '${info.caregiverBooking!.caregiverName} · '
                        '${info.caregiverBooking!.careType}',
                      ),
                  ],
                  orElse: () => const <Widget>[],
                ),
          const SizedBox(height: AppSpacing.s),
          BookingStatusChip(status: booking.status),
          if (booking.notes != null && booking.notes!.isNotEmpty)
            detail(
              isCareService(service)
                  ? Icons.notes_rounded
                  : Icons.pin_drop_rounded,
              booking.notes!,
            ),
        ],
      ),
    );
  }
}
