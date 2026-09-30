import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';
import 'package:kaylo_core/models/app_user.dart';
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
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';
import 'package:kaylo_ui/widgets/rating_stars.dart';
import 'package:kaylo_ui/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/current_user_provider.dart';
import '../../application/care_providers.dart';
import '../../domain/models/appointment.dart';
import '../../domain/models/doctor.dart';

class DoctorAppointmentScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentScreen> createState() =>
      _DoctorAppointmentScreenState();
}

class _DoctorAppointmentScreenState
    extends ConsumerState<DoctorAppointmentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _patientController;
  late final TextEditingController _notesController;

  String? _selectedSpecialty;
  Doctor? _selectedDoctor;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  String _consultationType = 'homeVisit'; // 'homeVisit' | 'teleconsult'

  final List<String> _specialties = [
    'All',
    'General Physician',
    'Cardiologist',
    'Orthopedic',
    'Geriatrician',
    'Ayurvedic',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final user = ref.read(currentUserProvider);
    _patientController = TextEditingController(text: user?.fullName ?? '');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _patientController.dispose();
    _notesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _specialtyLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'General Physician':
        return l10n.specGeneral;
      case 'Cardiologist':
        return l10n.specCardio;
      case 'Orthopedic':
        return l10n.specOrtho;
      case 'Geriatrician':
        return l10n.specGeriatric;
      case 'Ayurvedic':
        return l10n.specAyurveda;
      default:
        return key;
    }
  }

  String _formatDateChip(DateTime date, BuildContext context) {
    try {
      return DateFormat.MMMEd(Localizations.localeOf(context).toString()).format(date);
    } catch (_) {
      return DateFormat.MMMEd('en').format(date);
    }
  }

  String _formatUpcomingDate(DateTime date, BuildContext context) {
    try {
      return DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date);
    } catch (_) {
      return DateFormat.yMMMd('en').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen<AppUser?>(currentUserProvider, (_, next) {
      if (_patientController.text.isEmpty &&
          next?.fullName != null &&
          next!.fullName.isNotEmpty) {
        _patientController.text = next.fullName;
      }
    });

    return Theme(
      data: AppTheme.careTheme,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: Text(
                l10n.doctorAppointment,
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
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.careAccent,
                labelColor: AppColors.careAccent,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                tabs: [
                  Tab(text: l10n.bookNow),
                  Tab(text: l10n.upcomingAppointments),
                ],
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingTab(context, l10n),
                _buildUpcomingTab(context, l10n),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingTab(BuildContext context, AppLocalizations l10n) {
    final specialtyQuery = _selectedSpecialty == 'All'
        ? null
        : _selectedSpecialty;
    final doctorsAsync = ref.watch(doctorsListProvider(specialtyQuery));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: [
        // Specialty Selector
        Text(
          l10n.selectSpecialty,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _specialties.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s),
            itemBuilder: (context, index) {
              final spec = _specialties[index];
              final isSelected =
                  (_selectedSpecialty == null && spec == 'All') ||
                  _selectedSpecialty == spec;
              return ChoiceChip(
                label: Text(spec == 'All' ? spec : _specialtyLabel(spec, l10n)),
                selected: isSelected,
                onSelected: (selected) {
                  KayloFeedback.tap();
                  setState(() {
                    _selectedSpecialty = spec == 'All'
                        ? null
                        : (selected ? spec : null);
                    _selectedDoctor = null;
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Available Doctors Section
        Text(
          l10n.availableDoctors,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: AppSpacing.m),

        doctorsAsync.when(
          data: (doctors) {
            if (doctors.isEmpty) {
              return EmptyState(
                title: l10n.noResultsFound,
                description: l10n.tryDifferentSearch,
              );
            }

            return Column(
              children: doctors.map((doc) {
                final isSelected = _selectedDoctor?.id == doc.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.m),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.careAccent
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      onTap: () {
                        KayloFeedback.tap();
                        setState(() {
                          _selectedDoctor = doc;
                          _selectedTimeSlot = null;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.l),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AvatarCircle(
                              imageUrl: doc.imageUrl,
                              fallbackText: doc.name,
                              radius: 30,
                            ),
                            const SizedBox(width: AppSpacing.l),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_specialtyLabel(doc.specialty, l10n)} • ${doc.hospital}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  RatingStars(
                                    rating: doc.rating,
                                    reviewCount: doc.reviewsCount,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${l10n.consultationFee}: ₹${doc.consultationFee.toInt()}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.careAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
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
          loading: () => const ShimmerBox(width: double.infinity, height: 140),
          error: (err, stack) => ErrorState(
            message: err.toString(),
            onRetry: () => ref.invalidate(doctorsListProvider(specialtyQuery)),
          ),
        ),

        // Date & Time Selector if doctor selected
        if (_selectedDoctor != null) ...[
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
                label: l10n.tomorrow,
                date: DateTime.now().add(const Duration(days: 1)),
              ),
              const SizedBox(width: AppSpacing.s),
              _buildDateChip(
                label: l10n.inDays(2),
                date: DateTime.now().add(const Duration(days: 2)),
              ),
              const SizedBox(width: AppSpacing.s),
              _buildDateChip(
                label: l10n.inDays(3),
                date: DateTime.now().add(const Duration(days: 3)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          Text(
            l10n.selectTimeSlot,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: _selectedDoctor!.timeSlots.map((slot) {
              final isSelected = _selectedTimeSlot == slot;
              return ChoiceChip(
                label: Text(slot),
                selected: isSelected,
                onSelected: (selected) {
                  KayloFeedback.tap();
                  setState(() {
                    _selectedTimeSlot = selected ? slot : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Consultation Type
          Text(
            l10n.consultationType,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              Expanded(
                child: _buildConsultationTypeCard(
                  title: l10n.homeVisit,
                  icon: Icons.home_rounded,
                  type: 'homeVisit',
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: _buildConsultationTypeCard(
                  title: l10n.teleconsult,
                  icon: Icons.video_camera_front_rounded,
                  type: 'teleconsult',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Who is it for? & Notes
          KayloTextField(
            label: l10n.whoIsItFor,
            controller: _patientController,
          ),
          const SizedBox(height: AppSpacing.l),
          KayloTextField(
            label: l10n.appointmentNotes,
            controller: _notesController,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Confirm & Book Button
          KayloButton(
            text:
                '${l10n.confirmAppointment} (₹${_selectedDoctor!.consultationFee.toInt()})',
            icon: Icons.check_circle_rounded,
            onPressed: (_selectedDoctor != null && _selectedTimeSlot != null)
                ? () async {
                    KayloFeedback.press();
                    final user = ref.read(currentUserProvider);
                    final patient = _patientController.text.trim().isNotEmpty
                        ? _patientController.text.trim()
                        : (user?.fullName ?? '');
                    final notes = _notesController.text.trim().isNotEmpty
                        ? _notesController.text.trim()
                        : null;

                    final appointment = DoctorAppointment(
                      id: 'apt_${DateTime.now().millisecondsSinceEpoch}',
                      doctorId: _selectedDoctor!.id,
                      doctorName: _selectedDoctor!.name,
                      specialty: _selectedDoctor!.specialty,
                      hospital: _selectedDoctor!.hospital,
                      date: _selectedDate,
                      timeSlot: _selectedTimeSlot!,
                      consultationType: _consultationType,
                      status: 'confirmed',
                      patientName: patient,
                      notes: notes,
                    );

                    await ref
                        .read(doctorAppointmentsProvider.notifier)
                        .bookAppointment(appointment);

                    if (!context.mounted) return;

                    KayloSnackbar.showSuccess(
                      context,
                      l10n.appointmentConfirmedWith(_selectedDoctor!.name),
                    );
                    _tabController.animateTo(1);
                  }
                : null,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ],
    );
  }

  Widget _buildDateChip({required String label, required DateTime date}) {
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
            color: isSelected ? AppColors.careAccent : AppColors.border,
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
            const SizedBox(height: 2),
            Text(
              _formatDateChip(date, context),
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

  Widget _buildConsultationTypeCard({
    required String title,
    required IconData icon,
    required String type,
  }) {
    final isSelected = _consultationType == type;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: isSelected ? AppColors.careAccent : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () {
          KayloFeedback.tap();
          setState(() {
            _consultationType = type;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected
                    ? AppColors.careAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isSelected
                      ? AppColors.careAccent
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTab(BuildContext context, AppLocalizations l10n) {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider);

    return appointmentsAsync.when(
      data: (appointments) {
        if (appointments.isEmpty) {
          return EmptyState(
            title: l10n.noResultsFound,
            description: l10n.noUpcomingAppointments,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.l),
          itemCount: appointments.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
          itemBuilder: (context, index) {
            final apt = appointments[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'CONFIRMED',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '${_formatUpcomingDate(apt.date, context)} • ${apt.timeSlot}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      apt.doctorName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                    Text(
                      '${_specialtyLabel(apt.specialty, l10n)} • ${apt.hospital}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Row(
                      children: [
                        Icon(
                          apt.consultationType == 'homeVisit'
                              ? Icons.home_rounded
                              : Icons.video_call_rounded,
                          size: 18,
                          color: AppColors.careAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          apt.consultationType == 'homeVisit'
                              ? l10n.homeVisit
                              : l10n.teleconsult,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.careAccent,
                          ),
                        ),
                      ],
                    ),
                    if (apt.notes != null && apt.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        apt.notes!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(doctorAppointmentsProvider),
      ),
    );
  }
}
