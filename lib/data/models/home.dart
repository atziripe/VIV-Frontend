import 'catalog.dart';
import 'json.dart';

enum TimelineStatus { done, pending, upcoming }

/// Kinds that appear in `timeline` and/or `now_card`.
enum TimelineKind { checkin, meal, session, recoveryAction, lightsOut, unknown }

TimelineKind _kind(String? v) => switch (v) {
  'checkin' => TimelineKind.checkin,
  'meal' => TimelineKind.meal,
  'session' => TimelineKind.session,
  'recovery_action' => TimelineKind.recoveryAction,
  'lights_out' => TimelineKind.lightsOut,
  _ => TimelineKind.unknown,
};

/// One row of the Home timeline (`GET /home/today`).
class TimelineItem {
  const TimelineItem({
    required this.kind,
    required this.status,
    required this.title,
    this.time,
    this.detail,
    this.isEstimated = false,
  });

  final TimelineKind kind;
  final TimelineStatus status;
  final String title;

  /// Local `HH:MM`; absent when the backend can't estimate one.
  final String? time;
  final String? detail;

  /// Derived from a fixed offset table rather than something that happened.
  final bool isEstimated;

  bool get isDone => status == TimelineStatus.done;

  factory TimelineItem.fromJson(Json j) => TimelineItem(
    kind: _kind(j.str('kind')),
    status: TimelineStatus.values.asNameMap()[j.str('status')] ?? TimelineStatus.upcoming,
    title: j.strOr('title'),
    time: j.str('time'),
    detail: j.str('detail'),
    isEstimated: j.flag('is_estimated'),
  );
}

/// The highlighted card: whichever moment matters most right now.
class NowCard extends TimelineItem {
  const NowCard({
    required super.kind,
    required super.status,
    required super.title,
    super.time,
    super.detail,
    super.isEstimated,
    this.label,
    this.ctaLabel,
    this.ctaAction,
  });

  /// "NOW", "IN 15 MIN", "TODAY", "TONIGHT".
  final String? label;
  final String? ctaLabel;

  /// `"METHOD /path"` of the endpoint the button maps to; empty for lights-out.
  final String? ctaAction;

  /// Countdown labels carry the clock time ("NOW · 07:40"); the others don't.
  bool get showsTime => label == 'NOW' || (label?.startsWith('IN ') ?? false);

  factory NowCard.fromJson(Json j) {
    final base = TimelineItem.fromJson(j);
    return NowCard(
      kind: base.kind,
      status: base.status,
      title: base.title,
      time: base.time,
      detail: base.detail,
      isEstimated: base.isEstimated,
      label: j.str('label'),
      ctaLabel: j.str('cta_label'),
      ctaAction: j.str('cta_action'),
    );
  }
}

enum DayDotStatus { done, pending, rest }

class DayDot {
  const DayDot({required this.weekday, required this.status, this.isToday = false});

  final String weekday;
  final DayDotStatus status;
  final bool isToday;

  /// "M", "T", "W"…
  String get letter => weekday.isEmpty ? '' : weekday[0].toUpperCase();

  factory DayDot.fromJson(Json j) => DayDot(
    weekday: j.strOr('weekday'),
    status: DayDotStatus.values.asNameMap()[j.str('status')] ?? DayDotStatus.rest,
    isToday: j.flag('is_today'),
  );
}

class WeekProgress {
  const WeekProgress({
    required this.completedSessions,
    required this.totalSessions,
    this.days = const [],
  });

  final int completedSessions;
  final int totalSessions;
  final List<DayDot> days;

  factory WeekProgress.fromJson(Json j) => WeekProgress(
    completedSessions: j.integer('completed_sessions') ?? 0,
    totalSessions: j.integer('total_sessions') ?? 0,
    days: j.list('days', DayDot.fromJson),
  );
}

/// `GET /home/today` — everything the Home screen shows, in one read.
class HomeToday {
  const HomeToday({
    required this.date,
    required this.weekday,
    this.weekNumber,
    this.currentPhase,
    this.nextPhase,
    this.daysUntilNextPhase,
    this.nowCard,
    this.timeline = const [],
    this.weekProgress,
  });

  final String date;
  final String weekday;
  final int? weekNumber;
  final CyclePhase? currentPhase;
  final CyclePhase? nextPhase;
  final int? daysUntilNextPhase;

  /// Null once everything today is behind the user.
  final NowCard? nowCard;
  final List<TimelineItem> timeline;
  final WeekProgress? weekProgress;

  /// Greeting status line: "Follicular phase · Ovulatory in 3 days".
  String? get phaseCountdown => phaseCountdownText(currentPhase, nextPhase, daysUntilNextPhase);

  bool get isRestDay {
    for (final d in weekProgress?.days ?? const <DayDot>[]) {
      if (d.isToday) return d.status == DayDotStatus.rest;
    }
    return false;
  }

  factory HomeToday.fromJson(Json j) {
    final now = j.obj('now_card');
    final progress = j.obj('week_progress');
    return HomeToday(
      date: j.strOr('date'),
      weekday: j.strOr('weekday'),
      weekNumber: j.integer('week_number'),
      currentPhase: CyclePhase.fromId(j.str('current_phase')),
      nextPhase: CyclePhase.fromId(j.str('next_phase')),
      daysUntilNextPhase: j.integer('days_until_next_phase'),
      nowCard: now == null ? null : NowCard.fromJson(now),
      timeline: j.list('timeline', TimelineItem.fromJson),
      weekProgress: progress == null ? null : WeekProgress.fromJson(progress),
    );
  }
}

/// "Follicular phase · Ovulatory in 3 days". Degrades to whatever parts the
/// backend sent (all three are optional); null when there's no phase at all.
String? phaseCountdownText(CyclePhase? current, CyclePhase? next, int? days) {
  final countdown = switch (days) {
    null || < 0 => null,
    0 => '${next?.label ?? 'Next phase'} starts today',
    1 => '${next?.label ?? 'Next phase'} tomorrow',
    _ => '${next?.label ?? 'Next phase'} in $days days',
  };
  final parts = [?current == null ? null : '${current.label} phase', ?countdown];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// A Home row: either a plain timeline item or the now card in its slot.
sealed class HomeEntry {
  const HomeEntry();
}

class HomeItemEntry extends HomeEntry {
  const HomeItemEntry(this.item);
  final TimelineItem item;
}

class HomeNowEntry extends HomeEntry {
  const HomeNowEntry(this.card);
  final NowCard card;
}

/// Places the now card inside the timeline, the way the design shows it:
/// it replaces the timeline item it describes, or — when the timeline has no
/// matching row (e.g. `recovery_action`) — sits before the first item that
/// isn't done yet.
List<HomeEntry> composeHomeEntries(List<TimelineItem> timeline, NowCard? card) {
  final entries = <HomeEntry>[for (final i in timeline) HomeItemEntry(i)];
  if (card == null) return entries;

  final match = timeline.indexWhere(
    (i) => i.kind == card.kind && (i.time == card.time || i.title == card.title),
  );
  if (match != -1) {
    entries[match] = HomeNowEntry(card);
    return entries;
  }
  final firstOpen = timeline.indexWhere((i) => !i.isDone);
  entries.insert(firstOpen == -1 ? entries.length : firstOpen, HomeNowEntry(card));
  return entries;
}
