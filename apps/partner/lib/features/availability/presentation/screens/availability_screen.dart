import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kaylo_core/network/app_failure.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/section_header.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/availability_providers.dart';
import '../../domain/availability.dart';

/// The worker's weekly hours and days off. Hours are edited in place and
/// saved with one button; days off are saved as they are added.
class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  WeeklyHours? _saved;
  WeeklyHours? _draft;
  bool _saving = false;

  bool get _dirty => _draft != null && _draft != _saved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hoursAsync = ref.watch(weeklyHoursProvider);
    final timeOffAsync = ref.watch(timeOffProvider);

    // The draft starts from what is saved (or the defaults when nothing
    // is), and follows a save made elsewhere unless the worker is mid-edit.
    ref.listen(weeklyHoursProvider, (_, next) {
      final loaded = next.asData?.value;
      if (next is AsyncData) {
        final saved = loaded ?? WeeklyHours.defaults();
        setState(() {
          _saved = loaded;
          if (_draft == null || !_dirty) _draft = saved;
        });
      }
    });
    if (_draft == null && hoursAsync is AsyncData<WeeklyHours?>) {
      _saved = hoursAsync.value;
      _draft = hoursAsync.value ?? WeeklyHours.defaults();
    }

    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.availabilityTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.m,
          AppSpacing.l,
          AppSpacing.xl,
        ),
        children: [
          SectionHeader(title: l10n.workingHoursHeader),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.workingHoursHint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: secondary),
          ),
          const SizedBox(height: AppSpacing.m),
          if (_draft == null)
            hoursAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: KayloLoader(size: 32)),
              ),
              error: (e, _) => Text(
                e is AppFailure ? e.message : '$e',
                style: TextStyle(color: AppColors.error),
              ),
              data: (_) => const SizedBox.shrink(),
            )
          else
            KayloCard(
              child: Column(
                children: [
                  for (final day in _draft!.days) ...[
                    _DayRow(
                      day: day,
                      onChanged: (updated) =>
                          setState(() => _draft = _draft!.withDay(updated)),
                    ),
                    if (day.weekday != 7) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.m),
          KayloButton(
            text: l10n.saveHours,
            icon: Icons.save_outlined,
            isLoading: _saving,
            onPressed: _dirty && !_saving ? _saveHours : null,
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: l10n.daysOffHeader),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.daysOffHint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: secondary),
          ),
          const SizedBox(height: AppSpacing.m),
          timeOffAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.l),
              child: Center(child: KayloLoader(size: 32)),
            ),
            error: (e, _) => Text(
              e is AppFailure ? e.message : '$e',
              style: TextStyle(color: AppColors.error),
            ),
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                    child: Text(
                      l10n.noDaysOff,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: secondary),
                    ),
                  )
                : KayloCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < list.length; i++) ...[
                          _TimeOffRow(
                            entry: list[i],
                            onRemove: () => _removeTimeOff(list[i]),
                          ),
                          if (i < list.length - 1) const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.m),
          KayloButton(
            text: l10n.addDaysOff,
            icon: Icons.event_busy_outlined,
            variant: KayloButtonVariant.outline,
            onPressed: _addTimeOff,
          ),
        ],
      ),
    );
  }

  Future<void> _saveHours() async {
    final l10n = AppLocalizations.of(context)!;
    final draft = _draft!;
    if (!draft.isValid) {
      KayloSnackbar.showError(context, l10n.endAfterStart);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(availabilityRepositoryProvider).saveWeeklyHours(draft);
      if (!mounted) return;
      setState(() => _saved = draft);
      KayloFeedback.press();
      KayloSnackbar.showSuccess(context, l10n.hoursSaved);
    } catch (e) {
      if (!mounted) return;
      KayloSnackbar.showError(context, e is AppFailure ? e.message : '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addTimeOff() async {
    final l10n = AppLocalizations.of(context)!;
    KayloFeedback.tap();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: l10n.addDaysOff.toUpperCase(),
    );
    if (range == null || !mounted) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ReasonDialog(range: range),
    );
    if (reason == null || !mounted) return;
    try {
      await ref
          .read(availabilityRepositoryProvider)
          .addTimeOff(startsOn: range.start, endsOn: range.end, reason: reason);
      if (!mounted) return;
      KayloFeedback.press();
      KayloSnackbar.showSuccess(context, l10n.timeOffAdded);
    } catch (e) {
      if (!mounted) return;
      KayloSnackbar.showError(context, e is AppFailure ? e.message : '$e');
    }
  }

  Future<void> _removeTimeOff(TimeOff entry) async {
    final l10n = AppLocalizations.of(context)!;
    KayloFeedback.tap();
    try {
      await ref.read(availabilityRepositoryProvider).removeTimeOff(entry.id);
      if (!mounted) return;
      KayloSnackbar.showInfo(context, l10n.timeOffRemoved);
    } catch (e) {
      if (!mounted) return;
      KayloSnackbar.showError(context, e is AppFailure ? e.message : '$e');
    }
  }
}

