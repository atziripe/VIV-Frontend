import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/models/cycle.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';

/// 07 · Log sheet: "When did it start?" → `POST /cycle/period-start`, then
/// the Rebuilt screen.
Future<void> showPeriodStartSheet(BuildContext context) {
  return showVivSheet<void>(context, builder: (_) => const _PeriodStartSheet());
}

enum _When { today, yesterday, earlier }

class _PeriodStartSheet extends ConsumerStatefulWidget {
  const _PeriodStartSheet();

  @override
  ConsumerState<_PeriodStartSheet> createState() => _PeriodStartSheetState();
}

class _PeriodStartSheetState extends ConsumerState<_PeriodStartSheet> {
  _When _when = _When.today;
  DateTime? _earlier;
  bool _saving = false;

  DateTime get _date => switch (_when) {
    _When.today => Dates.today(),
    _When.yesterday => Dates.today().subtract(const Duration(days: 1)),
    _When.earlier => _earlier ?? Dates.today().subtract(const Duration(days: 2)),
  };

  Future<void> _pickEarlier() async {
    final today = Dates.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _earlier ?? today.subtract(const Duration(days: 2)),
      firstDate: today.subtract(const Duration(days: 30)),
      lastDate: today.subtract(const Duration(days: 2)),
    );
    if (picked != null) setState(() => _earlier = picked);
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final navigator = Navigator.of(context, rootNavigator: true);
    final date = _date;
    final isToday = _when == _When.today;
    try {
      final result = await ref.read(vivApiProvider).logPeriodStart(date: Dates.ymd(date));
      ref.invalidate(meProvider);
      ref.invalidate(currentWeekProvider);
      ref.invalidate(homeTodayProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => PeriodRebuiltScreen(result: result, date: date, isToday: isToday),
        ),
      );
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = Dates.today();
    final yesterday = today.subtract(const Duration(days: 1));
    String day(DateTime d) => '${Dates.shortWeekday(d)} ${Dates.dayMonth(d)}';
    return VivBottomSheet(
      title: 'When did it start?',
      body: 'Your week rebuilds from this day. Close enough is fine.',
      actions: [PillButton(label: 'Confirm', busy: _saving, onPressed: _confirm)],
      children: [
        Column(
          children: [
            OptionRow(
              label: 'Today',
              hint: day(today),
              selected: _when == _When.today,
              onTap: () => setState(() => _when = _When.today),
            ),
            const SizedBox(height: 8),
            OptionRow(
              label: 'Yesterday',
              hint: day(yesterday),
              selected: _when == _When.yesterday,
              onTap: () => setState(() => _when = _When.yesterday),
            ),
            const SizedBox(height: 8),
            OptionRow(
              label: 'Earlier, pick a date',
              hint: _earlier == null ? null : day(_earlier!),
              selected: _when == _When.earlier,
              onTap: () {
                setState(() => _when = _When.earlier);
                _pickEarlier();
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// 07 · Rebuilt: what moved, and the new estimate. No Undo: there's no
/// endpoint to take a period start back.
class PeriodRebuiltScreen extends StatelessWidget {
  const PeriodRebuiltScreen({
    super.key,
    required this.result,
    required this.date,
    required this.isToday,
  });

  final PeriodStartResult result;
  final DateTime date;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final next = Dates.tryParseYmd(result.nextEstimatedPeriodDate);
    return VivPage(
      bottom: PillButton(
        label: 'See this week',
        onPressed: () {
          final router = GoRouter.of(context);
          Navigator.of(context).pop();
          router.go(Routes.train);
        },
      ),
      children: [
        const SizedBox(height: 26),
        Text(
          'Logged · ${Dates.dayMonth(date)}'.toUpperCase(),
          style: VivType.eyebrow.copyWith(color: c.accent),
        ),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          child: Text(
            result.weekRebuilt
                ? 'Got it. Your week starts over from ${isToday ? 'today' : Dates.dayMonth(date)}.'
                : 'Got it. Your week already fits.',
            style: VivType.h1.copyWith(fontSize: 34, color: c.ink),
          ),
        ),
        const SizedBox(height: 20),
        if (result.moved.isNotEmpty) ...[
          WineField(
            pulse: false,
            children: [
              Text('WHAT MOVED', style: VivType.eyebrow.copyWith(color: VivColors.onField)),
              for (final (i, day) in result.moved.indexed)
                Enter(
                  delay: VivMotion.fieldEnterDelay + Duration(milliseconds: 200 + 70 * i),
                  child: _MovedRow(day: day, first: i == 0),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (result.cycleDurationChanged && result.cycleDuration != null)
          VivNote(
            text:
                'VIV now reads you as a ${result.cycleDuration}-day cycle'
                '${next == null ? '' : '. Next estimate: around ${Dates.dayMonth(next)}'}.',
          )
        else if (next != null)
          VivNote(text: 'Next estimate: around ${Dates.dayMonth(next)}.'),
      ],
    );
  }
}

class _MovedRow extends StatelessWidget {
  const _MovedRow({required this.day, required this.first});

  final MovedDay day;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final date = Dates.tryParseYmd(day.date);
    final isToday = date != null && Dates.ymd(date) == Dates.todayYmd();
    final what = day.isRestDay
        ? 'Rest'
        : [
            day.title,
            if (day.durationMinutes != null) '${day.durationMinutes} min',
          ].whereType<String>().join(' · ');
    return Container(
      padding: EdgeInsets.only(top: first ? 0 : 10),
      decoration: BoxDecoration(
        border: first ? null : const Border(top: BorderSide(color: VivColors.onFieldTrack)),
      ),
      child: Row(
        children: [
          Text(
            isToday ? 'Today' : Dates.capitalize(day.weekday),
            style: VivType.body.copyWith(color: VivColors.onFieldSoft),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              what,
              textAlign: TextAlign.right,
              style: VivType.body.copyWith(fontWeight: FontWeight.w800, color: VivColors.onField),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Ask me again tomorrow": hides the late-period prompt for the rest of
/// today. Device only.
class LatePromptSnooze extends Notifier<bool> {
  static const _key = 'viv.cycle.prompt_snoozed_on';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getString(_key) == Dates.todayYmd();

  Future<void> snooze() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setString(_key, Dates.todayYmd());
  }
}

final latePromptSnoozedProvider = NotifierProvider<LatePromptSnooze, bool>(LatePromptSnooze.new);

/// 07 · "Not yet" → holding: the plan holds until she logs it.
Future<void> showHoldingSheet(BuildContext context) {
  return showVivSheet<void>(
    context,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) => VivBottomSheet(
        title: 'Then VIV holds your plan where it is',
        body:
            'Rather than guess, VIV keeps this week\'s shape until you log it. '
            'Cycles shift a few days either way; that\'s normal.',
        actions: [
          PillButton(label: 'Got it', onPressed: () => Navigator.of(sheetContext).pop()),
          PillButton(
            label: 'Ask me again tomorrow',
            variant: PillVariant.text,
            size: PillSize.compact,
            onPressed: () {
              ref.read(latePromptSnoozedProvider.notifier).snooze();
              Navigator.of(sheetContext).pop();
            },
          ),
        ],
        children: const [
          VivNote(
            eyebrow: 'What stays the same',
            text: 'Your sessions, your days, your meals. Nothing reshuffles while VIV waits.',
          ),
        ],
      ),
    ),
  );
}
