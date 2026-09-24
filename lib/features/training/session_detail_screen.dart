import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';

/// 01 · Session detail — warm-up, main work, cool-down.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.date});

  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(dayDetailProvider(date));
    return detail.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(
        body: ErrorView(error: e, onRetry: () => ref.invalidate(dayDetailProvider(date))),
      ),
      data: (d) => d == null
          ? const VivPage(
              showBack: true,
              children: [
                PageHeader(title: 'No session', subtitle: 'Nothing is planned for this day yet.'),
              ],
            )
          : _Detail(day: d),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.day});

  final DayDetail day;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final isToday = day.date == Dates.todayYmd();
    final session = day.session;
    final chips = [
      ?day.loadLabel,
      if (day.durationMinutes != null)
        '${day.durationIsEstimated ? '~' : ''}${day.durationMinutes} min',
      if (day.mainExercises.isNotEmpty) '${day.mainExercises.length} exercises',
    ];

    Widget? bottom;
    if (day.loggable && isToday) {
      bottom = VivButton(
        label: session == null
            ? 'Start session'
            : session.isCompleted
            ? 'Done for today'
            : 'Resume session',
        onPressed: session?.isCompleted == true
            ? null
            : () => context.push(Routes.liveSession(day.date)),
      );
    }

    return VivPage(
      showBack: true,
      bottom: bottom,
      children: [
        PageHeader(
          eyebrow: Eyebrow('${Dates.capitalize(day.weekday)} · session', accent: true),
          title: day.title ?? day.displayTitle,
        ),
        if (chips.isNotEmpty)
          Transform.translate(
            offset: const Offset(0, -VivSpace.xs),
            child: Wrap(spacing: 6, runSpacing: 6, children: [for (final t in chips) _Chip(t)]),
          ),
        if (day.warning != null) ...[
          const SizedBox(height: VivSpace.xs),
          Text(day.warning!, style: VivType.bodySmall.copyWith(color: c.textSecondary)),
        ],
        const SizedBox(height: VivSpace.md),
        if (day.warmup case final w?) _BlockCard(label: 'Warm-up', block: w),
        if (day.mainExercises.isNotEmpty) ...[
          const SizedBox(height: VivSpace.lg),
          const Eyebrow('Main work'),
          const SizedBox(height: VivSpace.xs),
          for (final e in day.mainExercises)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: VivSpace.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.name,
                        style: VivType.bodySmall.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(e.prescription, style: VivType.caption.copyWith(color: c.textTertiary)),
                  ],
                ),
              ),
            ),
        ],
        if (day.cooldown case final cd?) ...[
          const SizedBox(height: VivSpace.lg),
          _BlockCard(label: 'Cool-down', block: cd),
        ],
        if (!day.loggable && !day.isRestDay) ...[
          const SizedBox(height: VivSpace.lg),
          Text(
            'Doing your own thing today? Keep it close to this — the intent is what matters, not the list.',
            style: VivType.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(VivRadius.sm),
      ),
      child: Text(text, style: VivType.caption.copyWith(color: c.textPrimary, fontSize: 12)),
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({required this.label, required this.block});

  final String label;
  final ExerciseBlock block;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final meta = [
      if (block.durationMinutes != null) '${block.durationMinutes} min',
      if (block.movements.isNotEmpty) '${block.movements.length} moves',
    ].join(' · ');
    return VivCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Eyebrow(label)),
              Text(meta, style: VivType.caption.copyWith(color: c.textTertiary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: VivSpace.xs),
          Text(
            block.movements.isNotEmpty ? block.movements.join(' · ') : (block.description ?? ''),
            style: VivType.bodySmall.copyWith(color: c.textPrimary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
