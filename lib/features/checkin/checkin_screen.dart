import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/models/catalog.dart';
import '../../data/models/checkin.dart';
import '../../data/models/home.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/providers.dart';
import '../home/home_timeline.dart' show dismissedMomentsProvider;
import 'checkin_copy.dart';

/// 03 · Check-in → Proposal → Why today.
///
/// A full-screen wine field asks one question at a time; tapping an answer
/// advances on its own. After the fourth, the proposal cross-fades in while
/// `POST /checkin` runs: the headline is built from her answers straight
/// away, the rest plays out once the backend has decided whether today
/// changes (`suggestion`).
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

const _options = <List<Enum>>[
  SleepAnswer.values,
  BodyAnswer.values,
  DemandAnswer.values,
  NeedAnswer.values,
];

String _label(Enum e) => switch (e) {
  SleepAnswer a => a.label,
  BodyAnswer a => a.label,
  DemandAnswer a => a.label,
  NeedAnswer a => a.label,
  _ => e.name,
};

String _short(Enum e) => switch (e) {
  SleepAnswer a => a.short,
  BodyAnswer a => a.short,
  DemandAnswer a => a.short,
  NeedAnswer a => a.short,
  _ => e.name,
};

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  final _answers = List<Enum?>.filled(4, null);
  int _step = 0;

  /// The 300 ms hold after a tap: further taps are ignored.
  bool _holding = false;
  bool _showProposal = false;

  @override
  void initState() {
    super.initState();
    // Warm today's plan for the "Planned" card.
    unawaited(ref.read(dayDetailProvider(Dates.todayYmd()).future).catchError((_) => null));
  }

  void _pick(int question, Enum answer) {
    if (_holding) return;
    _holding = true;
    HapticFeedback.selectionClick();
    setState(() => _answers[question] = answer);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _holding = false;
      setState(() {
        if (question < 3) {
          _step = question + 1;
        } else {
          _showProposal = true;
        }
      });
    });
  }

  Future<void> _skip() async {
    final date = Dates.todayYmd();
    ref.read(dismissedMomentsProvider.notifier).dismiss(date, TimelineKind.checkin);
    await ref.read(todayLoopProvider.notifier).decide(TodayDecision.skipped);
    if (!mounted) return;
    VivToast.show(context, CheckinCopy.toastSkipped);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      child: _showProposal
          ? _ProposalView(
              key: const ValueKey('proposal'),
              request: DailyCheckinRequest(
                date: Dates.todayYmd(),
                sleep: _answers[0]! as SleepAnswer,
                body: _answers[1]! as BodyAnswer,
                demand: _answers[2]! as DemandAnswer,
                need: _answers[3]! as NeedAnswer,
              ),
            )
          : _QuestionsView(
              key: const ValueKey('questions'),
              step: _step,
              answers: _answers,
              onPick: _pick,
              onSkip: _skip,
            ),
    );
  }
}

// ── Questions: the full-screen wine field ──────────────────────────────────

class _QuestionsView extends StatelessWidget {
  const _QuestionsView({
    super.key,
    required this.step,
    required this.answers,
    required this.onPick,
    required this.onSkip,
  });

