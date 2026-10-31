import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/analytics/track_on_mount.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/models/catalog.dart';
import '../../data/models/checkin.dart';
import '../../data/models/home.dart';
import '../../data/models/me.dart';
import '../../data/models/recovery.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';
import '../checkin/checkin_copy.dart';
import '../checkin/checkin_screen.dart' show showWhyTodaySheet;
import '../profile/your_info_screen.dart' show WhatChanges, showEditNumberSheet;
import 'home_timeline.dart';
import 'period_start_sheet.dart';

/// 03 · Home, as a day. A time-aware timeline: the wine field holds whatever
/// is due now (`GET /home/today` → `now_card`), then "Rest of today", then
/// the week.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(meProvider);
    ref.invalidate(homeTodayProvider);
    ref.invalidate(recoveryCardProvider(Dates.todayYmd()));
    await ref.read(homeTodayProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).value;
    final home = ref.watch(homeTodayProvider);
    final c = context.viv;

    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: c.accent,
          onRefresh: () => _refresh(ref),
          child: ResponsiveCenter(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 4, VivSpace.gutter, 24),
              children: [
                Enter(
                  child: _Greeting(me: me, home: home.value),
                ),
                Enter(
                  delay: const Duration(milliseconds: 60),
                  child: _PhaseLine(me: me, home: home.value),
                ),
                AsyncView<HomeToday?>(
                  value: home,
                  onRetry: () => ref.invalidate(homeTodayProvider),
                  loading: const _HomeSkeleton(),
                  data: (today) => today == null
                      ? const _NoWeek()
                      : TrackOnMount(
                          track: (a) => a.homeViewed(
                            nowCardKind: today.nowCard?.kind.name,
                            isRestDay: today.isRestDay,
                          ),
                          child: _Day(home: today, me: me),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.me, required this.home});

  final Me? me;
  final HomeToday? home;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final name = me?.firstName ?? '';
    final date = Dates.tryParseYmd(home?.date) ?? Dates.today();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "THU · 10 SEP"
              Text(
                '${Dates.shortWeekday(date)} · ${Dates.dayMonth(date)}'.toUpperCase(),
                style: VivType.eyebrow.copyWith(color: c.muted),
              ),
              const SizedBox(height: 6),
              Semantics(
                header: true,
                child: Text(
                  name.isEmpty ? 'Hey there' : 'Hey $name',
                  style: VivType.h1.copyWith(height: 1.05, letterSpacing: -1.19, color: c.ink),
                ),
              ),
            ],
          ),
        ),
        _Avatar(initial: name.isEmpty ? null : name[0].toUpperCase()),
      ],
    );
  }
}

/// The cycle, quietly: one dot and one line.
class _PhaseLine extends StatelessWidget {
  const _PhaseLine({required this.me, required this.home});

  final Me? me;
  final HomeToday? home;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    // "Late follicular · Ovulatory in 3 days" (falls back to /me's phase).
    final status = home?.phaseCountdown ?? phaseCountdownText(me?.cyclePhase, null, null);
    final phase = home?.currentPhase ?? me?.cyclePhase;
    if (status == null) return const SizedBox(height: 18);
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 18),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: phase == null ? c.ring : VivColors.phaseDot(phase),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(status, style: VivType.meta.copyWith(fontSize: 13.5, color: c.muted)),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.initial});

  final String? initial;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Semantics(
      button: true,
      label: 'You',
      child: GestureDetector(
        onTap: () => context.push(Routes.profile),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.sunken, shape: BoxShape.circle),
          child: Text(
            initial ?? '',
            style: VivType.rowTitle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.ink2,
            ),
          ),
        ),
      ),
    );
  }
}

/// The day: the field, the rest of today, the week.
class _Day extends ConsumerWidget {
  const _Day({required this.home, required this.me});

  final HomeToday home;
  final Me? me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.viv;
    final loop = ref.watch(todayLoopProvider);
    final checkin = ref.watch(todayCheckinProvider);
    final dismissed = ref.watch(dismissedMomentsProvider);

