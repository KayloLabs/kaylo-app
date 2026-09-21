import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/booking.dart';
import '../../../../core/models/service_item.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../home/application/home_providers.dart';
import '../../application/bookings_providers.dart';
import '../widgets/booking_labels.dart';

/// Bookings tab: everything the customer has booked, split into what is
/// still ahead and what is done. M4 extends this with tracking and
/// reviews; the list itself is shared by every booking flow.
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

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
        child: ListView(
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
            ...bookings.when(
              data: (list) {
                if (list.isEmpty) {
                  return [
                    EmptyState(
                      title: l10n.noBookingsTitle,
                      description: l10n.noBookingsDescription,
                      icon: Icons.event_available_rounded,
                      actionText: l10n.bookAService,
                      onActionPressed: () => context.push(Routes.farm),
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
                final past = list.where((b) => !isUpcoming(b)).toList();

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
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final ServiceItem? service;

  const _BookingCard({required this.booking, required this.service});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loc = MaterialLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
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
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: secondary),
                ),
              ),
            ],
          ),
        );

    return KayloCard(
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
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      booking.id,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: secondary),
                    ),
                  ],
                ),
              ),
              BookingStatusChip(status: booking.status),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          detail(
            Icons.schedule_rounded,
            '${loc.formatMediumDate(booking.scheduledAt)}, '
            '${loc.formatTimeOfDay(TimeOfDay.fromDateTime(booking.scheduledAt))}',
          ),
          detail(Icons.payments_rounded, formatRupees(booking.totalAmount)),
          if (booking.notes != null && booking.notes!.isNotEmpty)
            detail(Icons.pin_drop_rounded, booking.notes!),
        ],
      ),
    );
  }
}
