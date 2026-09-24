import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/catalog.dart';
import '../../data/models/checkin.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';

/// C1–C3 · Progressive quick check-in, then D1 · completion moment.
///
/// Questions stack as they're answered: answered ones collapse to a summary
/// row with "Change", the current one is expanded, upcoming ones are dimmed.
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _Question {
  const _Question(this.prompt, this.options);

  final String prompt;

  /// Answer value → label.
  final List<(Enum, String)> options;

  String labelOf(Enum value) => options.firstWhere((o) => o.$1 == value).$2;
}

final _questions = [
  _Question('How did you sleep last night?', [for (final a in SleepAnswer.values) (a, a.label)]),
  _Question('How does your body feel?', [for (final a in BodyAnswer.values) (a, a.label)]),
  _Question('How demanding is today?', [for (final a in DemandAnswer.values) (a, a.label)]),
  _Question('What do you need from today\'s session?', [
    for (final a in NeedAnswer.values) (a, a.label),
  ]),
];

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  final _answers = List<Enum?>.filled(4, null);
  int _current = 0;
  bool _submitting = false;
  DailyCheckinResult? _result;

  bool get _complete => _answers.every((a) => a != null);

  void _answer(int index, Enum value) {
    setState(() {
      _answers[index] = value;
      // Move to the next unanswered question; -1 once all four are in.
      _current = _answers.indexWhere((a) => a == null);
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(todayCheckinProvider.notifier)
          .submit(
            DailyCheckinRequest(
              date: Dates.todayYmd(),
              sleep: _answers[0]! as SleepAnswer,
              body: _answers[1]! as BodyAnswer,
              demand: _answers[2]! as DemandAnswer,
              need: _answers[3]! as NeedAnswer,
            ),
          );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _CompletionMoment(
        result: _result!,
        sleep: _answers[0]! as SleepAnswer,
        demand: _answers[2]! as DemandAnswer,
      );
    }
    final c = context.viv;

    return VivPage(
      topTrailing: VivButton.text(label: 'Skip', onPressed: () => context.pop()),
      bottom: _complete
          ? VivButton(label: 'See today\'s plan', loading: _submitting, onPressed: _submit)
          : null,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: PageHeader(
                title: 'Quick check-in',
                subtitle: 'Four taps. Then today\'s plan.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: VivSpace.lg + 4),
              child: Text(
                '${_current == -1 ? 4 : _current + 1} of 4',
                style: VivType.caption.copyWith(color: c.textTertiary),
              ),
            ),
          ],
        ),
        for (var i = 0; i < _questions.length; i++) ...[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            // Default layout centers children loosely; keep cards full width.
            layoutBuilder: (current, previous) =>
                Stack(fit: StackFit.passthrough, children: [...previous, ?current]),
            child: _buildQuestion(i, c),
          ),
          const SizedBox(height: VivSpace.xs),
        ],
      ],
    );
  }

  Widget _buildQuestion(int i, VivColors c) {
    final q = _questions[i];
    final answer = _answers[i];

    if (i == _current) {
      return VivCard(
        key: ValueKey('open$i'),
        tone: VivCardTone.highlight,
        padding: const EdgeInsets.all(VivSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, VivSpace.sm),
              child: Text(
                q.prompt,
                style: VivType.label.copyWith(color: c.textPrimary, fontSize: 14),
              ),
            ),
            for (final (value, label) in q.options) ...[
              OptionTile(
                title: label,
                selected: answer == value,
                showRadio: false,
                filledWhenSelected: true,
                onTap: () => _answer(i, value),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      );
    }

    if (answer != null) {
      return VivCard(
        key: ValueKey('done$i'),
        padding: const EdgeInsets.symmetric(horizontal: VivSpace.md, vertical: VivSpace.sm),
        onTap: () => setState(() => _current = i),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.prompt,
                    style: VivType.caption.copyWith(color: c.textTertiary, fontSize: 11.5),
                  ),
                  Text(
                    q.labelOf(answer),
                    style: VivType.bodySmall.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Change',
              style: VivType.caption.copyWith(color: c.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return VivCard(
      key: ValueKey('todo$i'),
      tone: VivCardTone.muted,
      padding: const EdgeInsets.symmetric(horizontal: VivSpace.md, vertical: VivSpace.sm),
      child: Text(q.prompt, style: VivType.caption.copyWith(color: c.textTertiary, fontSize: 13)),
    );
  }
}

/// D1 · "Restless night, packed day. Here's today."
class _CompletionMoment extends StatelessWidget {
  const _CompletionMoment({required this.result, required this.sleep, required this.demand});

  final DailyCheckinResult result;
  final SleepAnswer sleep;
  final DemandAnswer demand;

  String get _headline {
    final night = switch (sleep) {
      SleepAnswer.deepAndRestful => 'Deep sleep',
      SleepAnswer.normal => 'Normal night',
      SleepAnswer.restless => 'Restless night',
      SleepAnswer.barelySlept => 'Barely slept',
    };
    final day = switch (demand) {
      DemandAnswer.lightAndOpen => 'open day',
      DemandAnswer.normal => 'normal day',
      DemandAnswer.packed => 'packed day',
      DemandAnswer.unpredictable => 'unpredictable day',
    };
    return '$night, $day. Here\'s today.';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final a = result.assignment;
    final title = sessionTitle(
      activityType: a?.activityType,
      intensity: a?.intensity,
      isRestDay: result.isRestDay,
    );

    return VivPage(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VivButton(
            label: result.isRestDay ? 'Back to today' : 'Start session',
            onPressed: () {
              if (result.isRestDay) {
                context.pop();
              } else {
                context.pushReplacement(Routes.sessionDetail(result.date));
              }
            },
          ),
          if (result.reason != null)
            VivButton.text(
              label: 'Why it changed',
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                    VivSpace.gutter,
                    0,
                    VivSpace.gutter,
                    VivSpace.xxl,
                  ),
                  child: Text(result.reason!, style: VivType.body.copyWith(color: c.textPrimary)),
                ),
              ),
            ),
        ],
      ),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
        Eyebrow(Dates.eyebrow(Dates.today()), accent: true),
        const SizedBox(height: VivSpace.xs),
        Text(_headline, style: VivType.title.copyWith(color: c.textPrimary)),
        const SizedBox(height: VivSpace.xs),
        Text(
          result.suggestion != null
              ? 'VIV has a lighter option if you want it — it\'s on Today.'
              : 'Same purpose, sized to the day you actually have.',
          style: VivType.bodySmall.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: VivSpace.lg),
        VivCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: Eyebrow('Today')),
                  if (result.suggestion != null || result.regenerated)
                    Text(
                      result.regenerated ? 'New week' : 'Suggestion ready',
                      style: VivType.caption.copyWith(color: c.primary, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: VivSpace.xs),
              Text(title, style: VivType.cardTitle.copyWith(color: c.textPrimary)),
              if (a?.intensity != null) ...[
                const SizedBox(height: VivSpace.xxs),
                Text(
                  Intensity.labelFor(a!.intensity),
                  style: VivType.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
