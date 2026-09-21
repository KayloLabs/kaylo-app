import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/kaylo_loader.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';
import '../../../../core/widgets/kaylo_text_field.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/care_providers.dart';
import '../../domain/care_models.dart';
import '../widgets/care_scaffold.dart';

class MedicineRemindersScreen extends ConsumerWidget {
  const MedicineRemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reminders = ref.watch(medicineRemindersProvider);

    return CareScaffold(
      title: l10n.medicineReminders,
      children: [
        Text(l10n.todaysMedicines,
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: AppSpacing.s),
        Text(
          l10n.medicinesSubtitle,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        ...reminders.when(
          data: (list) {
            final pending = list.where((r) => !r.isTakenToday).toList();
            final now = TimeOfDay.now();
            final nowMinutes = now.hour * 60 + now.minute;
            final next = pending
                    .where((r) => r.minutesOfDay >= nowMinutes)
                    .firstOrNull ??
                pending.firstOrNull;
            return [
              _SummaryBanner(pendingCount: pending.length, next: next),
              const SizedBox(height: AppSpacing.xl),
              if (list.isEmpty)
                EmptyState(
                  title: l10n.noRemindersTitle,
                  description: l10n.noRemindersDescription,
                  icon: Icons.alarm_rounded,
                )
              else
                for (final reminder in list) ...[
                  _ReminderCard(reminder: reminder),
                  const SizedBox(height: AppSpacing.m),
                ],
              const SizedBox(height: AppSpacing.l),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addReminder),
                onPressed: () {
                  KayloFeedback.tap();
                  showCareSheet(context, const _AddReminderSheet());
                },
              ),
            ];
          },
          loading: () => const [
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxxl),
              child: Center(child: KayloLoader()),
            ),
          ],
          error: (error, _) => [
            ErrorState(
              title: l10n.somethingWentWrong,
              message: error.toString(),
              onRetry: () => ref.invalidate(medicineRemindersProvider),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final int pendingCount;
  final MedicineReminder? next;

  const _SummaryBanner({required this.pendingCount, required this.next});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loc = MaterialLocalizations.of(context);
    final allDone = pendingCount == 0;
    final color = allDone ? AppColors.brandPrimaryDark : AppColors.careAccent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            allDone ? Icons.task_alt_rounded : Icons.medication_rounded,
            color: color,
            size: 36,
          ),
          const SizedBox(width: AppSpacing.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.pendingDoses(pendingCount),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (next != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.nextDose(
                      next!.name,
                      loc.formatTimeOfDay(
                        TimeOfDay(hour: next!.hour, minute: next!.minute),
                      ),
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  final MedicineReminder reminder;

  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final loc = MaterialLocalizations.of(context);
    final taken = reminder.isTakenToday;
    final time = loc.formatTimeOfDay(
      TimeOfDay(hour: reminder.hour, minute: reminder.minute),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Row(
          children: [
            Material(
              color: taken
                  ? AppColors.brandPrimaryDark
                  : AppColors.careAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  KayloFeedback.tap();
                  await ref
                      .read(careControllerProvider)
                      .setReminderTaken(reminder.id, !taken);
                  if (!context.mounted) return;
                  if (taken) {
                    KayloSnackbar.showInfo(
                        context, l10n.markedPending(reminder.name));
                  } else {
                    KayloSnackbar.showSuccess(
                        context, l10n.markedTaken(reminder.name));
                  }
                },
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    taken
                        ? Icons.check_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: taken ? Colors.white : AppColors.careAccent,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          decoration: taken ? TextDecoration.lineThrough : null,
                          color: taken ? AppColors.textSecondary : null,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    reminder.dosage,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _Pill(icon: Icons.schedule_rounded, text: time),
                      if (reminder.addedBy != null)
                        _Pill(
                          icon: Icons.person_rounded,
                          text: l10n.addedBy(reminder.addedBy!),
                          color: AppColors.homeAccent,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Pill({
    required this.icon,
    required this.text,
    this.color = AppColors.careAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddReminderSheet extends ConsumerStatefulWidget {
  const _AddReminderSheet();

  @override
  ConsumerState<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<_AddReminderSheet> {
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    if (name.isEmpty) {
      KayloSnackbar.showError(context, l10n.nameRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(careControllerProvider).addReminder(
            name: name,
            dosage: _dosage.text.trim(),
            hour: _time.hour,
            minute: _time.minute,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.addReminder,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.l),
          KayloTextField(
            label: l10n.medicineName,
            hintText: l10n.medicineNameHint,
            controller: _name,
          ),
          const SizedBox(height: AppSpacing.m),
          KayloTextField(
            label: l10n.dosage,
            hintText: l10n.dosageHint,
            controller: _dosage,
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            l10n.reminderTime,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s),
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (picked != null) setState(() => _time = picked);
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Row(
                  children: [
                    const Icon(Icons.alarm_rounded, color: AppColors.careAccent),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Text(
                        loc.formatTimeOfDay(_time),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      l10n.change,
                      style: const TextStyle(
                        color: AppColors.brandPrimaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.save),
          ),
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
