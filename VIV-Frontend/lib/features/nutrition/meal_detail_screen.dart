import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/nutrition.dart';
import '../../data/providers.dart';
import 'nutrition_providers.dart';
import 'swap_meal_sheet.dart';

/// 05 · Meal detail
class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({super.key, required this.weekday, required this.slotIndex});

  final String weekday;
  final int slotIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.viv;
    final plan = ref.watch(nutritionPlanProvider).value;
    ref.watch(mealSelectionsProvider);
    final day = plan?.dayFor(weekday);
    final MealSlot? slot = (day != null && slotIndex < day.meals.length)
        ? day.meals[slotIndex]
        : null;
    if (slot == null || slot.options.isEmpty) {
      return const VivPage(showBack: true, children: [PageHeader(title: 'Meal not found')]);
    }
    final index = ref
        .read(mealSelectionsProvider.notifier)
        .selected(weekday, slot.slotKey)
        .clamp(0, slot.options.length - 1);
    final option = slot.options[index];
    final m = slot.macroTargets;

    return VivPage(
      showBack: true,
      bottom: slot.options.length > 1
          ? VivButton.secondary(
              label: 'Swap this meal',
              onPressed: () => showSwapMealSheet(context, weekday: weekday, slot: slot),
            )
          : null,
      children: [
        PageHeader(
          eyebrow: Eyebrow(slot.mealName, accent: true),
          title: option.name,
          subtitle: option.summary,
        ),
        Row(
          children: [
            if (m?.proteinG != null)
              Expanded(
                child: _Stat(label: 'Protein', value: '${m!.proteinG!.round()} g'),
              ),
            if (m?.proteinG != null && m?.calories != null) const SizedBox(width: VivSpace.xs),
            if (m?.calories != null)
              Expanded(
                child: _Stat(label: 'Energy', value: '${m!.calories} kcal'),
              ),
          ],
        ),
        if (slot.timingWindow != null || slot.phaseNote != null) ...[
          const SizedBox(height: VivSpace.md),
          VivNote(
            text: [
              if (slot.timingWindow != null) 'Best around ${slot.timingWindow}.',
              ?slot.phaseNote,
            ].join(' '),
          ),
        ],
        if (option.ingredients.isNotEmpty) ...[
          const SizedBox(height: VivSpace.xl),
          const Eyebrow('What you need'),
          const SizedBox(height: VivSpace.xs),
          for (final ing in option.ingredients)
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
                        ing.name,
                        style: VivType.bodySmall.copyWith(color: c.textPrimary),
                      ),
                    ),
                    Text(
                      ing.approx ?? (ing.amountG == null ? '' : '${ing.amountG!.round()} g'),
                      style: VivType.caption.copyWith(color: c.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return VivCard(
      padding: const EdgeInsets.all(VivSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(label),
          const SizedBox(height: 4),
          Text(value, style: VivType.cardTitle.copyWith(color: c.textPrimary)),
        ],
      ),
    );
  }
}
