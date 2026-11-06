import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/models/recovery.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';

/// 06 · Recover: driven by yesterday's real session (`GET /recovery/card`).
///
/// The cost ladder: Building (training day) and low are sunken, medium is
/// tint, high turns the whole card into the wine field.
class RecoverScreen extends ConsumerWidget {
  const RecoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.viv;
    final date = Dates.todayYmd();
    final card = ref.watch(recoveryCardProvider(date));
    final today = Dates.today();

    return VivPage(
      children: [
        AsyncView<RecoveryCard?>(
          value: card,
          onRetry: () => ref.invalidate(recoveryCardProvider(date)),
          loading: const _RecoverSkeleton(),
          data: (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (r != null)
                Text(
                  '${Dates.shortWeekday(today)} · ${r.isRestDay ? 'rest day' : 'training day'}'
                      .toUpperCase(),
                  style: VivType.eyebrow.copyWith(color: c.subtle),
                ),
              const SizedBox(height: 6),
              Semantics(
                header: true,
                child: Text('Recover', style: VivType.h1.copyWith(fontSize: 34, color: c.ink)),
              ),
              const SizedBox(height: 18),
              if (r == null)
                Text(
                  'Once your week is built, this shows what tonight should look like.',
                  style: VivType.lead.copyWith(fontSize: 15.5, color: c.muted),
                )
              else ...[
                _CostCard(card: r),
                if (r.rescheduleNote != null) ...[
                  const SizedBox(height: 12),
                  _RescheduleStrip(note: r.rescheduleNote!),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'If something feels off beyond a normal heavy week, that\'s a conversation for '
          'your doctor, not for VIV.',
          style: VivType.legal.copyWith(color: c.subtle),
        ),
      ],
    );
  }
}

enum _Cost {
  building('Building'),
  low('Low cost'),
  medium('Medium cost'),
  high('High cost');

  const _Cost(this.tag);
  final String tag;

  static _Cost of(RecoveryCard card) => switch (card.costTier) {
    'high' => high,
    'medium' => medium,
    'low' => low,
    _ => building,
  };
}

class _CostCard extends StatefulWidget {
  const _CostCard({required this.card});

  final RecoveryCard card;

  @override
  State<_CostCard> createState() => _CostCardState();
}

class _CostCardState extends State<_CostCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final card = widget.card;
    final cost = _Cost.of(card);
    final onField = cost == _Cost.high;
    final items = card.items;
    final ink = onField ? VivColors.onField : c.ink;
    final soft = onField ? VivColors.onFieldSoft : c.muted;

    // Capped: at most two secondary actions and one reason.
    final more = card.secondary.take(2).toList();
    final hasMore = more.isNotEmpty || card.why != null;

    final body = <Widget>[
      if (items.isNotEmpty)
        _PrimaryBox(item: items.first, onField: onField)
      else
        Text('Nothing extra tonight.', style: VivType.body.copyWith(color: soft)),
      if (card.availableActions.isNotEmpty)
        _Actions(card: card, onField: onField)
      else if (!card.isRestDay)
        PillButton(
          label: 'See today\'s meals',
          size: PillSize.medium,
          onPressed: () => context.go(Routes.eat),
        ),
      if (hasMore) ...[
        _Disclosure(
          label: _open ? 'Hide' : _disclosureLabel(card, more.length),
          open: _open,
          onField: onField,
          onTap: () => setState(() => _open = !_open),
        ),
        if (_open) ...[
          for (final item in more) _MoreRow(item: item, onField: onField),
          if (card.why != null) _WhyBox(cost: cost, text: card.why!, onField: onField),
        ],
      ],
    ];

    if (onField) {
      return WineField(
        compact: true,
        tag: cost.tag,
        title: card.headline ?? 'Today is for recovering',
        body: card.context,
        children: body,
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(VivRadius.card),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _CostTag(cost: cost),
          ),
          const SizedBox(height: 15),
          Text(
            card.headline ?? (items.isEmpty ? 'Nothing extra tonight.' : 'A few things tonight.'),
            style: VivType.h3.copyWith(color: ink),
          ),
          if (card.context != null) ...[
            const SizedBox(height: 6),
            Text(card.context!, style: VivType.body.copyWith(fontSize: 14.5, color: c.muted)),
          ],
          for (final w in body) ...[const SizedBox(height: 15), w],
        ],
      ),
    );
  }

  String _disclosureLabel(RecoveryCard card, int count) {
    if (!card.isRestDay && card.costTier == null) return 'What tonight sets up';
    final why = card.why != null;
    return switch (count) {
      0 => 'Why',
      1 => why ? 'One more, and why' : 'One more',
      _ => why ? 'Two more, and why' : 'Two more',
    };
  }
}

class _CostTag extends StatelessWidget {
  const _CostTag({required this.cost});

