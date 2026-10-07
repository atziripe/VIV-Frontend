import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/models/catalog.dart';
import '../../data/models/checkin.dart';
import '../../data/models/home.dart';
import '../../data/models/me.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';
import 'home_timeline.dart';
import 'period_start_sheet.dart';

/// 10a · Home, as a day — training, food and recovery in one timeline, with
/// the moment that matters now (`GET /home/today` → `now_card`) highlighted.
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
    final checkin = ref.watch(todayCheckinProvider);
    final c = context.viv;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: c.primary,
          onRefresh: () => _refresh(ref),
          child: ResponsiveCenter(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                VivSpace.gutter,
                VivSpace.md,
                VivSpace.gutter,
                VivSpace.xl,
              ),
              children: [
                _Greeting(me: me, home: home.value),
                const SizedBox(height: VivSpace.lg),
                if (me != null && me.daysLate > 0 && !me.cycleEstimationDisabled) ...[
                  _LatePeriodCard(me: me),
                  const SizedBox(height: VivSpace.sm),
                ],
                if (checkin?.suggestion case final suggestion?) ...[
                  _SuggestionCard(date: checkin!.date, suggestion: suggestion),
                  const SizedBox(height: VivSpace.sm),
                ],
                AsyncView<HomeToday?>(
                  value: home,
                  onRetry: () => ref.invalidate(homeTodayProvider),
                  loading: const Padding(
                    padding: EdgeInsets.all(VivSpace.xxl),
                    child: LoadingView(),
                  ),
                  data: (today) => today == null ? const _NoWeekCard() : _Timeline(home: today),
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
    final isRest = home?.isRestDay ?? false;

    // "THURSDAY · 10 SEP · WEEK 6" / "FRIDAY · 11 SEP · REST DAY"
    final eyebrow = [
      Dates.eyebrow(date),
      if (isRest) 'REST DAY' else if (home?.weekNumber != null) 'WEEK ${home!.weekNumber}',
    ].join(' · ');

    // "Follicular phase · Ovulatory in 3 days" (falls back to /me's phase)
    final status = home?.phaseCountdown ?? phaseCountdownText(me?.cyclePhase, null, null);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(eyebrow),
              const SizedBox(height: VivSpace.xs),
              Semantics(
                header: true,
                child: Text(
                  name.isEmpty ? 'Hey there' : 'Hey $name',
                  style: VivType.title.copyWith(color: c.textPrimary),
                ),
              ),
              if (status != null) ...[
                const SizedBox(height: VivSpace.xxs),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: c.signal, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        status,
                        style: VivType.caption.copyWith(color: c.textSecondary, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        _Avatar(initial: name.isEmpty ? null : name[0].toUpperCase()),
      ],
    );
  }
}

/// Timeline rows with the now card in its chronological slot, then the week.
class _Timeline extends ConsumerWidget {
  const _Timeline({required this.home});

  final HomeToday home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = ref.watch(dismissedMomentsProvider);
    var card = home.nowCard;
    if (card != null && dismissed.contains(DismissedMoments.keyFor(home.date, card.kind))) {
      card = null; // Skipped: falls back to a plain row.
    }
    final entries = composeHomeEntries(home.timeline, card);
    // A skipped card that had no timeline row of its own still shows as a row.
    final skipped = home.nowCard != null && card == null;
    final skippedHasRow = skipped && home.timeline.any((i) => i.kind == home.nowCard!.kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (skipped && !skippedHasRow) TimelineRow(item: home.nowCard!),
        for (final e in entries)
          switch (e) {
            HomeNowEntry(:final card) => NowMomentCard(card: card, date: home.date),
            HomeItemEntry(:final item) => TimelineRow(item: item, onTap: _onTap(context, item)),
          },
        if (home.weekProgress case final progress? when progress.days.isNotEmpty) ...[
          const SizedBox(height: VivSpace.md),
          WeekProgressCard(progress: progress, onTap: () => context.go(Routes.train)),
        ],
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

class _Avatar extends StatelessWidget {
  const _Avatar({this.initial});

  final String? initial;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Semantics(
      button: true,
      label: 'Profile',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.push(Routes.profile),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: c.primarySoft,
          child: Text(initial ?? '', style: VivType.label.copyWith(color: c.primary, fontSize: 14)),
        ),
      ),
    );
  }
}

