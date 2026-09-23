import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/models/recovery.dart';
import '../../data/providers.dart';

/// 03 · Recover — driven by yesterday's real session (`GET /recovery/card`).
class RecoverScreen extends ConsumerWidget {
  const RecoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.viv;
    final date = Dates.todayYmd();
    final card = ref.watch(recoveryCardProvider(date));

    return VivPage(
      children: [
        AsyncView<RecoveryCard?>(
          value: card,
          onRetry: () => ref.invalidate(recoveryCardProvider(date)),
          data: (r) => r == null
              ? const PageHeader(
                  title: 'Recover',
                  subtitle: 'Once your week is built, this shows what tonight should look like.',
                )
              : _Card(card: r),
        ),
        const SizedBox(height: VivSpace.xxl),
        Text(
          'If something feels off beyond a normal heavy week, that\'s a conversation for '
          'your doctor — not for VIV.',
          style: VivType.caption.copyWith(color: c.textTertiary),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.card});

  final RecoveryCard card;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final items = card.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Recover',
          subtitle:
              card.headline ??
              (items.isEmpty
                  ? 'Nothing extra tonight.'
                  : 'A few things tonight. That\'s the whole list.'),
        ),
        if (card.context != null) ...[
          Text(card.context!, style: VivType.caption.copyWith(color: c.textTertiary)),
          const SizedBox(height: VivSpace.sm),
        ],
        for (final item in items)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: VivSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: VivSpace.sm),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: VivType.bodySmall.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.detail != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.detail!,
                            style: VivType.caption.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (card.rescheduleNote != null) ...[
          const SizedBox(height: VivSpace.lg),
          VivNote(eyebrow: 'Moved for you', text: card.rescheduleNote!, highlight: true),
        ],
        if (card.why != null) ...[
          const SizedBox(height: VivSpace.lg),
          VivNote(eyebrow: 'Why', text: card.why!),
        ],
        if (card.availableActions.isNotEmpty) ...[
          const SizedBox(height: VivSpace.lg),
          _Actions(card: card),
        ],
      ],
    );
  }
}

/// Only the actions the card itself offered — sending another kind is a 400.
class _Actions extends ConsumerStatefulWidget {
  const _Actions({required this.card});

  final RecoveryCard card;

  @override
  ConsumerState<_Actions> createState() => _ActionsState();
}

class _ActionsState extends ConsumerState<_Actions> {
  RecoveryActionKind? _saving;

  Future<void> _log(RecoveryActionKind kind) async {
    setState(() => _saving = kind);
    try {
      await ref.read(vivApiProvider).saveRecoveryAction(widget.card.date, kind);
      ref.invalidate(recoveryCardProvider(widget.card.date));
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logged = widget.card.loggedAction;
    return Row(
      children: [
        for (final (i, a) in widget.card.availableActions.indexed) ...[
          if (i > 0) const SizedBox(width: VivSpace.xs),
          Expanded(
            child: VivButton(
              label: a.label,
              height: 44,
              variant: logged == a.kind || (logged == null && i == 0)
                  ? VivButtonVariant.primary
                  : VivButtonVariant.secondary,
              loading: _saving == a.kind,
              onPressed: _saving == null ? () => _log(a.kind) : null,
            ),
          ),
        ],
      ],
    );
  }
}
