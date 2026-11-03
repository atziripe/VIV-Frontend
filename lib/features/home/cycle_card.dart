import 'package:flutter/material.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/catalog.dart';
import '../../data/models/home.dart';
import '../../data/models/me.dart';
import 'cycle_copy.dart';
import 'period_start_sheet.dart';

/// One phase on the cycle track: cycle days [start]..[end], inclusive.
class PhaseSpan {
  const PhaseSpan(this.phase, this.start, this.end);

  final CyclePhase phase;
  final int start;
  final int end;

  int get days => end - start + 1;
}

/// Where she is in her cycle, from `/me` (+ `/home/today`'s countdown when
/// it has one). The phase spans mirror the backend's `phaseForDay`
/// (cycle_sync.go) so the track and the phase name never disagree.
class CycleEstimate {
  const CycleEstimate({
    required this.day,
    required this.duration,
    required this.phase,
    required this.spans,
    required this.periodStart,
    required this.nextPeriod,
    this.nextPhase,
    this.daysToNext,
  });

  final int day;
  final int duration;
  final CyclePhase phase;
  final List<PhaseSpan> spans;
  final DateTime periodStart;
  final DateTime nextPeriod;
  final CyclePhase? nextPhase;
  final int? daysToNext;

  /// Null when there's nothing honest to show: estimates off, a late period
  /// (the late card handles that), or no cycle day yet.
  static CycleEstimate? from(Me? me, {HomeToday? home}) {
    if (me == null || me.cycleEstimationDisabled || me.daysLate > 0) return null;
    final day = me.cycleDay;
    if (day == null || day <= 0) return null;
    final duration = int.tryParse(me.cycleDuration ?? '') ?? 28;
    final period = int.tryParse(me.periodDuration ?? '') ?? 5;
    final spans = phaseSpans(duration, period);
    if (spans.isEmpty) return null;

    final shownDay = day.clamp(1, duration);
    final current = spans.lastWhere((s) => s.start <= shownDay, orElse: () => spans.first);
    final phase = me.cyclePhase ?? current.phase;
    final i = spans.indexOf(current);
    final computedNext = i + 1 < spans.length ? spans[i + 1].phase : CyclePhase.menstrual;
    final computedDays = (i + 1 < spans.length ? spans[i + 1].start : duration + 1) - shownDay;

    final today = Dates.today();
    final periodStart = today.subtract(Duration(days: day - 1));
    final nextPeriod =
        Dates.tryParseYmd(me.expectedPeriodDate) ?? periodStart.add(Duration(days: duration));
    return CycleEstimate(
      day: day,
      duration: duration,
      phase: phase,
      spans: spans,
      periodStart: periodStart,
      nextPeriod: nextPeriod,
      nextPhase: home?.nextPhase ?? computedNext,
      daysToNext: home?.daysUntilNextPhase ?? computedDays,
    );
  }

  /// Same boundaries as the backend: bleeding days, follicular until two days
  /// before ovulation (duration − 14), a 3-day ovulatory window, five early
  /// luteal days, then late luteal.
  static List<PhaseSpan> phaseSpans(int duration, int period) {
    if (duration <= 0) return const [];
    final p = period <= 0 ? 5 : period;
    final ov = duration - 14;
    final raw = [
      PhaseSpan(CyclePhase.menstrual, 1, p),
      PhaseSpan(CyclePhase.follicular, p + 1, ov - 2),
      PhaseSpan(CyclePhase.ovulatory, (ov - 1).clamp(p + 1, duration), ov + 1),
      PhaseSpan(CyclePhase.earlyLuteal, ov + 2, ov + 5),
      PhaseSpan(CyclePhase.lateLuteal, ov + 6, duration),
    ];
    // Short cycles can squeeze a phase out entirely; drop empty spans.
    return [
      for (final s in raw)
        if (s.end >= s.start && s.start <= duration)
          PhaseSpan(s.phase, s.start, s.end.clamp(s.start, duration)),
    ];
  }

  /// Fraction along the current phase's span, for the marker.
  double get progressInPhase {
    final span = spans.firstWhere((s) => s.phase == phase, orElse: () => spans.first);
    if (span.days <= 1) return 0.5;
    return ((day.clamp(span.start, span.end) - span.start) / (span.days - 1)).clamp(0.0, 1.0);
  }

  /// "Ovulatory in about 4 days" / "Period tomorrow". [short] → "in ~4 days".
  String? countdown({bool short = false}) {
    final d = daysToNext;
    if (d == null || nextPhase == null) return null;
    final name = nextPhase == CyclePhase.menstrual ? 'Period' : nextPhase!.displayName;
    return switch (d) {
      <= 0 => '$name starts today',
      1 => '$name tomorrow',
      _ => short ? '$name in ~$d days' : '$name in about $d days',
    };
  }
}

/// Today · "YOUR CYCLE": phase and day, one line, the track, and a way into
/// the briefing.
class CycleCard extends StatelessWidget {
  const CycleCard({super.key, required this.estimate});

