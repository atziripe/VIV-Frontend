import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/models/home.dart';
import '../../data/models/recovery.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';

/// Moments the user skipped on this device today ("Skip" on the check-in
/// card). Kept in memory only; the backend has no "skip" concept.
class DismissedMoments extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  static String keyFor(String date, TimelineKind kind) => '$date|${kind.name}';

  void dismiss(String date, TimelineKind kind) => state = {...state, keyFor(date, kind)};
}

final dismissedMomentsProvider = NotifierProvider<DismissedMoments, Set<String>>(
  DismissedMoments.new,
);

/// Width of the left time column, shared so rows and card line up.
const _timeColumn = 52.0;

/// One timeline row: time · status circle · title + detail.
class TimelineRow extends StatelessWidget {
  const TimelineRow({super.key, required this.item, this.onTap});

  final TimelineItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Semantics(
      label: [
        item.time,
        item.title,
        item.detail,
        item.isDone ? 'done' : null,
      ].whereType<String>().join(', '),
      excludeSemantics: true,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VivRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: VivSpace.sm - 2),
          child: Row(
            children: [
              SizedBox(
                width: _timeColumn,
                child: Text(
                  item.time ?? '',
                  style: VivType.caption.copyWith(
                    color: c.textTertiary,
                    fontSize: 13,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              _StatusCircle(done: item.isDone),
              const SizedBox(width: VivSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: VivType.bodySmall.copyWith(
                        color: item.isDone ? c.textSecondary : c.textPrimary,
                        fontWeight: item.isDone ? FontWeight.w400 : FontWeight.w500,
                      ),
                    ),
                    if (item.detail != null)
                      Text(
                        item.detail!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VivType.caption.copyWith(color: c.textTertiary),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCircle extends StatelessWidget {
  const _StatusCircle({required this.done, this.size = 22, this.highlight = false});

  final bool done;
  final double size;

  /// Outline in the brand color (today's pending dot).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? c.primary : null,
        border: done ? null : Border.all(color: highlight ? c.primary : c.borderStrong, width: 1.4),
      ),
      child: done ? Icon(Icons.check_rounded, size: size * 0.62, color: c.onPrimary) : null,
    );
  }
}

/// The highlighted "what matters now" card that sits inside the timeline.
class NowMomentCard extends ConsumerStatefulWidget {
  const NowMomentCard({super.key, required this.card, required this.date});

  final NowCard card;
  final String date;

  @override
  ConsumerState<NowMomentCard> createState() => _NowMomentCardState();
}

class _NowMomentCardState extends ConsumerState<NowMomentCard> {
  /// Which button is running, so only that one spins.
  String? _busy;

  NowCard get card => widget.card;

  String get _category => switch (card.kind) {
    TimelineKind.checkin => 'Check-in',
    TimelineKind.session => 'Train',
    TimelineKind.meal => 'Eat',
    _ => 'Recover',
  };

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

  Future<void> _skipSession() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Make today a rest day?'),
        content: const Text('VIV turns today into rest. The rest of the week stays as planned.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rest today')),
        ],
      ),
    );
    if (ok != true) return;
    // Empty activity_type turns the day into a rest day.
    await _run('secondary', () => ref.read(vivApiProvider).editDay(DaySlotEdit(date: widget.date)));
  }

  Future<void> _recovery(RecoveryActionKind kind) =>
      _run(kind.value, () => ref.read(vivApiProvider).saveRecoveryAction(widget.date, kind));

  /// Buttons per moment kind. `cta_label` comes from the backend; the action
  /// itself maps to the screen or endpoint `cta_action` names.
  List<Widget> _buttons() {
    final primaryLabel = card.ctaLabel;
    switch (card.kind) {
      case TimelineKind.checkin:
        return [
          _primary(primaryLabel ?? 'Check in', () => context.push(Routes.checkin)),
          _secondary(
            'Skip',
            () => ref
                .read(dismissedMomentsProvider.notifier)
                .dismiss(widget.date, TimelineKind.checkin),
          ),
        ];
      case TimelineKind.session:
        return [
          _primary(
            primaryLabel ?? 'Start session',
            () => context.push(Routes.sessionDetail(widget.date)),
          ),
          _secondary('Not today', _skipSession, id: 'secondary'),
        ];
      case TimelineKind.recoveryAction:
        // Only offer what the recovery card offers — anything else is a 400.
        final actions = ref.watch(recoveryCardProvider(widget.date)).value?.availableActions;
        final options = (actions == null || actions.isEmpty)
            ? const [
                RecoveryActionOption(kind: RecoveryActionKind.done, label: 'Done'),
                RecoveryActionOption(kind: RecoveryActionKind.notToday, label: 'Not today'),
              ]
            : actions;
        return [
          for (final (i, a) in options.indexed)
            i == 0
                ? _primary(primaryLabel ?? a.label, () => _recovery(a.kind), id: a.kind.value)
                : _secondary(a.label, () => _recovery(a.kind), id: a.kind.value),
        ];
      case TimelineKind.lightsOut:
        if (primaryLabel == null) return const [];
        return [
          _primary(
            primaryLabel,
            // TODO(api+push): cta_action is empty — nothing schedules this
            // reminder yet. Wire to local notifications or FCM.
            () =>
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Reminders are coming soon.'))),
          ),
        ];
      case TimelineKind.meal:
      case TimelineKind.unknown:
        return const [];
    }
  }

  Widget _primary(String label, VoidCallback onTap, {String id = 'primary'}) => VivButton(
    label: label,
    height: 48,
    loading: _busy == id,
    onPressed: _busy == null ? onTap : null,
  );

  Widget _secondary(String label, VoidCallback onTap, {String id = 'secondary'}) =>
      VivButton.secondary(
        label: label,
        height: 48,
        expand: false,
        loading: _busy == id,
        onPressed: _busy == null ? onTap : null,
      );

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final buttons = _buttons();
    final showsCost =
        card.kind == TimelineKind.recoveryAction || card.kind == TimelineKind.lightsOut;
    final cost = showsCost ? ref.watch(recoveryCardProvider(widget.date)).value?.costTier : null;
    final label = [
      card.label ?? 'Now',
      if (card.showsTime && card.time != null) card.time!,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: VivSpace.xs),
      padding: const EdgeInsets.all(VivSpace.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(VivRadius.lg + 2),
        border: Border.all(color: c.primary, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Eyebrow(label, accent: true)),
              Eyebrow(_category),
            ],
          ),
          if (cost != null) ...[
            const SizedBox(height: VivSpace.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: _CostChip(tier: cost),
            ),
          ],
          const SizedBox(height: VivSpace.sm),
          Semantics(
            header: true,
            child: Text(card.title, style: VivType.headline.copyWith(color: c.textPrimary)),
          ),
          if (card.detail != null) ...[
            const SizedBox(height: VivSpace.sm),
            Text(card.detail!, style: VivType.bodySmall.copyWith(color: c.textSecondary)),
          ],
          if (buttons.isNotEmpty) ...[
            const SizedBox(height: VivSpace.lg),
            Row(
              children: [
                Expanded(child: buttons.first),
                for (final b in buttons.skip(1)) ...[const SizedBox(width: VivSpace.xs), b],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CostChip extends StatelessWidget {
  const _CostChip({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(VivRadius.pill),
      ),
      child: Text(
        '$tier cost'.toUpperCase(),
        style: VivType.eyebrow.copyWith(color: c.primary, fontSize: 10.5),
      ),
    );
  }
}

/// "THIS WEEK · 1 of 3 sessions" with one dot per day.
class WeekProgressCard extends StatelessWidget {
  const WeekProgressCard({super.key, required this.progress, this.onTap});

  final WeekProgress progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return VivCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(VivSpace.md, VivSpace.md, VivSpace.md, VivSpace.sm),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Eyebrow('This week')),
              Text(
                '${progress.completedSessions} of ${progress.totalSessions} sessions',
                style: VivType.label.copyWith(color: c.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: VivSpace.md),
          Row(
            children: [for (final d in progress.days) Expanded(child: _DayDotView(dot: d))],
          ),
        ],
      ),
    );
  }
}

class _DayDotView extends StatelessWidget {
  const _DayDotView({required this.dot});

  final DayDot dot;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final indicator = switch (dot.status) {
      DayDotStatus.done => const _StatusCircle(done: true, size: 28),
      DayDotStatus.pending => _StatusCircle(done: false, size: 28, highlight: dot.isToday),
      DayDotStatus.rest => Container(
        width: dot.isToday ? 7 : 5,
        height: dot.isToday ? 7 : 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dot.isToday ? c.primary : c.borderStrong,
        ),
      ),
    };
    return Semantics(
      label: '${Dates.capitalize(dot.weekday)}, ${dot.status.name}${dot.isToday ? ', today' : ''}',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(height: 28, child: Center(child: indicator)),
          const SizedBox(height: VivSpace.xs),
          Text(
            dot.letter,
            style: VivType.caption.copyWith(
              color: dot.isToday ? c.textPrimary : c.textTertiary,
              fontWeight: dot.isToday ? FontWeight.w700 : FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