  final _Cost cost;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final tint = cost == _Cost.medium;
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: ShapeDecoration(shape: const StadiumBorder(), color: tint ? c.tint : c.sunken),
      child: Center(
        widthFactor: 1,
        child: Text(
          cost.tag.toUpperCase(),
          style: VivType.eyebrow.copyWith(fontSize: 11, color: tint ? c.tintInk : c.muted),
        ),
      ),
    );
  }
}

/// The one thing: "Walk 20 minutes / Outside, easy pace."
class _PrimaryBox extends StatelessWidget {
  const _PrimaryBox({required this.item, required this.onField});

  final RecoveryItem item;
  final bool onField;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      decoration: BoxDecoration(
        color: onField ? VivColors.onFieldOption : c.sunken,
        borderRadius: BorderRadius.circular(VivRadius.option),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: VivType.h3.copyWith(
              fontSize: 21,
              height: 1.2,
              letterSpacing: -0.42,
              color: onField ? VivColors.onField : c.ink,
            ),
          ),
          if (item.detail != null) ...[
            const SizedBox(height: 5),
            Text(
              item.detail!,
              style: VivType.body.copyWith(
                fontSize: 14.5,
                height: 1.45,
                color: onField ? VivColors.onFieldSoft : c.ink2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Disclosure extends StatelessWidget {
  const _Disclosure({
    required this.label,
    required this.open,
    required this.onField,
    required this.onTap,
  });

  final String label;
  final bool open;
  final bool onField;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final ink = onField ? VivColors.onField : c.ink;
    return Semantics(
      button: true,
      expanded: open,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: VivSize.minTap),
          padding: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: onField ? VivColors.onFieldTrack : c.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: VivType.body.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ),
              Icon(
                open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: onField ? VivColors.onFieldMuted : c.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.item, required this.onField});

  final RecoveryItem item;
  final bool onField;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Enter(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 12),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: onField ? VivColors.onField : c.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: VivType.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: onField ? VivColors.onField : c.ink,
                  ),
                ),
                if (item.detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.detail!,
                    style: VivType.meta.copyWith(
                      fontSize: 13.5,
                      color: onField ? VivColors.onFieldSoft : c.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyBox extends StatelessWidget {
  const _WhyBox({required this.cost, required this.text, required this.onField});

  final _Cost cost;
  final String text;
  final bool onField;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final label = switch (cost) {
      _Cost.high => 'Why high',
      _Cost.medium => 'Why medium',
      _Cost.low => 'Why low',
      _Cost.building => 'Why',
    };
    return Enter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: onField ? VivColors.onFieldOption : c.tint,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: VivType.eyebrow.copyWith(color: onField ? VivColors.onField : c.tintInk),
            ),
            const SizedBox(height: 5),
            Text(
              text,
              style: VivType.body.copyWith(
                fontSize: 14,
                color: onField ? VivColors.onFieldSoft : c.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Moved for you": the backend's reschedule note as a sunken strip.
class _RescheduleStrip extends StatelessWidget {
  const _RescheduleStrip({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VivRadius.group)),
        color: c.sunken,
      ),
      child: Text(
        note,
        style: VivType.body.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: c.accent),
      ),
    );
  }
}

/// Only the actions the card itself offered (sending another kind is a 400),
/// at most two side by side. "I trained anyway" shows only when offered.
class _Actions extends ConsumerStatefulWidget {
  const _Actions({required this.card, required this.onField});

  final RecoveryCard card;
  final bool onField;

  @override
  ConsumerState<_Actions> createState() => _ActionsState();
}

class _ActionsState extends ConsumerState<_Actions> {
  RecoveryActionKind? _saving;

  Future<void> _log(RecoveryActionKind kind) async {
    setState(() => _saving = kind);
    try {
      await ref.read(vivApiProvider).saveRecoveryAction(widget.card.date, kind);
      ref.read(analyticsProvider).recoveryActionLogged(kind.value);
      ref.invalidate(recoveryCardProvider(widget.card.date));
      ref.invalidate(homeTodayProvider);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logged = widget.card.loggedAction;
    final actions = widget.card.availableActions.take(2).toList();
    return Row(
      children: [
        for (final (i, a) in actions.indexed) ...[
          if (i > 0) const SizedBox(width: 9),
          Expanded(
            child: PillButton(
              label: a.label,
              size: PillSize.medium,
              variant: _variant(logged == a.kind || (logged == null && i == 0)),
              busy: _saving == a.kind,
              onPressed: _saving == null ? () => _log(a.kind) : null,
            ),
          ),
        ],
      ],
    );
  }

  PillVariant _variant(bool primary) => widget.onField
      ? (primary ? PillVariant.onField : PillVariant.onFieldFaint)
      : (primary ? PillVariant.primary : PillVariant.outline);
}

class _RecoverSkeleton extends StatelessWidget {
  const _RecoverSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox.line(width: 110, height: 12),
          SizedBox(height: 10),
          SkeletonBox.line(width: 150, height: 32),
          SizedBox(height: 18),
          SkeletonBox(height: 320, radius: VivRadius.card),
        ],
      ),
    );
  }
}