    var card = home.nowCard;
    final skipped =
        card?.kind == TimelineKind.checkin &&
        dismissed.contains(DismissedMoments.keyFor(home.date, TimelineKind.checkin));
    TimelineItem? hero = card;
    if (skipped) {
      // Skipped: the next thing that's still open takes the field.
      hero = home.timeline
          .where((i) => !i.isDone && i.kind != TimelineKind.checkin && i.kind != TimelineKind.meal)
          .firstOrNull;
      card = null;
    }
    // A proposal she hasn't answered yet (she left the proposal screen).
    final pendingProposal = checkin?.suggestion != null && loop == null ? checkin : null;

    final rows = [
      for (final i in home.timeline)
        if (hero == null || i.kind != hero.kind) i,
    ];

    var delay = 280;
    Duration next() => Duration(milliseconds: (delay += 70) - 70);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (skipped) ...[
          Text(
            'No check-in today. That\'s fine, you\'re on your usual plan.',
            style: VivType.body.copyWith(color: c.muted),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => context.push(Routes.checkin),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: VivSize.minTap),
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  child: Text(
                    'Check in anyway',
                    style: VivType.body.copyWith(fontWeight: FontWeight.w700, color: c.accent),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (pendingProposal != null)
          _ProposalField(result: pendingProposal)
        else if (hero != null)
          _HeroField(
            item: hero,
            now: card,
            date: home.date,
            decision: loop?.decision,
            answers: loop?.answers,
          ),
        if (me case final me?
            when me.daysLate > 0 &&
                !me.cycleEstimationDisabled &&
                !ref.watch(latePromptSnoozedProvider)) ...[
          const SizedBox(height: 14),
          _LatePeriodCard(me: me),
        ],
        if (rows.isNotEmpty) ...[
          Enter(
            delay: const Duration(milliseconds: 220),
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 6),
              child: Text('REST OF TODAY', style: VivType.eyebrow.copyWith(color: c.muted)),
            ),
          ),
          for (final item in rows)
            Enter(
              delay: next(),
              duration: const Duration(milliseconds: 480),
              child: TimelineRow(
                time: item.time ?? '',
                title: item.title,
                meta: item.kind == TimelineKind.checkin && item.isDone
                    ? (loop?.summary ?? item.detail)
                    : item.detail,
                done: item.isDone,
                onTap: _onTap(context, item),
              ),
            ),
        ],
        if (home.weekProgress case final progress? when progress.days.isNotEmpty) ...[
          const SizedBox(height: 20),
          Enter(
            delay: const Duration(milliseconds: 480),
            child: GestureDetector(
              onTap: () => context.go(Routes.train),
              child: WeekCard(
                completed: progress.completedSessions,
                total: progress.totalSessions,
                days: weekCardDays(progress.days),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        const _PeriodStrip(),
      ],
    );
  }

  VoidCallback? _onTap(BuildContext context, TimelineItem item) => switch (item.kind) {
    TimelineKind.meal => () => context.go(Routes.eat),
    TimelineKind.session => () => context.push(Routes.sessionDetail(home.date)),
    TimelineKind.checkin when !item.isDone => () => context.push(Routes.checkin),
    _ => null,
  };
}

/// Day circles for the [WeekCard]: a planned day before today that wasn't
/// done reads as missed (dashed), never counted against her.
List<WeekCardDay> weekCardDays(List<DayDot> days) {
  final today = days.indexWhere((d) => d.isToday);
  return [
    for (final (i, d) in days.indexed)
      WeekCardDay(
        letter: d.letter,
        isToday: d.isToday,
        mark: switch (d.status) {
          DayDotStatus.done => WeekMark.done,
          DayDotStatus.rest => WeekMark.rest,
          DayDotStatus.pending => (today >= 0 && i < today) ? WeekMark.missed : WeekMark.planned,
        },
      ),
  ];
}

String _pillar(TimelineKind kind) => switch (kind) {
  TimelineKind.checkin => 'Check-in',
  TimelineKind.session => 'Train',
  TimelineKind.meal => 'Eat',
  TimelineKind.recoveryAction || TimelineKind.lightsOut => 'Recover',
  TimelineKind.unknown => 'Today',
};

/// The wine field for whatever is due now.
class _HeroField extends ConsumerStatefulWidget {
  const _HeroField({
    required this.item,
    required this.now,
    required this.date,
    this.decision,
    this.answers,
  });

  final TimelineItem item;

