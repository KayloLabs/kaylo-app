import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/service_item.dart';
import '../../../../core/models/worker.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/kaylo_loader.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';
import '../../../../core/widgets/price_tag.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../home/application/home_providers.dart';
import '../../../workers/application/workers_providers.dart';
import '../../domain/booking_draft.dart';

class BookServiceScreen extends ConsumerStatefulWidget {
  final String serviceId;
  final String? workerId;

  const BookServiceScreen({super.key, required this.serviceId, this.workerId});

  @override
  ConsumerState<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends ConsumerState<BookServiceScreen> {
  late DateTime _selectedDate;
  int _selectedSlotIndex = 0;
  Worker? _selectedWorker;
  bool _photoAttached = false;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  final List<String> _timeSlots = const [
    '09:00 AM - 12:00 PM',
    '01:00 PM - 04:00 PM',
    '04:00 PM - 07:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _addressController = TextEditingController(
      text: 'Thekkedath House, Kaloor, Kochi',
    );
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onProceed(ServiceItem service) {
    final l10n = AppLocalizations.of(context)!;
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      KayloFeedback.alert();
      KayloSnackbar.showError(context, l10n.addressRequired);
      return;
    }

    KayloFeedback.press();
    const double platformFee = 50.0;
    final total = service.basePrice + platformFee;

    final draft = BookingDraft(
      service: service,
      worker: _selectedWorker,
      date: _selectedDate,
      timeSlot: _timeSlots[_selectedSlotIndex],
      address: address,
      notes: _notesController.text.trim(),
      total: total,
    );

    context.push(Routes.bookPayment(service.id), extra: draft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    final catalogAsync = ref.watch(fullCatalogProvider);

    return catalogAsync.when(
      data: (catalog) {
        final service = catalog
            .where((s) => s.id == widget.serviceId)
            .firstOrNull;
        if (service == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.bookAService)),
            body: ErrorState(
              title: l10n.somethingWentWrong,
              message: 'Service with ID ${widget.serviceId} not found.',
              onRetry: () => ref.invalidate(fullCatalogProvider),
            ),
          );
        }

        final workersAsync = ref.watch(
          workersByServiceProvider(widget.serviceId),
        );

        return Scaffold(
          appBar: AppBar(title: Text('${l10n.bookAService}: ${service.name}')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.s,
              AppSpacing.l,
              AppSpacing.xxl,
            ),
            children: [
              // Service Quick Card
              KayloCard(
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.asset(service.iconPath, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            service.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: secondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    PriceTag(amount: service.basePrice),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Worker Selection
              SectionHeader(title: 'Choose Professional'),
              const SizedBox(height: AppSpacing.s),
              workersAsync.when(
                data: (workers) {
                  if (workers.isEmpty) {
                    return KayloCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            color: AppColors.brandPrimary,
                            size: 28,
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Text(
                              'Auto-assigned best verified professional',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Default selected worker if not selected yet
                  _selectedWorker ??= widget.workerId == null
                      ? workers.first
                      : workers.firstWhere(
                          (worker) => worker.id == widget.workerId,
                          orElse: () => workers.first,
                        );

                  return Column(
                    children: [
                      for (final worker in workers) ...[
                        _WorkerSelectTile(
                          worker: worker,
                          isSelected: _selectedWorker?.id == worker.id,
                          onSelect: () {
                            KayloFeedback.tap();
                            setState(() => _selectedWorker = worker);
                          },
                        ),
                        const SizedBox(height: AppSpacing.s),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.m),
                    child: KayloLoader(size: 28),
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Date Selector
              SectionHeader(title: l10n.selectDate),
              const SizedBox(height: AppSpacing.s),
              _DateSelector(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  KayloFeedback.tap();
                  setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Time Slot Selector
              SectionHeader(title: l10n.selectTimeSlot),
              const SizedBox(height: AppSpacing.s),
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  for (int i = 0; i < _timeSlots.length; i++)
                    ChoiceChip(
                      label: Text(_timeSlots[i]),
                      selected: _selectedSlotIndex == i,
                      onSelected: (selected) {
                        if (selected) {
                          KayloFeedback.tap();
                          setState(() => _selectedSlotIndex = i);
                        }
                      },
                      selectedColor: AppColors.brandPrimary.withValues(
                        alpha: 0.2,
                      ),
                      side: BorderSide(
                        color: _selectedSlotIndex == i
                            ? AppColors.brandPrimary
                            : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.border),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Address Field
              SectionHeader(title: 'Service Address'),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Enter your house name, street, locality',
                  prefixIcon: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.brandPrimary,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Problem Notes
              SectionHeader(title: 'Describe Issue (Optional)'),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'e.g., Kitchen sink pipe is leaking from the joint…',
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // Photo Attachment Mock
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    KayloFeedback.tap();
                    setState(() => _photoAttached = !_photoAttached);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.s,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _photoAttached
                            ? AppColors.brandPrimary
                            : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.border),
                      ),
                      borderRadius: BorderRadius.circular(14),
                      color: _photoAttached
                          ? AppColors.brandPrimary.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _photoAttached
                              ? Icons.check_circle_rounded
                              : Icons.add_a_photo_outlined,
                          size: 20,
                          color: _photoAttached
                              ? AppColors.brandPrimary
                              : secondary,
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          _photoAttached
                              ? '1 Photo Attached of Problem'
                              : 'Add photo of problem (Optional)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _photoAttached
                                    ? AppColors.brandPrimary
                                    : secondary,
                                fontWeight: _photoAttached
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Price Breakdown
              SectionHeader(title: 'Price Details'),
              const SizedBox(height: AppSpacing.s),
              KayloCard(
                child: Column(
                  children: [
                    _PriceRow(
                      label: 'Base Service Charge',
                      value: formatRupees(service.basePrice),
                    ),
                    const _PriceRow(
                      label: 'Safety & Inspection Fee',
                      value: '₹50',
                    ),
                    const Divider(height: AppSpacing.m),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.totalPayable,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        PriceTag(amount: service.basePrice + 50, isLarge: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.s,
              AppSpacing.l,
              AppSpacing.l,
            ),
            child: KayloButton(
              text: l10n.continueToPayment,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => _onProceed(service),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.bookAService)),
        body: const Center(child: KayloLoader(size: 36)),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.bookAService)),
        body: ErrorState(
          title: l10n.somethingWentWrong,
          message: err.toString(),
          onRetry: () => ref.invalidate(fullCatalogProvider),
        ),
      ),
    );
  }
}

class _WorkerSelectTile extends StatelessWidget {
  final Worker worker;
  final bool isSelected;
  final VoidCallback onSelect;

  const _WorkerSelectTile({
    required this.worker,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return KayloCard(
      onTap: onSelect,
      child: Row(
        children: [
          AvatarCircle(
            imageUrl: worker.profileImageUrl,
            fallbackText: worker.name,
            radius: 24,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    RatingStars(
                      rating: worker.rating,
                      reviewCount: worker.reviewsCount,
                      size: 14,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      '• ${worker.totalJobs} jobs',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            isSelected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: isSelected ? AppColors.brandPrimary : Colors.grey,
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.add(Duration(days: i)));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected =
              day.year == selectedDate.year &&
              day.month == selectedDate.month &&
              day.day == selectedDate.day;

          final dayName = index == 0
              ? 'Today'
              : index == 1
              ? 'Tomorrow'
              : _weekdayShort(day.weekday);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: () => onDateSelected(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 68,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandPrimary
                      : (isDark ? AppColors.surfaceDark : AppColors.surface),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandPrimary
                        : (isDark ? AppColors.borderDark : AppColors.border),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary),
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _weekdayShort(int weekday) => switch (weekday) {
    1 => 'Mon',
    2 => 'Tue',
    3 => 'Wed',
    4 => 'Thu',
    5 => 'Fri',
    6 => 'Sat',
    _ => 'Sun',
  };
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;

  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: secondary),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
