import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaylo_core/models/booking.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_radius.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/theme/app_theme.dart';
import 'package:kaylo_ui/widgets/avatar_circle.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import 'package:kaylo_ui/widgets/error_state.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/rating_stars.dart';
import 'package:kaylo_ui/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../booking/application/bookings_providers.dart';
import '../../application/care_providers.dart';
import '../../domain/models/caregiver.dart';

class CaregiverBookingScreen extends ConsumerStatefulWidget {
  const CaregiverBookingScreen({super.key});

  @override
  ConsumerState<CaregiverBookingScreen> createState() =>
      _CaregiverBookingScreenState();
}

class _CaregiverBookingScreenState
    extends ConsumerState<CaregiverBookingScreen> {
  Caregiver? _selectedCaregiver;
  int _selectedHours = 4;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedCareType = 'Elderly Care';

  final List<int> _hourOptions = [2, 4, 8, 12, 24];

  final List<String> _careTypes = [
    'Elderly Care',
    'Post-operative Care',
    'Companionship',
    'Mobility Assistance',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final caregiversAsync = ref.watch(caregiversListProvider);

    return Theme(
      data: AppTheme.careTheme,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: Text(
                l10n.caregiverBooking,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () {
                  KayloFeedback.tap();
                  context.pop();
                },
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.l),
                children: [
                  // Care Type Selection
                  Text(
                    l10n.careType,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: _careTypes.map((type) {
                      final isSelected = _selectedCareType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          KayloFeedback.tap();
                          setState(() {
                            if (selected) _selectedCareType = type;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Select Caregiver
                  Text(
                    l10n.selectCaregiver,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  caregiversAsync.when(
                    data: (caregivers) {
                      if (caregivers.isEmpty) {
                        return EmptyState(
                          title: l10n.noResultsFound,
                          description: l10n.tryDifferentSearch,
                        );
                      }

                      return Column(
                        children: caregivers.map((cg) {
                          final isSelected = _selectedCaregiver?.id == cg.id;
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.m,
                            ),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.card,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.careAccent
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.card,
                                ),
                                onTap: () {
                                  KayloFeedback.tap();
                                  setState(() {
                                    _selectedCaregiver = cg;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.l),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AvatarCircle(
                                        imageUrl: cg.imageUrl,
                                        fallbackText: cg.name,
                                        radius: 30,
                                      ),
                                      const SizedBox(width: AppSpacing.l),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    cg.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (cg.isVerified) ...[
                                                  const SizedBox(width: 6),
                                                  const Icon(
                                                    Icons.verified_rounded,
                                                    color: AppColors.careAccent,
                                                    size: 18,
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              cg.specialties.join(' • '),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            RatingStars(
                                              rating: cg.rating,
                                              reviewCount: cg.reviewsCount,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '₹${cg.hourlyRate.toInt()}/hour',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppColors.careAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle_rounded
                                            : Icons
                                                  .radio_button_unchecked_rounded,
                                        color: isSelected
                                            ? AppColors.careAccent
                                            : AppColors.textSecondary,
                                        size: 28,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const ShimmerBox(width: double.infinity, height: 140),
                    error: (err, _) => ErrorState(
                      message: err.toString(),
                      onRetry: () => ref.invalidate(caregiversListProvider),
                    ),
                  ),

                  // Hours Selector
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.selectHours,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: _hourOptions.map((hrs) {
                      final isSelected = _selectedHours == hrs;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? AppColors.careAccent.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.careAccent
                                    : Colors.grey.shade400,
                                width: isSelected ? 2 : 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.button,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.m,
                              ),
                            ),
                            onPressed: () {
                              KayloFeedback.tap();
                              setState(() {
                                _selectedHours = hrs;
                              });
                            },
                            child: Text(
                              '$hrs hrs',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isSelected
                                    ? AppColors.careAccent
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Date Picker
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.selectDate,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: [
                      _buildDateChip(
                        'Tomorrow',
                        DateTime.now().add(const Duration(days: 1)),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      _buildDateChip(
                        'In 2 Days',
                        DateTime.now().add(const Duration(days: 2)),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      _buildDateChip(
                        'In 3 Days',
                        DateTime.now().add(const Duration(days: 3)),
                      ),
                    ],
                  ),

                  // Total & Book Button
                  const SizedBox(height: AppSpacing.xxl),
                  _buildTotalCard(l10n),
                  const SizedBox(height: AppSpacing.l),

                  KayloButton(
                    text: '${l10n.bookNow} • ₹${_calculateTotal().toInt()}',
                    icon: Icons.check_circle_rounded,
                    onPressed: () async {
                      KayloFeedback.press();
                      final caregiver =
                          _selectedCaregiver ??
                          const Caregiver(
                            id: 'cg1',
                            name: 'Mary Varghese',
                            rating: 4.9,
                            reviewsCount: 64,
                            hourlyRate: 250,
                            experienceYears: 7,
                            isVerified: true,
                            imageUrl: '',
                            specialties: ['Elderly Care'],
                            bio: '',
                          );

                      final total = _calculateTotal();

                      // 1. Store to caregiverBookings
                      final record = CaregiverBookingRecord(
                        id: 'cgb_${DateTime.now().millisecondsSinceEpoch}',
                        caregiverId: caregiver.id,
                        caregiverName: caregiver.name,
                        date: _selectedDate,
                        startTime: '09:00 AM',
                        hours: _selectedHours,
                        hourlyRate: caregiver.hourlyRate,
                        totalAmount: total,
                        careType: _selectedCareType,
                        notes: 'Caregiver visit for senior',
                        status: 'confirmed',
                      );

                      await ref
                          .read(caregiverBookingsProvider.notifier)
                          .bookCaregiver(record);

                      // 2. Also register in M4's Bookings repository with category caregiver
                      try {
                        final bookingsRepo = ref.read(
                          bookingsRepositoryProvider,
                        );
                        await bookingsRepo.createBooking(
                          Booking(
                            id: record.id,
                            userId: 'u1',
                            serviceId: '8', // Caregiver Visit service id
                            workerId: caregiver.id,
                            scheduledAt: _selectedDate,
                            status: BookingStatus.confirmed,
                            totalAmount: total,
                            notes: '${record.careType} - ${record.hours} hours',
                          ),
                        );
                      } catch (_) {}

                      if (!context.mounted) return;

                      KayloSnackbar.showSuccess(
                        context,
                        '${l10n.caregiverBooked} ${caregiver.name} scheduled for ${_selectedDate.day}/${_selectedDate.month}',
                      );
                      context.pop();
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _calculateTotal() {
    final rate = _selectedCaregiver?.hourlyRate ?? 250.0;
    return rate * _selectedHours;
  }

  Widget _buildDateChip(String label, DateTime date) {
    final isSelected =
        _selectedDate.day == date.day &&
        _selectedDate.month == date.month &&
        _selectedDate.year == date.year;

    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? AppColors.careAccent.withValues(alpha: 0.15)
              : Colors.transparent,
          side: BorderSide(
            color: isSelected ? AppColors.careAccent : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        ),
        onPressed: () {
          KayloFeedback.tap();
          setState(() {
            _selectedDate = date;
          });
        },
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.careAccent
                    : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            Text(
              '${date.day}/${date.month}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(AppLocalizations l10n) {
    final rate = _selectedCaregiver?.hourlyRate ?? 250.0;
    final total = rate * _selectedHours;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedCaregiver?.name ?? "Caregiver"} ($rate/hr × $_selectedHours hrs)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '₹${total.toInt()}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.totalAmount,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${total.toInt()}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.careAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
