import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/nutrition.dart';
import 'nutrition_providers.dart';

/// 06 · Swap a meal
Future<void> showSwapMealSheet(
  BuildContext context, {
  required String weekday,
  required MealSlot slot,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SwapSheet(weekday: weekday, slot: slot),
  );
}

class _SwapSheet extends ConsumerStatefulWidget {
  const _SwapSheet({required this.weekday, required this.slot});

  final String weekday;
  final MealSlot slot;

  @override
  ConsumerState<_SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends ConsumerState<_SwapSheet> {
  late int _choice = ref
      .read(mealSelectionsProvider.notifier)
      .selected(widget.weekday, widget.slot.slotKey);
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(mealSelectionsProvider.notifier)
          .select(widget.weekday, widget.slot.slotKey, _choice);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final options = widget.slot.options;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 0, VivSpace.gutter, VivSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Swap ${widget.slot.mealName.toLowerCase()}',
            style: VivType.headline.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: VivSpace.xxs),
          Text(
            'Same targets, different food. Pick one and the day still adds up.',
            style: VivType.bodySmall.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: VivSpace.lg),
          for (var i = 0; i < options.length; i++) ...[
            OptionTile(
              title: options[i].name,
              subtitle: options[i].flagReason ?? options[i].summary,
              selected: _choice == i,
              onTap: () => setState(() => _choice = i),
            ),
            const SizedBox(height: VivSpace.xs),
          ],
          const SizedBox(height: VivSpace.md),
          VivButton(label: 'Swap it in', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