class _LatePeriodCard extends StatelessWidget {
  const _LatePeriodCard({required this.me});

  final Me me;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final expected = Dates.tryParseYmd(me.expectedPeriodDate);
    return VivCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Eyebrow(
            expected == null
                ? 'Your period may be late'
                : 'VIV expected your period on ${Dates.longWeekday(expected)}',
            accent: true,
          ),
          const SizedBox(height: VivSpace.xs),
          Text('Still not here?', style: VivType.cardTitle.copyWith(color: c.textPrimary)),
          const SizedBox(height: VivSpace.md),
          Row(
            children: [
              Expanded(
                child: VivButton.secondary(
                  label: 'It started',
                  height: 44,
                  onPressed: () => showPeriodStartSheet(context),
                ),
              ),
              const SizedBox(width: VivSpace.xs),
              Expanded(
                child: VivButton.secondary(
                  label: 'Not yet',
                  height: 44,
                  // TODO(design): "Not yet" follow-up (cycle length nudge).
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Okay, we\'ll keep the week gentle.')),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoWeekCard extends ConsumerStatefulWidget {
  const _NoWeekCard();

  @override
  ConsumerState<_NoWeekCard> createState() => _NoWeekCardState();
}

class _NoWeekCardState extends ConsumerState<_NoWeekCard> {
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
    final c = context.viv;
    return VivCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Eyebrow('This week'),
          const SizedBox(height: VivSpace.xs),
          Text(
            'Your week isn\'t built yet.',
            style: VivType.cardTitle.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: VivSpace.xxs),
          Text(
            'Check in to build it around today, or build it now.',
            style: VivType.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: VivSpace.md),
          VivButton.secondary(
            label: 'Build my week',
            height: 44,
            loading: _building,
            onPressed: _generate,
          ),
        ],
      ),
    );
  }
}

/// Daily adaptation proposes — the user decides. Accepting applies it via
/// `PATCH /training/weekly-plan/day`.
class _SuggestionCard extends ConsumerStatefulWidget {
  const _SuggestionCard({required this.date, required this.suggestion});

  final String date;
  final CheckinSuggestion suggestion;

  @override
  ConsumerState<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends ConsumerState<_SuggestionCard> {
  bool _saving = false;

  Future<void> _accept() async {
    setState(() => _saving = true);
    final a = widget.suggestion.assignment;
    try {
      await ref
          .read(vivApiProvider)
          .editDay(
            DaySlotEdit(
              date: widget.date,
              activityType: a.activityType,
              intensity: a.intensity,
              impact: a.impact,
            ),
          );
      ref.invalidate(currentWeekProvider);
      ref.invalidate(homeTodayProvider);
      ref.invalidate(dayDetailProvider(widget.date));
      await ref.read(todayCheckinProvider.notifier).applySuggestion();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final a = widget.suggestion.assignment;
    return VivCard(
      tone: VivCardTone.highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Eyebrow('VIV suggests', accent: true),
          const SizedBox(height: VivSpace.xs),
          Text(
            sessionTitle(activityType: a.activityType, intensity: a.intensity),
            style: VivType.cardTitle.copyWith(color: c.textPrimary),
          ),
          if (widget.suggestion.reason != null) ...[
            const SizedBox(height: VivSpace.xxs),
            Text(
              widget.suggestion.reason!,
              style: VivType.caption.copyWith(color: c.textSecondary),
            ),
          ],
          const SizedBox(height: VivSpace.md),
          VivButton(label: 'Switch to this', height: 44, loading: _saving, onPressed: _accept),
        ],
      ),
    );
  }
}