  final CycleEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final e = estimate;
    final copy = PhaseCopy.of(e.phase);
    final countdown = e.countdown();
    return Semantics(
      container: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showCycleBriefing(context, e),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: c.raised,
            borderRadius: BorderRadius.circular(VivRadius.card),
            boxShadow: c.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _Dot(color: VivColors.phaseDot(e.phase)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text('YOUR CYCLE', style: VivType.eyebrow.copyWith(color: c.muted)),
                  ),
                  Semantics(
                    button: true,
                    child: Text(
                      'Briefing ›',
                      style: VivType.body.copyWith(fontWeight: FontWeight.w700, color: c.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${e.phase.displayName} · day ${e.day}',
                style: VivType.h3.copyWith(fontSize: 22, color: c.ink),
              ),
              const SizedBox(height: 8),
              Text(
                [copy.card, if (countdown != null) '$countdown.'].join(' '),
                style: VivType.body.copyWith(fontSize: 15, color: c.muted),
              ),
              const SizedBox(height: 16),
              CycleTrack(estimate: e),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// The cycle as five segments sized by days. The current phase is filled in
/// its phase colour with a ring marking today; the rest stay sunken.
class CycleTrack extends StatelessWidget {
  const CycleTrack({super.key, required this.estimate});

  final CycleEstimate estimate;

  static const _height = 9.0;
  static const _marker = 16.0;
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final e = estimate;
    final color = VivColors.phaseDot(e.phase);
    return Semantics(
      label: 'Day ${e.day} of about ${e.duration}, ${e.phase.displayName}',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final usable = box.maxWidth - _gap * (e.spans.length - 1);
          final total = e.spans.fold<int>(0, (sum, s) => sum + s.days);
          var x = 0.0;
          double? markerX;
          final segments = <Widget>[];
          for (final s in e.spans) {
            final w = usable * s.days / total;
            final current = s.phase == e.phase;
            if (current) markerX = x + w * e.progressInPhase;
            segments.add(
              Positioned(
                left: x,
                width: w,
                top: (_marker - _height) / 2,
                height: _height,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: current ? color : c.sunken,
                  ),
                ),
              ),
            );
            x += w + _gap;
          }
          return SizedBox(
            height: _marker,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ...segments,
                if (markerX != null)
                  Positioned(
                    left: (markerX - _marker / 2).clamp(0.0, box.maxWidth - _marker),
                    top: 0,
                    child: Container(
                      width: _marker,
                      height: _marker,
                      decoration: BoxDecoration(
                        color: c.raised,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The briefing: the phase in plain words, what it means for training,
/// energy and food this week, and what's going on underneath.
Future<void> showCycleBriefing(BuildContext context, CycleEstimate e) {
  return showVivSheet<void>(
    context,
    builder: (sheet) => _Briefing(estimate: e, sheetContext: sheet, hostContext: context),
  );
}

class _Briefing extends StatelessWidget {
  const _Briefing({required this.estimate, required this.sheetContext, required this.hostContext});

  final CycleEstimate estimate;
  final BuildContext sheetContext;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final e = estimate;
    final copy = PhaseCopy.of(e.phase);
    final logLabel = e.phase == CyclePhase.lateLuteal
        ? 'Period started? Log it'
        : 'Period came early? Log it';
    return VivBottomSheet(
      eyebrow: 'Your cycle · day ${e.day} of ~${e.duration}',
      actions: [
        PillButton(label: 'Got it', onPressed: () => Navigator.of(sheetContext).pop()),
        PillButton(
          label: logLabel,
          variant: PillVariant.text,
          size: PillSize.compact,
          onPressed: () {
            Navigator.of(sheetContext).pop();
            showPeriodStartSheet(hostContext);
          },
        ),
      ],
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                e.phase.displayName,
                style: VivType.h1.copyWith(fontSize: 34, color: c.ink),
              ),
            ),
            const SizedBox(height: 10),
            Text(copy.about, style: VivType.lead.copyWith(fontSize: 15.5, color: c.muted)),
            const SizedBox(height: 20),
            CycleTrack(estimate: e),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Period · ${Dates.dayMonth(e.periodStart)}',
                    style: VivType.meta.copyWith(color: c.muted),
                  ),
                ),
                if (e.countdown(short: true) case final countdown?)
                  Text(
                    countdown,
                    style: VivType.meta.copyWith(fontWeight: FontWeight.w700, color: c.ink),
                  ),
                Expanded(
                  child: Text(
                    'Next · ~${Dates.dayMonth(e.nextPeriod)}',
                    textAlign: TextAlign.right,
                    style: VivType.meta.copyWith(color: c.muted),
                  ),
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('THIS WEEK FOR YOU', style: VivType.eyebrow.copyWith(color: c.muted)),
            const SizedBox(height: 6),
            _Topic(label: 'Training', text: copy.training),
            _Topic(label: 'Energy', text: copy.energy),
            _Topic(label: 'Food', text: copy.food, last: true),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.sunken,
            borderRadius: BorderRadius.circular(VivRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WHAT\'S GOING ON', style: VivType.eyebrow.copyWith(color: c.accent)),
              const SizedBox(height: 8),
              Text(copy.goingOn, style: VivType.body.copyWith(color: c.ink2)),
            ],
          ),
        ),
        Text(cycleBriefingLegal, style: VivType.legal.copyWith(color: c.subtle)),
      ],
    );
  }
}

class _Topic extends StatelessWidget {
  const _Topic({required this.label, required this.text, this.last = false});

  final String label;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: VivType.eyebrow.copyWith(color: c.accent)),
          const SizedBox(height: 6),
          Text(text, style: VivType.body.copyWith(fontSize: 16, color: c.ink)),
        ],
      ),
    );
  }
}