/// Monday to Sunday in the app's language; 1 January 2024 was a Monday.
String weekdayName(BuildContext context, int weekday, {bool short = false}) {
  final locale = Localizations.localeOf(context).toString();
  final date = DateTime(2024, 1, weekday);
  try {
    return (short ? DateFormat.E(locale) : DateFormat.EEEE(locale)).format(
      date,
    );
  } catch (_) {
    return (short ? DateFormat.E('en') : DateFormat.EEEE('en')).format(date);
  }
}

String formatMinutes(BuildContext context, int minutes) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

class _DayRow extends StatelessWidget {
  final DayHours day;
  final ValueChanged<DayHours> onChanged;

  const _DayRow({required this.day, required this.onChanged});

  Future<void> _pick(BuildContext context, {required bool start}) async {
    KayloFeedback.tap();
    final current = start ? day.startMinutes : day.endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    onChanged(
      start
          ? day.copyWith(startMinutes: minutes)
          : day.copyWith(endMinutes: minutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final invalid = !day.isValid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekdayName(context, day.weekday),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (!day.works)
                  Text(
                    l10n.dayOff,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: secondary),
                  )
                else
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.xs,
                    children: [
                      _TimeChip(
                        label: formatMinutes(context, day.startMinutes),
                        onTap: () => _pick(context, start: true),
                      ),
                      Text('–', style: TextStyle(color: secondary)),
                      _TimeChip(
                        label: formatMinutes(context, day.endMinutes),
                        error: invalid,
                        onTap: () => _pick(context, start: false),
                      ),
                    ],
                  ),
                if (invalid)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      l10n.endAfterStart,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            value: day.works,
            activeTrackColor: AppColors.brandPrimary,
            onChanged: (works) {
              KayloFeedback.tap();
              onChanged(day.copyWith(works: works));
            },
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool error;
  final VoidCallback onTap;

  const _TimeChip({
    required this.label,
    required this.onTap,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: error
              ? AppColors.error.withValues(alpha: 0.1)
              : AppColors.brandPrimary.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: error ? AppColors.error : AppColors.brandPrimary,
          ),
        ),
      ),
    );
  }
}

class _TimeOffRow extends StatelessWidget {
  final TimeOff entry;
  final VoidCallback onRemove;

  const _TimeOffRow({required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final locale = Localizations.localeOf(context).toString();
    String day(DateTime d) {
      try {
        return DateFormat.MMMd(locale).format(d);
      } catch (_) {
        return DateFormat.MMMd('en').format(d);
      }
    }

    final when = entry.dayCount == 1
        ? day(entry.startsOn)
        : l10n.dateRange(day(entry.startsOn), day(entry.endsOn));
    final detail = [
      l10n.dayCount(entry.dayCount),
      if ((entry.reason ?? '').isNotEmpty) entry.reason!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: AppColors.farmAccent,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  when,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  detail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: secondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.remove,
            icon: const Icon(Icons.delete_outline_rounded),
            color: secondary,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  final DateTimeRange range;

  const _ReasonDialog({required this.range});

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    String day(DateTime d) {
      try {
        return DateFormat.MMMd(locale).format(d);
      } catch (_) {
        return DateFormat.MMMd('en').format(d);
      }
    }

    final days = widget.range.end.difference(widget.range.start).inDays + 1;
    final title = days == 1
        ? day(widget.range.start)
        : l10n.dateRange(day(widget.range.start), day(widget.range.end));

    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.reasonLabel,
          hintText: l10n.reasonHint,
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.add),
        ),
      ],
    );
  }
}
