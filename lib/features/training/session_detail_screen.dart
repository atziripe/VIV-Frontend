import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';
import '../checkin/checkin_copy.dart';
import '../checkin/checkin_screen.dart' show showWhyTodaySheet;

/// 01 · Session detail — warm-up, main work, cool-down.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.date});

  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(dayDetailProvider(date));
    return detail.when(
      loading: () => const _DetailSkeleton(),
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

class _Detail extends ConsumerWidget {
  const _Detail({required this.day});

  final DayDetail day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.viv;
    final isToday = day.date == Dates.todayYmd();
    final session = day.session;
    final loop = ref.watch(todayLoopProvider);
    final chips = [
      ?day.loadLabel,
      if (day.durationMinutes != null)
        '${day.durationIsEstimated ? '~' : ''}${day.durationMinutes} min',
      if (day.mainExercises.isNotEmpty) '${day.mainExercises.length} moves',
      if ((day.strengthBlockNumber, day.strengthWeek) case (final b?, final w?))
        'Block $b · week $w',
    ];
    final adjustments = [
      for (final t in day.strengthTierChanges)
        if (t.detail != null) t.detail!,
    ];
    final traceability = [
      if (day.strengthConfigStatus case final s?) strengthStatusText(s),
      if (day.strengthWarmupCooldownStatus case final s?)
        'Warm-up and cool-down: ${strengthStatusText(s, sentence: false)}.',
      if (day.strengthRestSecondsStatus case final s?)
        'Rest times: ${strengthStatusText(s, sentence: false)}.',
    ];

    Widget? bottom;
    if (day.loggable && isToday) {
      final done = session?.isCompleted == true;
      bottom = PillButton(
        label: session == null
            ? 'Start session'
            : done
            ? 'Done for today'
            : 'Resume session',
        arrow: !done,
        onPressed: done ? null : () => context.push(Routes.liveSession(day.date)),
      );
    }

    VoidCallback? why;
    final a = loop?.answers;
    if (isToday && a != null) {
      why = () => showWhyTodaySheet(
        context,
        CheckinCopy.reasons(
          sleep: a.sleep,
          body: a.body,
          demand: a.demand,
          need: a.need,
          adjusted: loop?.decision == TodayDecision.adjusted,
          backendReason: ref.read(todayCheckinProvider)?.reason,
          phase: ref.read(homeTodayProvider).value?.currentPhase,
        ),
      );
    }

    return VivPage(
      showBack: true,
      bottom: bottom,
      children: [
        Text(
          '${Dates.capitalize(day.weekday)} · session'.toUpperCase(),
          style: VivType.eyebrow.copyWith(color: c.tintInk),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            day.title ?? day.displayTitle,
            style: VivType.h1.copyWith(fontSize: 36, color: c.ink),
          ),
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 7, runSpacing: 7, children: [for (final t in chips) _Chip(t)]),
        ],
        if (day.warning != null) ...[
          const SizedBox(height: 16),
          Text(day.warning!, style: VivType.lead.copyWith(fontSize: 15.5, color: c.ink2)),
        ],
        if (why != null) ...[const SizedBox(height: 4), WhyLink(onTap: why, color: c.ink)],
        if (adjustments.isNotEmpty) ...[
          const SizedBox(height: 16),
          VivNote(eyebrow: 'Adjusted today', text: adjustments.join('\n')),
        ],
        // Shown once for the whole session, before the first exercise.
        if (day.strengthRampUpNote case final note?) ...[
          const SizedBox(height: 12),
          VivNote(text: note),
        ],
        const SizedBox(height: 18),
        SettingsGroup(
          children: [
            if (day.warmup case final w?) _BlockHeader(label: 'Warm-up', block: w),
            for (final e in day.mainExercises) _ExerciseRow(exercise: e),
            if (day.cooldown case final cd?) _BlockHeader(label: 'Cool-down', block: cd),
          ],
        ),
        if (!day.loggable && !day.isRestDay) ...[
          const SizedBox(height: 14),
          Text(
            'Doing your own thing? Keep it moderate. The zone matters more than the list.',
            style: VivType.meta.copyWith(fontSize: 13.5, height: 1.5, color: c.muted),
          ),
        ],
        if (traceability.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(traceability.join(' '), style: VivType.legal.copyWith(color: c.subtle)),
        ],
      ],
    );
  }
}

/// The plan's traceability flag in words: "draft_not_reviewed_by_sport_scientist"
/// → "Draft program, not yet reviewed by a sport scientist." Unknown flags
/// are shown with their underscores turned into spaces, never dropped.
String strengthStatusText(String status, {bool sentence = true}) {
  final text = switch (status) {
    'draft_not_reviewed_by_sport_scientist' =>
      'Draft program, not yet reviewed by a sport scientist',
    _ => status.replaceAll('_', ' '),
  };
  if (!sentence) return text.isEmpty ? text : '${text[0].toLowerCase()}${text.substring(1)}';
  return '${Dates.capitalize(text)}.';
}

/// Name, then (on the real Strength path) the verbatim prescription, its
/// equipment and an Accessory/Optional tag. Older days keep "3 × 8–10" on the
/// right.
class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final e = exercise;
    final name = Text(e.name, style: VivType.rowTitle.copyWith(fontSize: 15.5, color: c.ink));
    if (e.prescriptionText == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(flex: 3, child: name),
            const SizedBox(width: 14),
            Flexible(
              flex: 2,
              child: Text(
                e.prescription,
                textAlign: TextAlign.end,
                style: VivType.meta.copyWith(fontWeight: FontWeight.w600, color: c.subtle),
              ),
            ),
          ],
        ),
      );
    }
    final tag = switch (e.priority) {
      ExercisePriority.accessory || ExercisePriority.optional => e.priority!.value,
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                name,
                const SizedBox(height: 3),
                Text(
                  e.prescriptionText!,
                  style: VivType.meta.copyWith(fontWeight: FontWeight.w600, color: c.ink2),
                ),
                if (e.equipment.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(e.equipment.join(' · '), style: VivType.meta.copyWith(color: c.subtle)),
                ],
              ],
            ),
          ),
          if (tag != null) ...[const SizedBox(width: 12), _Chip(tag)],
        ],
      ),
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
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: ShapeDecoration(color: c.sunken, shape: const StadiumBorder()),
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          style: VivType.meta.copyWith(fontWeight: FontWeight.w700, color: c.ink2),
        ),
      ),
    );
  }
}

/// "WARM-UP · 5 min" row inside the session list.
class _BlockHeader extends StatelessWidget {
  const _BlockHeader({required this.label, required this.block});

  final String label;
  final ExerciseBlock block;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label.toUpperCase(), style: VivType.eyebrow.copyWith(color: c.subtle)),
              ),
              if (block.durationMinutes != null)
                Text('${block.durationMinutes} min', style: VivType.meta.copyWith(color: c.subtle)),
            ],
          ),
          if (block.movements.isNotEmpty || block.description != null) ...[
            const SizedBox(height: 6),
            Text(
              block.movements.isNotEmpty ? block.movements.join(' · ') : block.description!,
              style: VivType.body.copyWith(fontSize: 14, color: c.ink2),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const VivPage(
      showBack: true,
      children: [
        Skeleton(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox.line(width: 130, height: 12),
              SizedBox(height: 12),
              SkeletonBox(width: 240, height: 38, radius: VivRadius.md),
              SizedBox(height: 14),
              SkeletonBox.line(width: 200, height: 32),
              SizedBox(height: 24),
              SkeletonBox(height: 260, radius: VivRadius.group),
            ],
          ),
        ),
      ],
    );
  }
}
