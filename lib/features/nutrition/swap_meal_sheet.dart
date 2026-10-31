import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/nutrition.dart';
import 'nutrition_format.dart';
import 'nutrition_providers.dart';

/// 05 · Swap a meal
Future<void> showSwapMealSheet(
  BuildContext context, {
  required String weekday,
  required MealSlot slot,
}) {
  return showVivSheet<void>(
    context,
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
    final options = widget.slot.options;
    final protein = widget.slot.macroTargets?.proteinG;
    return VivBottomSheet(
      title: 'Swap ${widget.slot.mealName.toLowerCase()}',
      body: 'Same targets, different food. Pick one and the day still adds up.',
      actions: [PillButton(label: 'Swap it in', busy: _saving, onPressed: _save)],
      children: [
        Column(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              OptionRow(
                label: options[i].name,
                hint: protein == null ? null : grams(protein),
                selected: _choice == i,
                onTap: () => setState(() => _choice = i),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
