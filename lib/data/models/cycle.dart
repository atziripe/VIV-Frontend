import 'json.dart';
import 'me.dart';

class MovedDay {
  const MovedDay({
    required this.weekday,
    required this.date,
    required this.isRestDay,
    this.title,
    this.durationMinutes,
  });

  final String weekday;
  final String date;
  final bool isRestDay;
  final String? title;
  final int? durationMinutes;

  factory MovedDay.fromJson(Json j) => MovedDay(
    weekday: j.strOr('weekday'),
    date: j.strOr('date'),
    isRestDay: j.flag('is_rest_day'),
    title: j.str('title'),
    durationMinutes: j.integer('duration_minutes'),
  );
}

/// `POST /cycle/period-start` response.
class PeriodStartResult {
  const PeriodStartResult({
    this.cycleDay,
    this.cycleSummary,
    this.cycleDurationChanged = false,
    this.previousCycleDuration,
    this.cycleDuration,
    this.nextEstimatedPeriodDate,
    this.weekRebuilt = false,
    this.moved = const [],
  });

  final int? cycleDay;
  final CycleSummary? cycleSummary;
  final bool cycleDurationChanged;
  final int? previousCycleDuration;
  final int? cycleDuration;
  final String? nextEstimatedPeriodDate;
  final bool weekRebuilt;

  /// Days whose assignment changed; empty when [weekRebuilt] is false.
  final List<MovedDay> moved;

  factory PeriodStartResult.fromJson(Json j) {
    final s = j.obj('cycle_summary');
    return PeriodStartResult(
      cycleDay: j.integer('cycle_day'),
      cycleSummary: s == null ? null : CycleSummary.fromJson(s),
      cycleDurationChanged: j.flag('cycle_duration_changed'),
      previousCycleDuration: j.integer('previous_cycle_duration'),
      cycleDuration: j.integer('cycle_duration'),
      nextEstimatedPeriodDate: j.str('next_estimated_period_date'),
      weekRebuilt: j.flag('week_rebuilt'),
      moved: j.list('moved', MovedDay.fromJson),
    );
  }
}
