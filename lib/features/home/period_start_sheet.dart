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

/// "When did it start?" → `POST /cycle/period-start` → "Your week starts
/// over from today."
Future<void> showPeriodStartSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _PeriodStartSheet(),
  );
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
  PeriodStartResult? _result;

  DateTime get _date => switch (_when) {
    _When.today => Dates.today(),
    _When.yesterday => Dates.today().subtract(const Duration(days: 1)),
    _When.earlier => _earlier ?? Dates.today().subtract(const Duration(days: 2)),
  };

  Future<void> _pickEarlier() async {
    final today = Dates.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: today.subtract(const Duration(days: 2)),
      firstDate: today.subtract(const Duration(days: 30)),
      lastDate: today.subtract(const Duration(days: 2)),
    );
    if (picked != null) setState(() => _earlier = picked);
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final result = await ref.read(vivApiProvider).logPeriodStart(date: Dates.ymd(_date));
      ref.invalidate(meProvider);
      ref.invalidate(currentWeekProvider);
      setState(() => _result = result);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final result = _result;
    return Padding(
      padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 0, VivSpace.gutter, VivSpace.lg),
      child: result == null ? _picker(c) : _done(c, result),
    );
  }

  Widget _picker(VivColors c) {
    final yesterday = Dates.today().subtract(const Duration(days: 1));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('When did it start?', style: VivType.headline.copyWith(color: c.textPrimary)),
        const SizedBox(height: VivSpace.xxs),
        Text(
          'Your week rebuilds from this day. Close enough is fine.',
          style: VivType.bodySmall.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: VivSpace.lg),
        OptionTile(
          title: 'Today',
          subtitle: Dates.dayMonth(Dates.today()),
          selected: _when == _When.today,
          onTap: () => setState(() => _when = _When.today),
        ),
        const SizedBox(height: VivSpace.xs),
        OptionTile(
          title: 'Yesterday',
          subtitle: Dates.dayMonth(yesterday),
          selected: _when == _When.yesterday,
          onTap: () => setState(() => _when = _When.yesterday),
        ),
        const SizedBox(height: VivSpace.xs),
        OptionTile(
          title: 'Earlier than that',
          subtitle: _earlier == null ? 'Pick a date' : Dates.dayMonth(_earlier!),
          selected: _when == _When.earlier,
          onTap: () {
            setState(() => _when = _When.earlier);
            _pickEarlier();
          },
        ),
        const SizedBox(height: VivSpace.lg),
        VivButton(label: 'Confirm', loading: _saving, onPressed: _confirm),
      ],
    );
  }

  Widget _done(VivColors c, PeriodStartResult result) {
    final next = Dates.tryParseYmd(result.nextEstimatedPeriodDate);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Eyebrow(Dates.eyebrow(_date), accent: true),
        const SizedBox(height: VivSpace.xs),
        Text(
          result.weekRebuilt
              ? 'Got it. Your week starts over from ${_when == _When.today ? 'today' : Dates.dayMonth(_date)}.'
              : 'Got it. Your week already fits.',
          style: VivType.headline.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: VivSpace.md),
        if (result.moved.isNotEmpty)
          VivCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Eyebrow('What moved'),
                const SizedBox(height: VivSpace.xs),
                for (final day in result.moved)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            Dates.capitalize(day.weekday),
                            style: VivType.bodySmall.copyWith(color: c.textPrimary),
                          ),
                        ),
                        Text(
                          day.isRestDay
                              ? 'Rest'
                              : [
                                  day.title,
                                  if (day.durationMinutes != null) '${day.durationMinutes} min',
                                ].whereType<String>().join(' · '),
                          style: VivType.bodySmall.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (result.cycleDurationChanged && result.cycleDuration != null) ...[
          const SizedBox(height: VivSpace.sm),
          VivNote(
            text:
                'VIV now reads you as a ${result.cycleDuration}-day cycle'
                '${next == null ? '' : '. Next estimate: around ${Dates.dayMonth(next)}'}.',
          ),
        ],
        const SizedBox(height: VivSpace.lg),
        VivButton(
          label: 'See this week',
          onPressed: () {
            Navigator.of(context).pop();
            context.go(Routes.train);
          },
        ),
      ],
    );
  }
}
