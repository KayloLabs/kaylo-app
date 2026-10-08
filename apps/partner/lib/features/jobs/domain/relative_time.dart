import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Formats a scheduled [DateTime] into a human-friendly relative label
/// such as "in 45 min", "tomorrow 9:00", "today 14:30", or "12 min ago".
String formatRelativeScheduled(
  DateTime scheduledAt,
  AppLocalizations l10n, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final diff = scheduledAt.difference(current);

  final timeStr = DateFormat('H:mm').format(scheduledAt);

  final today = DateTime(current.year, current.month, current.day);
  final targetDay = DateTime(
    scheduledAt.year,
    scheduledAt.month,
    scheduledAt.day,
  );
  final dayDiff = targetDay.difference(today).inDays;

  // Past
  if (scheduledAt.isBefore(current)) {
    final minutesAgo = current.difference(scheduledAt).inMinutes;
    if (minutesAgo < 60) {
      return l10n.timeMinutesAgo(minutesAgo <= 0 ? 1 : minutesAgo);
    }
    if (dayDiff == 0) {
      return l10n.timeToday(timeStr);
    }
    return DateFormat('d MMM, H:mm').format(scheduledAt);
  }

  // Future
  if (diff.inMinutes < 60) {
    return l10n.timeInMinutes(diff.inMinutes <= 0 ? 1 : diff.inMinutes);
  }

  if (dayDiff == 0) {
    if (diff.inHours < 4) {
      return l10n.timeInHours(diff.inHours);
    }
    return l10n.timeToday(timeStr);
  }

  if (dayDiff == 1) {
    return l10n.timeTomorrow(timeStr);
  }

  return DateFormat('d MMM, H:mm').format(scheduledAt);
}