  /// The backend's now card, when [item] is it (labels and CTA copy).
  final NowCard? now;
  final String date;
  final TodayDecision? decision;
  final DailyCheckinRequest? answers;

  @override
  ConsumerState<_HeroField> createState() => _HeroFieldState();
}

class _HeroFieldState extends ConsumerState<_HeroField> {
  String? _busy;

  TimelineItem get item => widget.item;

  void _refreshToday() {
    ref.invalidate(homeTodayProvider);
    ref.invalidate(currentWeekProvider);
    ref.invalidate(recoveryCardProvider(widget.date));
    ref.invalidate(dayDetailProvider(widget.date));
  }

  Future<void> _run(String id, Future<void> Function() action) async {
    setState(() => _busy = id);
    try {
      await action();
      _refreshToday();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _track() => ref.read(analyticsProvider).nowCardTapped(item.kind.name);

  Future<void> _skipCheckin() async {
    _track();
    ref.read(dismissedMomentsProvider.notifier).dismiss(widget.date, TimelineKind.checkin);
    await ref.read(todayLoopProvider.notifier).decide(TodayDecision.skipped);
    if (mounted) VivToast.show(context, CheckinCopy.toastSkipped);
  }

  Future<void> _notToday() async {
    final ok = await showVivSheet<bool>(
      context,
      builder: (sheet) => VivBottomSheet(
        title: 'Make today a rest day?',
        body: 'VIV turns today into rest. The rest of the week stays as planned.',
        actions: [
          PillButton(
            label: 'Rest today',
            size: PillSize.control,
            onPressed: () => Navigator.pop(sheet, true),
          ),
          PillButton(
            label: 'Keep it',
            variant: PillVariant.secondary,
            size: PillSize.medium,
            onPressed: () => Navigator.pop(sheet, false),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run('secondary', () async {
      // An empty activity_type turns the day into rest.
      await ref.read(vivApiProvider).editDay(DaySlotEdit(date: widget.date));
      ref.read(analyticsProvider).weekDayEdited(toRest: true);
      if (mounted) VivToast.show(context, CheckinCopy.toastNotToday);
    });
  }

  Future<void> _recovery(RecoveryActionKind kind) => _run(kind.value, () async {
    await ref.read(vivApiProvider).saveRecoveryAction(widget.date, kind);
    ref.read(analyticsProvider).recoveryActionLogged(kind.value);
  });

  void _whyFromAnswers() {
    final a = widget.answers;
    if (a == null) return;
    final checkin = ref.read(todayCheckinProvider);
    showWhyTodaySheet(
      context,
      CheckinCopy.reasons(
        sleep: a.sleep,
        body: a.body,
        demand: a.demand,
        need: a.need,
        adjusted: widget.decision == TodayDecision.adjusted,
        backendReason: checkin?.reason,
        phase: ref.read(homeTodayProvider).value?.currentPhase,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.now;
    // "NOW · 07:40", "IN 15 MIN · 18:00", "TONIGHT", "NEXT · 18:00".
    final eyebrow = now != null
        ? [now.label ?? 'Now', if (now.showsTime && now.time != null) now.time!].join(' · ')
        : ['Next', ?item.time].join(' · ');

    final String? decisionTag = switch ((item.kind, widget.decision)) {
      (TimelineKind.session, TodayDecision.adjusted) => 'Adjusted · your call',
      (TimelineKind.session, TodayDecision.kept) => 'Kept · your call',
      _ => null,
    };

    String? primary;
    VoidCallback? onPrimary;
    String? secondary;
    VoidCallback? onSecondary;
    VoidCallback? onWhy;
    String? costTag;

    switch (item.kind) {
      case TimelineKind.checkin:
        primary = now?.ctaLabel ?? 'Check in';
        onPrimary = () {
          _track();
          context.push(Routes.checkin);
        };
        secondary = 'Skip';
        onSecondary = _skipCheckin;
      case TimelineKind.session:
        primary = now?.ctaLabel ?? 'Start';
        onPrimary = () {
          _track();
          context.push(Routes.sessionDetail(widget.date));
        };
        secondary = 'Not today';
        onSecondary = _busy == null ? _notToday : null;
        if (widget.answers != null) onWhy = _whyFromAnswers;
      case TimelineKind.recoveryAction:
        final card = ref.watch(recoveryCardProvider(widget.date)).value;
        if (card?.costTier case final tier?) costTag = '$tier cost';
        // Only what the recovery card offers — anything else is a 400.
        final actions = card?.availableActions ?? const [];
        final options = actions.isEmpty
            ? const [
                RecoveryActionOption(kind: RecoveryActionKind.done, label: 'Done'),
                RecoveryActionOption(kind: RecoveryActionKind.notToday, label: 'Not today'),
              ]
            : actions;
        primary = now?.ctaLabel ?? options.first.label;
        onPrimary = _busy == null
            ? () {
                _track();
                _recovery(options.first.kind);
              }
            : null;
        if (options.length > 1) {
          secondary = options[1].label;
          onSecondary = _busy == null ? () => _recovery(options[1].kind) : null;
        }
        if (card?.why case final why?) {
          onWhy = () => showWhyTodaySheet(context, [(card?.headline ?? 'Recovery', why)]);
        }
      case TimelineKind.lightsOut:
      case TimelineKind.meal:
      case TimelineKind.unknown:
        // "Remind me" waits for notifications.
        break;
    }

    return WineField(
      eyebrow: eyebrow,
      pillar: _pillar(item.kind),
      tag: decisionTag ?? costTag,
      title: item.title,
      body: item.detail,
      primaryLabel: primary,
      onPrimary: onPrimary,
      secondaryLabel: secondary,
      onSecondary: onSecondary,
      onWhy: onWhy,
    );
  }
}

/// She left the proposal without choosing: the field asks again.
class _ProposalField extends ConsumerStatefulWidget {
  const _ProposalField({required this.result});

  final DailyCheckinResult result;

  @override
  ConsumerState<_ProposalField> createState() => _ProposalFieldState();
}

class _ProposalFieldState extends ConsumerState<_ProposalField> {
  bool _saving = false;

  Future<void> _accept() async {
    final a = widget.result.suggestion!.assignment;
    setState(() => _saving = true);
    try {
      await ref
          .read(vivApiProvider)
          .editDay(
            DaySlotEdit(
              date: widget.result.date,
              activityType: a.activityType,
              intensity: a.intensity,
              impact: a.impact,
            ),
          );
      ref.invalidate(currentWeekProvider);
      ref.invalidate(homeTodayProvider);
      ref.invalidate(dayDetailProvider(widget.result.date));
      await ref.read(todayCheckinProvider.notifier).applySuggestion();
      await ref.read(todayLoopProvider.notifier).decide(TodayDecision.adjusted);
      if (mounted) VivToast.show(context, CheckinCopy.toastSwapped);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _keep() async {
    await ref.read(todayLoopProvider.notifier).decide(TodayDecision.kept);
    if (mounted) VivToast.show(context, CheckinCopy.toastKept);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.result.suggestion!;
    return WineField(
      eyebrow: 'Now',
      pillar: 'Train',
      tag: 'Proposed',
      title: sessionTitle(
        activityType: s.assignment.activityType,
        intensity: s.assignment.intensity,
      ),
      body: s.reason,
      primaryLabel: 'Sounds good',
      onPrimary: _saving ? null : _accept,
      secondaryLabel: 'Keep the original',
      onSecondary: _saving ? null : _keep,
    );
  }
}

/// The prompt near the estimate. Six or more days past it, VIV owns the
/// miss instead: update the cycle length, or stop estimating. No counter, no
/// irregularity flag.
class _LatePeriodCard extends ConsumerStatefulWidget {
  const _LatePeriodCard({required this.me});

  final Me me;

  @override
  ConsumerState<_LatePeriodCard> createState() => _LatePeriodCardState();
}

class _LatePeriodCardState extends ConsumerState<_LatePeriodCard> {
  bool _stopping = false;

  Future<void> _stopEstimating() async {
    setState(() => _stopping = true);
    try {
      await ref.read(vivApiProvider).updateMe(const ProfileUpdate(cycleEstimationDisabled: true));
      ref.invalidate(meProvider);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final me = widget.me;
    final wrong = me.daysLate >= 6;
    final expected = Dates.tryParseYmd(me.expectedPeriodDate);
    return Container(
      padding: const EdgeInsets.all(VivSpace.card),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(VivRadius.card),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wrong) ...[
            Text('VIV GOT THIS ONE WRONG', style: VivType.eyebrow.copyWith(color: c.accent)),
            const SizedBox(height: 10),
            Text(
              'Your cycle may just run longer than VIV assumed.',
              style: VivType.h3.copyWith(fontSize: 23, color: c.ink),
            ),
            const SizedBox(height: 10),
            Text(
              'Set it to what you actually know and the next estimate lands closer.',
              style: VivType.body.copyWith(fontSize: 14.5, color: c.ink2),
            ),
            const SizedBox(height: 14),
            PillButton(
              label: 'Update cycle length',
              size: PillSize.medium,
              onPressed: () => showEditNumberSheet(
                context,
                title: 'Typical cycle length',
                unit: 'days',
                initial: double.tryParse(me.cycleDuration ?? '') ?? 28,
                step: 1,
                min: 15,
                max: 60,
                whatChanges: WhatChanges.cycleLength,
                build: (v) => ProfileUpdate(cycleDuration: v.round().toString()),
              ),
            ),
            const SizedBox(height: 4),
            PillButton(
              label: 'It varies, stop estimating',
              variant: PillVariant.text,
              size: PillSize.compact,
              busy: _stopping,
              onPressed: _stopEstimating,
            ),
            const SizedBox(height: 6),
            Text(
              'VIV uses timing to plan training, not to tell you anything about your health. '
              'If a late period is a question for you, it\'s one for your doctor.',
              style: VivType.legal.copyWith(color: c.subtle),
            ),
          ] else ...[
            Text(
              expected == null
                  ? 'VIV expects your period around now. Started already?'
                  : 'VIV expects your period around ${Dates.longWeekday(expected)}. '
                        'Started already?',
              style: VivType.body.copyWith(color: c.ink2),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: 'Yes, log it',
                    size: PillSize.compact,
                    onPressed: () => showPeriodStartSheet(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PillButton(
                    label: 'Not yet',
                    variant: PillVariant.tint,
                    size: PillSize.compact,
                    onPressed: () => showHoldingSheet(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Always-on "Period arrived? · Log it" at the bottom of Home.
class _PeriodStrip extends StatelessWidget {
  const _PeriodStrip();

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showPeriodStartSheet(context),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: ShapeDecoration(color: c.sunken, shape: const StadiumBorder()),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Period arrived?',
                style: VivType.body.copyWith(fontWeight: FontWeight.w500, color: c.ink2),
              ),
            ),
            Text(
              'Log it',
              style: VivType.body.copyWith(fontWeight: FontWeight.w700, color: c.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoWeek extends ConsumerStatefulWidget {
  const _NoWeek();

  @override
  ConsumerState<_NoWeek> createState() => _NoWeekState();
}

class _NoWeekState extends ConsumerState<_NoWeek> {
  bool _building = false;

  Future<void> _generate() async {
    setState(() => _building = true);
    try {
      final api = ref.read(vivApiProvider);
      final jobId = await api.startWeeklyPlanGeneration();
      await api.waitForWeeklyPlan(jobId);
      ref.invalidate(currentWeekProvider);
      ref.invalidate(homeTodayProvider);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _building = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_building) return const _HomeSkeleton();
    return WineField(
      pillar: 'This week',
      title: 'Your week isn\'t built yet.',
      body: 'Check in to build it around today, or build it now.',
      primaryLabel: 'Build my week',
      onPrimary: _generate,
    );
  }
}

/// Home's shape while `/home/today` loads.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SkeletonBox.field(),
          const SizedBox(height: 28),
          const SkeletonBox.line(width: 110, height: 12),
          const SizedBox(height: 10),
          for (var i = 0; i < 3; i++) ...[
            const Row(
              children: [
                SkeletonBox.line(width: 40, height: 12),
                SizedBox(width: 13),
                SkeletonBox(width: 22, height: 22, radius: VivRadius.pill),
                SizedBox(width: 13),
                Expanded(child: SkeletonBox.line()),
              ],
            ),
            const SizedBox(height: 26),
          ],
          const SkeletonBox(height: 110, radius: VivRadius.group),
        ],
      ),
    );
  }
}
