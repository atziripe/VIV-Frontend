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
import '../../data/models/me.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';
import 'period_start_sheet.dart';

/// 03 · Home — before and after the daily check-in.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(meProvider);
    ref.invalidate(currentWeekProvider);
    ref.invalidate(nutritionPlanProvider);
    await ref.read(currentWeekProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).value;
    final week = ref.watch(currentWeekProvider);
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
                _Greeting(me: me, checkedIn: checkin != null),
                const SizedBox(height: VivSpace.lg),
                if (me != null && me.daysLate > 0 && !me.cycleEstimationDisabled) ...[
                  _LatePeriodCard(me: me),
                  const SizedBox(height: VivSpace.sm),
                ],
                if (checkin == null) ...[
                  const _BeforeYouStartCard(),
                  const SizedBox(height: VivSpace.sm),
                ],
                AsyncView<WeeklyPlan?>(
                  value: week,
                  onRetry: () => ref.invalidate(currentWeekProvider),
                  loading: const Padding(
                    padding: EdgeInsets.all(VivSpace.xxl),
                    child: LoadingView(),
                  ),
                  data: (plan) =>
                      plan == null ? const _NoWeekCard() : _TodayPlan(plan: plan, checkin: checkin),
                ),
                if (checkin != null) ...[
                  const SizedBox(height: VivSpace.sm),
                  VivCard(
                    tone: VivCardTone.muted,
                    onTap: () => context.push(Routes.checkin),
                    padding: const EdgeInsets.symmetric(
                      horizontal: VivSpace.md,
                      vertical: VivSpace.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Something changed today?',
                            style: VivType.caption.copyWith(color: c.textSecondary, fontSize: 13),
                          ),
                        ),
                        Text(
                          'Check in again',
                          style: VivType.caption.copyWith(
                            color: c.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.me, required this.checkedIn});

  final Me? me;
  final bool checkedIn;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final name = me?.firstName ?? '';
    final phase = me?.cyclePhase;
    final status = checkedIn
        ? 'Checked in · adjusted for today'
        : (me?.cycleDay != null && phase != null)
        ? 'Day ${me!.cycleDay} of ${phase.energyCopy}'
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(Dates.eyebrow(Dates.today())),
              const SizedBox(height: VivSpace.xs),
              Semantics(
                header: true,
                child: Text(
                  name.isEmpty ? 'Hey there' : 'Hey $name',
                  style: VivType.headline.copyWith(color: c.textPrimary),
                ),
              ),
              if (status != null) ...[
                const SizedBox(height: VivSpace.xxs),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(status, style: VivType.caption.copyWith(color: c.textSecondary)),
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

class _BeforeYouStartCard extends StatelessWidget {
  const _BeforeYouStartCard();

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return VivCard(
      tone: VivCardTone.highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Eyebrow('Before you start', accent: true),
          const SizedBox(height: VivSpace.xs),
          Text(
            'Four taps and today\'s session fits your day.',
            style: VivType.cardTitle.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: VivSpace.md),
          VivButton(label: 'Check in', height: 44, onPressed: () => context.push(Routes.checkin)),
        ],
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
                    const SnackBar(content: Text('Okay — we\'ll keep the week gentle.')),
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

class _TodayPlan extends ConsumerWidget {
  const _TodayPlan({required this.plan, required this.checkin});

  final WeeklyPlan plan;
  final DailyCheckinResult? checkin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.viv;
    final today = plan.today;
    final next = plan.nextSession;
    final nutrition = ref.watch(nutritionPlanProvider).value;
    final nutritionToday = nutrition?.dayFor(Dates.longWeekday(Dates.today()).toLowerCase());
    final protein = nutritionToday?.macros?.proteinG;

    // After a check-in, the response is the source of truth for today.
    final isRest = checkin?.isRestDay ?? today?.isRestDay ?? true;
    final assignment = checkin?.assignment;
    final title = sessionTitle(
      activityType: assignment?.activityType ?? today?.activityType,
      muscleGroup: today?.muscleGroup,
      intensity: assignment?.intensity ?? today?.intensity,
      isRestDay: isRest,
    );
    final duration = today?.durationMinutes;
    final reason =
        checkin?.reason ??
        (checkin == null ? 'Built last Sunday. Check in and VIV fits it to today.' : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VivCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: Eyebrow('Today')),
                  Text(
                    checkin == null ? 'As planned' : 'Adjusted',
                    style: VivType.caption.copyWith(
                      color: checkin == null ? c.textTertiary : c.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VivSpace.xs),
              Text(
                duration == null || isRest ? title : '$title · $duration min',
                style: VivType.cardTitle.copyWith(color: c.textPrimary),
              ),
              if (reason != null) ...[
                const SizedBox(height: VivSpace.xxs),
                Text(reason, style: VivType.caption.copyWith(color: c.textSecondary)),
              ],
              if (!isRest && today != null) ...[
                const SizedBox(height: VivSpace.md),
                if (checkin == null)
                  VivButton.secondary(
                    label: 'Start as planned',
                    height: 44,
                    onPressed: () => context.push(Routes.sessionDetail(today.date)),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: VivButton(
                          label: 'Start',
                          height: 44,
                          onPressed: () => context.push(Routes.sessionDetail(today.date)),
                        ),
                      ),
                      const SizedBox(width: VivSpace.xs),
                      Expanded(
                        flex: 2,
                        child: VivButton.secondary(
                          label: 'Not today',
                          height: 44,
                          onPressed: () => context.go(Routes.recover),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
        if (checkin?.suggestion case final suggestion?) ...[
          const SizedBox(height: VivSpace.sm),
          _SuggestionCard(date: checkin!.date, suggestion: suggestion),
        ],
        const SizedBox(height: VivSpace.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MiniCard(
                  eyebrow: 'Eat',
                  title: protein == null ? 'Set up meals' : '${protein.round()} g protein',
                  subtitle: protein == null ? 'Two minutes, optional' : 'the one to protect today',
                  onTap: () => context.go(Routes.eat),
                ),
              ),
              const SizedBox(width: VivSpace.sm),
              Expanded(
                child: _MiniCard(
                  eyebrow: 'Next',
                  title: next == null ? 'Rest' : Dates.shortWeekday(next.dateTime),
                  subtitle: next == null
                      ? 'Nothing else this week'
                      : [
                          next.title,
                          if (next.durationMinutes != null) '${next.durationMinutes} min',
                        ].join(' · '),
                  onTap: () => context.go(Routes.train),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.eyebrow, required this.title, required this.subtitle, this.onTap});

  final String eyebrow;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return VivCard(
      onTap: onTap,
      padding: const EdgeInsets.all(VivSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(eyebrow),
          const SizedBox(height: VivSpace.xxs),
          Text(title, style: VivType.cardTitle.copyWith(color: c.textPrimary, fontSize: 16)),
          const SizedBox(height: 2),
          Text(subtitle, style: VivType.caption.copyWith(color: c.textTertiary, fontSize: 12)),
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
