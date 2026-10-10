import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/network/app_failure.dart';
import 'package:kaylo_core/utils/money.dart';
import '../../../offers/domain/kaylo_offer.dart';
import '../../../offers/presentation/offers_screen.dart';
import 'package:intl/intl.dart';
import '../../application/care_checkout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../application/care_providers.dart';
import '../../domain/models/caregiver.dart';
import '../../../home/application/user_location_provider.dart';
import '../../../home/presentation/widgets/saved_location_chooser.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';

class CaregiverBookingScreen extends ConsumerStatefulWidget {
  const CaregiverBookingScreen({super.key});

  @override
  ConsumerState<CaregiverBookingScreen> createState() =>
      _CaregiverBookingScreenState();
}

class _CaregiverBookingScreenState
    extends ConsumerState<CaregiverBookingScreen> {
  final _checkout = CareCheckout();
  KayloOffer? _offer;
  double get _discount =>
      _offer?.savings(_calculateTotal(), category: 'care') ?? 0;
  double get _payable => _calculateTotal() - _discount;
  final _address = TextEditingController();
  UserLocation? _visitLocation;

  @override
  void initState() {
    super.initState();
    final current = ref.read(userLocationProvider);
    if (!current.isFallback) {
      _visitLocation = current;
      _address.text = current.fullAddress;
    }
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  bool _paying = false;
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

    return PopScope(
      canPop: !_paying,
      child: Theme(
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
                          showCheckmark: false,
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
                                                      color:
                                                          AppColors.careAccent,
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
                                                  color:
                                                      AppColors.textSecondary,
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
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.s,
                      children: _hourOptions.map((hrs) {
                        final isSelected = _selectedHours == hrs;
                        return OutlinedButton(
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
                              horizontal: AppSpacing.m,
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
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.s,
                      children: [
                        _buildDateChip(
                          'Tomorrow',
                          DateTime.now().add(const Duration(days: 1)),
                        ),
                        _buildDateChip(
                          'In 2 Days',
                          DateTime.now().add(const Duration(days: 2)),
                        ),
                        _buildDateChip(
                          'In 3 Days',
                          DateTime.now().add(const Duration(days: 3)),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    KayloTextField(
                      label: l10n.serviceAddress,
                      hintText: l10n.farmAddressHint,
                      controller: _address,
                      prefixIcon: const Icon(Icons.place_outlined),
                      onChanged: (_) => setState(() => _visitLocation = null),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.map_outlined),
                        label: Text(l10n.chooseAddress),
                        onPressed: _paying
                            ? null
                            : () async {
                                final chosen = await showSavedLocationChooser(
                                  context,
                                  initialLocation: _visitLocation,
                                );
                                if (chosen == null || !mounted) return;
                                setState(() {
                                  _visitLocation = chosen;
                                  _address.text = chosen.fullAddress;
                                });
                              },
                      ),
                    ),

                    // Total & Book Button
                    const SizedBox(height: AppSpacing.xxl),
                    _buildTotalCard(l10n),
                    const SizedBox(height: AppSpacing.l),
                    OfferSelector(
                      subtotal: _calculateTotal(),
                      category: 'care',
                      selected: _offer,
                      enabled: !_paying && !_checkout.hasStartedPayment,
                      onChanged: (offer) => setState(() => _offer = offer),
                    ),
                    const SizedBox(height: AppSpacing.l),

                    KayloButton(
                      text: _paying
                          ? l10n.openingPayment
                          : '${l10n.payAndBook} • ${formatRupees(_payable)}',
                      icon: Icons.check_circle_rounded,
                      onPressed: _paying || _selectedCaregiver == null
                          ? null
                          : () async {
                              if (_address.text.trim().isEmpty) {
                                KayloSnackbar.showError(
                                  context,
                                  l10n.serviceAddressRequired,
                                );
                                return;
                              }
                              KayloFeedback.press();
                              final caregiver = _selectedCaregiver!;

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
                                totalAmount: _payable,
                                careType: _selectedCareType,
                                notes:
                                    _visitLocation?.bookingNotes ??
                                    _address.text.trim(),
                                status: 'confirmed',
                              );

                              setState(() => _paying = true);
                              try {
                                await _checkout.pay(
                                  ref,
                                  kind: 'caregiver',
                                  mockAmount: total,
                                  offerCode:
                                      _offer?.appliesTo(
                                            total,
                                            category: 'care',
                                          ) ==
                                          true
                                      ? _offer!.code
                                      : null,
                                  details: {
                                    'provider_id': caregiver.id,
                                    'date': DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(_selectedDate),
                                    'time': '09:00',
                                    'time_slot': '09:00 AM',
                                    'hours': _selectedHours,
                                    'care_type': _selectedCareType,
                                    'notes': record.notes,
                                    'location_id':
                                        _visitLocation?.savedAddressId,
                                  },
                                );
                                if (useMockData) {
                                  await ref
                                      .read(caregiverBookingsProvider.notifier)
                                      .bookCaregiver(
                                        record.withBooking(_checkout.bookingId),
                                      );
                                }
                              } catch (error) {
                                if (!context.mounted) return;
                                KayloSnackbar.showError(
                                  context,
                                  error is AppFailure
                                      ? error.message
                                      : error is StateError
                                      ? error.message.toString()
                                      : l10n.visitPaymentFailed,
                                );
                                return;
                              } finally {
                                if (mounted) setState(() => _paying = false);
                              }

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

    return OutlinedButton(
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
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.m,
          horizontal: AppSpacing.l,
        ),
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
              color: isSelected ? AppColors.careAccent : AppColors.textPrimary,
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
                Expanded(
                  child: Text(
                    '${_selectedCaregiver?.name ?? "Caregiver"} ($rate/hr × $_selectedHours hrs)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
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
            if (_discount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.m),
                child: Row(
                  children: [
                    Expanded(child: Text('Offer • ${_offer!.code}')),
                    Text(
                      '−${formatRupees(_discount)}',
                      style: const TextStyle(
                        color: AppColors.careAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.totalAmount,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  formatRupees(_payable),
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