  final int step;
  final List<Enum?> answers;
  final void Function(int question, Enum answer) onPick;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: VivTheme.overlayOnField,
      child: Scaffold(
        backgroundColor: c.field,
        body: Stack(
          children: [
            const Positioned(
              top: -120,
              right: -120,
              child: FieldGlow(size: 320, blur: 60, opacity: 0.6, period: Duration(seconds: 10)),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 180),
                                child: _Progress(answers: answers, step: step),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onSkip,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: VivSize.minTap),
                              child: Center(
                                widthFactor: 1,
                                child: Text(
                                  'Skip today',
                                  style: VivType.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: VivColors.onField,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 34),
                      child: Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (var i = 0; i < step; i++)
                            if (answers[i] case final a?)
                              _AnswerChip(key: ValueKey('chip$i'), label: _short(a)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 420),
                            layoutBuilder: (current, previous) => current ?? const SizedBox(),
                            transitionBuilder: (child, _) => child,
                            child: _Question(
                              key: ValueKey('q$step'),
                              index: step,
                              selected: answers[step],
                              onPick: (a) => onPick(step, a),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      CheckinCopy.footer,
                      style: VivType.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: VivColors.onFieldMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Four segments that fill (scaleX, 420 ms) as answers come in.
class _Progress extends StatelessWidget {
  const _Progress({required this.answers, required this.step});

  final List<Enum?> answers;
  final int step;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Question ${step + 1} of 4',
      child: Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const Flexible(child: SizedBox(width: 6)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(VivRadius.pill),
                child: Container(
                  height: 5,
                  color: VivColors.onFieldFaint,
                  alignment: Alignment.centerLeft,
                  child: AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 420),
                    curve: VivMotion.curve,
                    widthFactor: (i < step || answers[i] != null) ? 1 : 0,
                    child: Container(color: VivColors.onField),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({super.key, required this.index, required this.selected, required this.onPick});

  final int index;
  final Enum? selected;
  final ValueChanged<Enum> onPick;

  @override
  Widget build(BuildContext context) {
    return Enter.fromRight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${index + 1} of 4'.toUpperCase(),
            style: VivType.eyebrow.copyWith(fontSize: 13, color: VivColors.onFieldMuted),
          ),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(
              CheckinCopy.questions[index],
              style: VivType.question.copyWith(color: VivColors.onField),
            ),
          ),
          const SizedBox(height: 22),
          for (final (k, option) in _options[index].indexed) ...[
            if (k > 0) const SizedBox(height: 9),
            Enter(
              delay: Duration(milliseconds: 120 + k * 55),
              duration: const Duration(milliseconds: 380),
              child: _OptionPill(
                label: _label(option),
                selected: selected == option,
                onTap: () => onPick(option),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 60 px pill: fills onField (180 ms) and scales to 1.02 when picked.
class _OptionPill extends StatelessWidget {
  const _OptionPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? VivColors.onFieldInv : VivColors.onField;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.02 : 1,
          duration: VivMotion.fill,
          curve: VivMotion.curve,
          child: AnimatedContainer(
            duration: VivMotion.fill,
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? VivColors.onField : VivColors.onFieldOption,
              borderRadius: BorderRadius.circular(VivRadius.option),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: VivType.rowTitle.copyWith(fontSize: 18, letterSpacing: -0.18, color: fg),
                  ),
                ),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: VivMotion.fill,
                  child: Icon(Icons.check_rounded, size: 18, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An answer collected at the top: pops in (scale .6 → 1.06 → 1, 380 ms).
class _AnswerChip extends StatelessWidget {
  const _AnswerChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final reduced = VivMotion.reduced(context);
    final chip = Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: const ShapeDecoration(color: VivColors.onField, shape: StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 14, color: VivColors.onFieldInv),
          const SizedBox(width: 6),
          Text(
            label,
            style: VivType.body.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: VivColors.onFieldInv,
            ),
          ),
        ],
      ),
    );
    final pop = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.06), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 40),
    ]);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: VivMotion.curve,
      child: chip,
      builder: (context, t, child) => Opacity(
        opacity: math.min(1, t / 0.6),
        child: reduced ? child : Transform.scale(scale: pop.transform(t), child: child),
      ),
    );
  }
}

// ── Proposal ───────────────────────────────────────────────────────────────

class _ProposalView extends ConsumerStatefulWidget {
  const _ProposalView({super.key, required this.request});

  final DailyCheckinRequest request;

  @override
  ConsumerState<_ProposalView> createState() => _ProposalViewState();
}

/// Offsets of the proposal choreography, from the moment it appears.
abstract final class _At {
  static const headline = Duration(milliseconds: 80);
  static const body = Duration(milliseconds: 180);
  static const planned = Duration(milliseconds: 300);
  static const strike = Duration(milliseconds: 820);
  static const proposed = Duration(milliseconds: 1150);
  static const asPlanned = Duration(milliseconds: 320);
  static const buttons = Duration(milliseconds: 1300);

  /// Show the skeleton only if the backend takes longer than this.
  static const skeleton = Duration(milliseconds: 400);
}

class _ProposalViewState extends ConsumerState<_ProposalView> {
  final _started = Stopwatch()..start();
  DailyCheckinResult? _result;
  Object? _error;

