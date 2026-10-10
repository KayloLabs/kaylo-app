import 'package:flutter/foundation.dart';

/// One weekday's window. [weekday] is ISO: 1 = Monday, 7 = Sunday, the
/// same numbering as `worker_weekly_hours.weekday`.
@immutable
class DayHours {
  final int weekday;
  final bool works;
  final int startMinutes;
  final int endMinutes;

  const DayHours({
    required this.weekday,
    this.works = true,
    this.startMinutes = 8 * 60,
    this.endMinutes = 19 * 60,
  });

  /// Monday to Saturday 8:00 to 19:00, Sunday off: what a new worker sees
  /// before they change anything.
  factory DayHours.defaultFor(int weekday) =>
      DayHours(weekday: weekday, works: weekday != DateTime.sunday);

  bool get isValid => !works || endMinutes > startMinutes;

  DayHours copyWith({bool? works, int? startMinutes, int? endMinutes}) {
    return DayHours(
      weekday: weekday,
      works: works ?? this.works,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
    );
  }

  factory DayHours.fromJson(Map<String, dynamic> json) => DayHours(
    weekday: (json['weekday'] as num).toInt(),
    works: (json['works'] as bool?) ?? true,
    startMinutes: _minutesOf(json['start_time']),
    endMinutes: _minutesOf(json['end_time']),
  );

  Map<String, dynamic> toJson() => {
    'weekday': weekday,
    'works': works,
    'start_time': _timeString(startMinutes),
    'end_time': _timeString(endMinutes),
  };

  /// '08:00:00' or '08:00' -> 480.
  static int _minutesOf(Object? time) {
    final parts = time.toString().split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _timeString(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  bool operator ==(Object other) =>
      other is DayHours &&
      other.weekday == weekday &&
      other.works == works &&
      other.startMinutes == startMinutes &&
      other.endMinutes == endMinutes;

  @override
  int get hashCode => Object.hash(weekday, works, startMinutes, endMinutes);
}

/// All seven days, Monday first.
@immutable
class WeeklyHours {
  final List<DayHours> days;

  WeeklyHours(List<DayHours> days)
    : days = List.unmodifiable([for (var d = 1; d <= 7; d++) _dayOf(days, d)]);

  factory WeeklyHours.defaults() =>
      WeeklyHours([for (var d = 1; d <= 7; d++) DayHours.defaultFor(d)]);

  static DayHours _dayOf(List<DayHours> days, int weekday) {
    for (final day in days) {
      if (day.weekday == weekday) return day;
    }
    return DayHours.defaultFor(weekday);
  }

  DayHours operator [](int weekday) => days[weekday - 1];

  WeeklyHours withDay(DayHours day) =>
      WeeklyHours([for (final d in days) d.weekday == day.weekday ? day : d]);

  bool get isValid => days.every((d) => d.isValid);
  List<DayHours> get workingDays => [
    for (final d in days)
      if (d.works) d,
  ];

  /// True when every working day shares one window, so the schedule can be
  /// summarised on one line.
  bool get hasOneWindow {
    final working = workingDays;
    if (working.isEmpty) return true;
    return working.every(
      (d) =>
          d.startMinutes == working.first.startMinutes &&
          d.endMinutes == working.first.endMinutes,
    );
  }

  factory WeeklyHours.fromJson(List<dynamic> json) => WeeklyHours([
    for (final d in json)
      DayHours.fromJson(Map<String, dynamic>.from(d as Map)),
  ]);

  List<Map<String, dynamic>> toJson() => [for (final d in days) d.toJson()];

  @override
  bool operator ==(Object other) =>
      other is WeeklyHours && listEquals(other.days, days);

  @override
  int get hashCode => Object.hashAll(days);
}

/// A run of days the worker is not taking jobs.
@immutable
class TimeOff {
  final String id;
  final DateTime startsOn;
  final DateTime endsOn;
  final String? reason;

  const TimeOff({
    required this.id,
    required this.startsOn,
    required this.endsOn,
    this.reason,
  });

  int get dayCount => endsOn.difference(startsOn).inDays + 1;

  bool covers(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(startsOn) && !d.isAfter(endsOn);
  }

  factory TimeOff.fromJson(Map<String, dynamic> json) => TimeOff(
    id: json['time_off_id'] as String,
    startsOn: DateTime.parse(json['starts_on'] as String),
    endsOn: DateTime.parse(json['ends_on'] as String),
    reason: json['reason'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'time_off_id': id,
    'starts_on': dateString(startsOn),
    'ends_on': dateString(endsOn),
    'reason': reason,
  };

  static String dateString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

abstract class AvailabilityRepository {
  /// The saved hours, then every change; null until the worker saves any.
  Stream<WeeklyHours?> watchWeeklyHours();
  Future<void> saveWeeklyHours(WeeklyHours hours);

  /// Current and upcoming days off, earliest first.
  Stream<List<TimeOff>> watchTimeOff();
  Future<TimeOff> addTimeOff({
    required DateTime startsOn,
    required DateTime endsOn,
    String? reason,
  });
  Future<void> removeTimeOff(String id);
  void dispose();
}
