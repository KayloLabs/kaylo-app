import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/booking.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/kaylo_loader.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../home/application/home_providers.dart';
import '../../../workers/application/workers_providers.dart';
import '../../application/booking_controller.dart';
import '../../application/bookings_providers.dart';
import '../widgets/booking_labels.dart';

class TrackingScreen extends ConsumerWidget {
  final String bookingId;

  const TrackingScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    final booking = ref.watch(bookingByIdProvider(bookingId));
    final bookingsList = ref.watch(userBookingsProvider);

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Service')),
        body: bookingsList.isLoading
            ? const Center(child: KayloLoader(size: 36))
            : ErrorState(
                title: l10n.somethingWentWrong,
                message: 'Booking not found ($bookingId)',
                onRetry: () => ref.invalidate(userBookingsProvider),
              ),
      );
    }

    final catalog = ref.watch(fullCatalogProvider).whenOrNull(data: (c) => c);
    final service = catalog
        ?.where((s) => s.id == booking.serviceId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Service'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.l),
              child: BookingStatusChip(status: booking.status),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.l,
          AppSpacing.xxl,
        ),
        children: [
          // Map Visual Card
          const _StaticMapCard(),
          const SizedBox(height: AppSpacing.xl),

          // Worker Details Card
          _WorkerInfoCard(
            workerId: booking.workerId,
            serviceName: service?.name ?? 'Home Service',
          ),
          const SizedBox(height: AppSpacing.xl),

          // Service & Schedule Info
          SectionHeader(title: 'Booking Details'),
          const SizedBox(height: AppSpacing.s),
          KayloCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                      color: secondary,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      'Booking ID: ${booking.id}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                Row(
                  children: [
                    Icon(
                      Icons.home_repair_service_rounded,
                      size: 18,
                      color: secondary,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      service?.name ?? 'Service',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: secondary,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          booking.notes!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: secondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Status Stepper Timeline
          SectionHeader(title: 'Service Status'),
          const SizedBox(height: AppSpacing.s),
          KayloCard(child: _StatusTimeline(status: booking.status)),
          const SizedBox(height: AppSpacing.xxl),

          // Review 1 Interactive Demo Simulator Card
          KayloCard(
            child: Container(
              color: AppColors.brandPrimary.withValues(
                alpha: isDark ? 0.14 : 0.08,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        color: AppColors.brandPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        'Review 1 Live Demo Controls',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tap to advance the booking status step-by-step to demonstrate workflow progression.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: secondary),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  KayloButton(
                    text: _nextStatusLabel(booking.status),
                    icon: Icons.fast_forward_rounded,
                    variant: KayloButtonVariant.secondary,
                    onPressed: () {
                      KayloFeedback.press();
                      final next = _nextStatus(booking.status);
                      ref
                          .read(bookingCheckoutControllerProvider.notifier)
                          .updateStatus(booking.id, next);
                      KayloSnackbar.showSuccess(
                        context,
                        'Status advanced to: ${bookingStatusLabel(l10n, next)}',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static BookingStatus _nextStatus(BookingStatus current) => switch (current) {
    BookingStatus.pending => BookingStatus.confirmed,
    BookingStatus.confirmed => BookingStatus.onWay,
    BookingStatus.onWay => BookingStatus.inProgress,
    BookingStatus.inProgress => BookingStatus.completed,
    BookingStatus.completed => BookingStatus.confirmed,
    BookingStatus.cancelled => BookingStatus.confirmed,
  };

  static String _nextStatusLabel(BookingStatus current) => switch (current) {
    BookingStatus.pending => 'Confirm Booking',
    BookingStatus.confirmed => 'Simulate: Worker On The Way',
    BookingStatus.onWay => 'Simulate: Start Service',
    BookingStatus.inProgress => 'Simulate: Mark Service Completed',
    BookingStatus.completed => 'Reset to Confirmed',
    BookingStatus.cancelled => 'Reset to Confirmed',
  };
}

class _StaticMapCard extends StatefulWidget {
  const _StaticMapCard();

  @override
  State<_StaticMapCard> createState() => _StaticMapCardState();
}

class _StaticMapCardState extends State<_StaticMapCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        color: isDark ? const Color(0xFF161F28) : const Color(0xFFE9F1F7),
      ),
      child: Stack(
        children: [
          // Map Background Illustration
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(painter: _MapCanvasPainter(isDark: isDark)),
            ),
          ),

          // ETA Floating Badge
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xDD1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.brandPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Arriving in ~20 mins • 2.4 km',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.brandPrimaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pulsing Worker Pin
          Positioned(
            top: 60,
            left: 70,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 44 + (16 * _pulseController.value),
                      height: 44 + (16 * _pulseController.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandPrimary.withValues(
                          alpha: 0.35 * (1 - _pulseController.value),
                        ),
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.brandPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.two_wheeler_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Destination Pin (User House)
          Positioned(
            bottom: 45,
            right: 80,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.home_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final bool isDark;

  _MapCanvasPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF263342) : Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final minorRoadPaint = Paint()
      ..color = isDark ? const Color(0xFF1D2835) : const Color(0xFFF3F7FA)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    // Minor grid roads
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.25),
      minorRoadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width, size.height * 0.75),
      minorRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.35, size.height),
      minorRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      minorRoadPaint,
    );

    // Main road
    final mainRoad = Path()
      ..moveTo(0, size.height * 0.45)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.35,
        size.width * 0.5,
        size.height * 0.65,
        size.width,
        size.height * 0.55,
      );
    canvas.drawPath(mainRoad, roadPaint);

    // Route connection path (worker to home)
    final routePaint = Paint()
      ..color = AppColors.brandPrimary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final routePath = Path()
      ..moveTo(90, 80)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.4,
        size.width - 90,
        size.height - 55,
      );

    canvas.drawPath(routePath, routePaint);
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _WorkerInfoCard extends ConsumerWidget {
  final String? workerId;
  final String serviceName;

  const _WorkerInfoCard({required this.workerId, required this.serviceName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    final workerAsync = workerId == null
        ? null
        : ref.watch(workerByIdProvider(workerId!));
    final worker = workerAsync?.whenOrNull(data: (value) => value);

    if (workerAsync?.isLoading ?? false) {
      return const KayloCard(child: Center(child: KayloLoader(size: 28)));
    }

    if (workerAsync?.hasError ?? false) {
      return KayloCard(
        child: Text(
          'Your verified professional will be assigned shortly.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    if (worker == null) {
      return KayloCard(
        child: Text(
          'A verified professional will be assigned shortly.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return KayloCard(
      child: Column(
        children: [
          Row(
            children: [
              AvatarCircle(
                imageUrl: worker.profileImageUrl,
                fallbackText: worker.name,
                radius: 28,
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          worker.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (worker.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.brandPrimary,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Assigned Professional • $serviceName',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: secondary),
                    ),
                    const SizedBox(height: 2),
                    RatingStars(
                      rating: worker.rating,
                      reviewCount: worker.reviewsCount,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    KayloFeedback.press();
                    KayloSnackbar.showInfo(
                      context,
                      'Calling ${worker.name} (+91 9847012345)…',
                    );
                  },
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    KayloFeedback.press();
                    context.push(Routes.chat(worker.id));
                  },
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: const Text('Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final BookingStatus status;

  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        title: 'Booking Confirmed',
        subtitle: 'Order received and scheduled',
        isDone: true,
      ),
      (
        title: 'Worker Assigned',
        subtitle: 'Professional notified of address',
        isDone: status != BookingStatus.pending,
      ),
      (
        title: 'On the Way',
        subtitle: 'Worker is traveling to your location',
        isDone:
            status == BookingStatus.inProgress ||
            status == BookingStatus.completed,
      ),
      (
        title: 'Service Completed',
        subtitle: 'Work verified and approved',
        isDone: status == BookingStatus.completed,
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _TimelineStepRow(
            title: steps[i].title,
            subtitle: steps[i].subtitle,
            isDone: steps[i].isDone,
            isCurrent:
                (i == 2 && status == BookingStatus.onWay) ||
                (i == 3 && status == BookingStatus.inProgress),
            isLast: i == steps.length - 1,
          ),
        ],
      ],
    );
  }
}

class _TimelineStepRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const _TimelineStepRow({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    final color = isDone
        ? AppColors.brandPrimary
        : (isCurrent
              ? AppColors.secondaryAccent
              : (isDark ? Colors.grey[700]! : Colors.grey[300]!));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.brandPrimary
                    : (isCurrent
                          ? AppColors.secondaryAccent.withValues(alpha: 0.2)
                          : Colors.transparent),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : (isCurrent
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.secondaryAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isDone ? AppColors.brandPrimary : Colors.grey[400],
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: isDone || isCurrent
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: secondary),
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