  /// How much later than planned the backend answered; later elements
  /// shift by it so the sequence still plays in order.
  Duration _shift = Duration.zero;
  Duration _arrivedAt = Duration.zero;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _submit();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    try {
      final result = await ref.read(todayCheckinProvider.notifier).submit(widget.request);
      if (!mounted) return;
      final now = _started.elapsed;
      setState(() {
        _result = result;
        _arrivedAt = now;
        _shift = now > _At.body ? now - _At.body : Duration.zero;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// Delay, from now, for an element due at [offset] in the sequence.
  Duration _delay(Duration offset) {
    final d = offset + _shift - _arrivedAt;
    return d.isNegative ? Duration.zero : d;
  }

  String get _summary => widget.request.summary;

  Future<void> _accept() async {
    final suggestion = _result?.suggestion;
    if (suggestion == null) return;
    setState(() => _saving = true);
    try {
      final a = suggestion.assignment;
      final date = widget.request.date;
      await ref
          .read(vivApiProvider)
          .editDay(
            DaySlotEdit.fromSuggestion(
              date,
              activityType: a.activityType,
              intensity: a.intensity,
              impact: a.impact,
            ),
          );
      ref.invalidate(currentWeekProvider);
      ref.invalidate(homeTodayProvider);
      ref.invalidate(dayDetailProvider(date));
      await ref.read(todayCheckinProvider.notifier).applySuggestion();
      await ref
          .read(todayLoopProvider.notifier)
          .decide(TodayDecision.adjusted, summary: _summary, answers: widget.request);
      _done(CheckinCopy.toastSwapped);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e);
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _keep() async {
    await ref
        .read(todayLoopProvider.notifier)
        .decide(TodayDecision.kept, summary: _summary, answers: widget.request);
    _done(CheckinCopy.toastKept);
  }

  Future<void> _letsGo() async {
    await ref
        .read(todayLoopProvider.notifier)
        .decide(TodayDecision.asPlanned, summary: _summary, answers: widget.request);
    final home = ref.read(homeTodayProvider).value;
    final session = home?.timeline.where((i) => i.kind == TimelineKind.session).firstOrNull;
    _done(CheckinCopy.toastLockedIn(session?.time));
  }

  void _done(String toast) {
    if (!mounted) return;
    VivToast.show(context, toast);
    context.pop();
  }

  void _openWhy() {
    final r = widget.request;
    final result = _result;
    final reasons = CheckinCopy.reasons(
      sleep: r.sleep,
      body: r.body,
      demand: r.demand,
      need: r.need,
      adjusted: result?.suggestion != null,
      backendReason: result?.suggestion?.reason ?? result?.reason,
      phase: ref.read(homeTodayProvider).value?.currentPhase,
    );
    showWhyTodaySheet(context, reasons);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final r = widget.request;
    final weekday = Dates.longWeekday(Dates.parseYmd(r.date));
    final planned = ref.watch(dayDetailProvider(r.date)).value;
    final plannedTitle = planned == null ? null : _sessionLine(planned);
    final result = _result;
    final adjusted = result?.suggestion != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: VivTheme.overlayFor(Theme.of(context).brightness),
      child: Scaffold(
        backgroundColor: c.page,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Enter(
                          duration: const Duration(milliseconds: 480),
                          child: Text(
                            CheckinCopy.eyebrow(weekday).toUpperCase(),
                            style: VivType.eyebrow.copyWith(color: c.tintInk),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Enter(
                          delay: _At.headline,
                          duration: const Duration(milliseconds: 560),
                          child: Semantics(
                            header: true,
                            child: Text(
                              CheckinCopy.headline(r.sleep, r.demand),
                              style: VivType.hero.copyWith(color: c.ink),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_error != null)
                          _ProposalError(onRetry: _submit)
                        else if (result == null)
                          const Enter(delay: _At.skeleton, child: _ProposalSkeleton())
                        else ...[
                          Enter(
                            delay: _delay(_At.body),
                            duration: const Duration(milliseconds: 560),
                            child: Text(
                              adjusted
                                  ? CheckinCopy.proposalBody(
                                      planned: planned?.displayTitle ?? 'session',
                                      proposed: _assignmentTitle(result.suggestion!.assignment),
                                    )
                                  : CheckinCopy.asPlannedBody,
                              style: VivType.lead.copyWith(color: c.ink2),
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (adjusted) ...[
                            Enter(
                              delay: _delay(_At.planned),
                              child: _PlannedCard(
                                title: plannedTitle ?? 'Today\'s session',
                                strikeDelay: _delay(_At.strike),
                              ),
                            ),
                            const SizedBox(height: 10),
                            WineField(
                              compact: true,
                              enterDelay: _delay(_At.proposed),
                              tag: 'Proposed',
                              title: _assignmentTitle(result.suggestion!.assignment),
                              body: result.suggestion!.reason,
                              onWhy: _openWhy,
                            ),
                          ] else
                            WineField(
                              compact: true,
                              enterDelay: _delay(_At.asPlanned),
                              tag: 'As planned',
                              title: plannedTitle ?? _assignmentTitle(result.assignment!),
                              body: result.reason,
                              onWhy: _openWhy,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (result != null)
                  Enter(
                    delay: _delay(_At.buttons),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PillButton(
                            label: adjusted ? 'Sounds good' : 'Let\'s go',
                            busy: _saving,
                            onPressed: adjusted ? _accept : _letsGo,
                          ),
                          if (adjusted) ...[
                            const SizedBox(height: 8),
                            PillButton(
                              label: 'Keep the original',
                              variant: PillVariant.secondary,
                              size: PillSize.medium,
                              onPressed: _saving ? null : _keep,
                            ),
                          ],
                        ],
                      ),
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

/// "Lower strength · 60 min"
String _sessionLine(DayDetail d) =>
    [d.displayTitle, if (d.durationMinutes != null) '${d.durationMinutes} min'].join(' · ');

String _assignmentTitle(Assignment a) =>
    sessionTitle(activityType: a.activityType, intensity: a.intensity);

class _PlannedCard extends StatelessWidget {
  const _PlannedCard({required this.title, required this.strikeDelay});

  final String title;
  final Duration strikeDelay;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(VivRadius.tile),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PLANNED', style: VivType.eyebrow.copyWith(fontSize: 11.5, color: c.muted)),
          const SizedBox(height: 6),
          _StrikeThrough(
            delay: strikeDelay,
            color: c.muted,
            child: Text(title, style: VivType.rowTitle.copyWith(fontSize: 17, color: c.muted)),
          ),
        ],
      ),
    );
  }
}

/// Draws a line across the old plan (scaleX 0 → 1, 520 ms) after [delay].
class _StrikeThrough extends StatefulWidget {
  const _StrikeThrough({required this.child, required this.delay, required this.color});

  final Widget child;
  final Duration delay;
  final Color color;

  @override
  State<_StrikeThrough> createState() => _StrikeThroughState();
}

class _StrikeThroughState extends State<_StrikeThrough> with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) _draw.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = CurvedAnimation(parent: _draw, curve: VivMotion.strikeCurve);
    return Semantics(
      label: 'Replaced',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          Positioned(
            left: -2,
            right: -2,
            top: 0,
            bottom: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: line,
                builder: (context, _) => Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.diagonal3Values(line.value, 1, 1),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalSkeleton extends StatelessWidget {
  const _ProposalSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox.line(),
          SizedBox(height: 8),
          SkeletonBox.line(width: 220),
          SizedBox(height: 26),
          SkeletonBox(height: 78, radius: VivRadius.tile),
          SizedBox(height: 10),
          SkeletonBox(height: 190, radius: VivRadius.card),
        ],
      ),
    );
  }
}

class _ProposalError extends StatelessWidget {
  const _ProposalError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your answers didn\'t reach VIV. Nothing changed yet.',
          style: VivType.lead.copyWith(color: c.ink2),
        ),
        const SizedBox(height: 16),
        PillButton(label: 'Try again', size: PillSize.control, onPressed: onRetry),
        const SizedBox(height: 8),
        PillButton(
          label: 'Back to today',
          variant: PillVariant.secondary,
          size: PillSize.control,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

// ── Why today ──────────────────────────────────────────────────────────────

/// 2–3 numbered reasons and one legal line.
Future<void> showWhyTodaySheet(BuildContext context, List<(String, String)> reasons) {
  return showVivSheet<void>(
    context,
    builder: (sheetContext) {
      final c = sheetContext.viv;
      return VivBottomSheet(
        eyebrow: 'Why today',
        title: 'What VIV weighed',
        actions: [
          PillButton(
            label: 'Got it',
            size: PillSize.control,
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ],
        children: [
          for (final (i, (title, body)) in reasons.indexed)
            Enter(
              delay: Duration(milliseconds: 120 + i * 90),
              duration: const Duration(milliseconds: 420),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.field, shape: BoxShape.circle),
                    child: Text(
                      '${i + 1}',
                      style: VivType.meta.copyWith(
                        fontWeight: FontWeight.w800,
                        color: VivColors.onField,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: VivType.rowTitle.copyWith(
                            fontWeight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(body, style: VivType.body.copyWith(fontSize: 14, color: c.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Text(CheckinCopy.whyLegal, style: VivType.legal.copyWith(color: c.muted)),
        ],
      );
    },
  );
}
