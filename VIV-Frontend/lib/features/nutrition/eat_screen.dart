import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/nutrition.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';
import 'nutrition_providers.dart';
import 'swap_meal_sheet.dart';

String todayWeekday() => Dates.longWeekday(Dates.today()).toLowerCase();

/// 04 · Eat
class EatScreen extends ConsumerWidget {
  const EatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(nutritionPlanProvider);
    return VivPage(
      children: [
        AsyncView<NutritionPlan?>(
          value: plan,
          onRetry: () => ref.invalidate(nutritionPlanProvider),
          data: (p) => p == null ? const _SetupPrompt() : _Today(plan: p),
        ),
      ],
    );
  }
}

class _SetupPrompt extends StatelessWidget {
  const _SetupPrompt();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          title: 'Eat today',
          subtitle:
              'A few questions about how you eat, and VIV sizes meals to your '
              'training and your cycle. Optional — training works without it.',
        ),
        VivButton(label: 'Set up meals', onPressed: () => context.push(Routes.nutritionSetup)),
      ],
    );
  }
}

class _Today extends ConsumerWidget {
  const _Today({required this.plan});

  final NutritionPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.viv;
    final weekday = todayWeekday();
    final day = plan.dayFor(weekday);
    ref.watch(mealSelectionsProvider);
    final selections = ref.read(mealSelectionsProvider.notifier);

    if (day == null) {
      return const PageHeader(title: 'Eat today', subtitle: 'No meals planned for today.');
    }
    final protein = day.macros?.proteinG;
    final water = day.hydration?.liters ?? plan.waterBaseLiters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Eat today',
          subtitle: day.isTrainingDay
              ? 'Training day. Protein is the one thing worth protecting.'
              : 'Rest day. Keep protein steady; the rest can flex.',
        ),
        Row(
          children: [
            Expanded(
              child: _Stat(label: 'Protein', value: protein == null ? '—' : '${protein.round()} g'),
            ),
            const SizedBox(width: VivSpace.xs),
            Expanded(
              child: _Stat(
                label: 'Water',
                value: water == null ? '—' : '${water.toStringAsFixed(1)} L',
              ),
            ),
          ],
        ),
        const SizedBox(height: VivSpace.xl),
        const Eyebrow('Your meals'),
        const SizedBox(height: VivSpace.xs),
        for (var i = 0; i < day.meals.length; i++)
          _MealRow(
            slot: day.meals[i],
            option: _optionAt(day.meals[i], selections.selected(weekday, day.meals[i].slotKey)),
            onOpen: () => context.push(Routes.meal(weekday, i)),
            onSwap: () => showSwapMealSheet(context, weekday: weekday, slot: day.meals[i]),
          ),
        const SizedBox(height: VivSpace.lg),
        const VivNote(
          text: 'Eating the same thing twice isn\'t lazy. Fewer food decisions is the point this week.',
          highlight: true,
        ),
        const SizedBox(height: VivSpace.lg),
        Center(
          child: VivButton.text(
            label: 'See full targets',
            onPressed: () => context.push(Routes.fullTargets),
          ),
        ),
        if (!plan.copyEnriched)
          Text(
            'Meal names are still being polished…',
            textAlign: TextAlign.center,
            style: VivType.caption.copyWith(color: c.textTertiary),
          ),
      ],
    );
  }

  MealOption? _optionAt(MealSlot slot, int index) =>
      slot.options.isEmpty ? null : slot.options[index.clamp(0, slot.options.length - 1)];
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.slot,
    required this.option,
    required this.onOpen,
    required this.onSwap,
  });

  final MealSlot slot;
  final MealOption? option;
  final VoidCallback onOpen;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final kcal = slot.macroTargets?.calories;
    return InkWell(
      onTap: onOpen,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: VivSpace.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow([slot.mealName, if (kcal != null) '$kcal kcal'].join(' · ')),
                    const SizedBox(height: 2),
                    Text(
                      option?.name ?? '—',
                      style: VivType.bodySmall.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (slot.options.length > 1)
                TextButton(
                  onPressed: onSwap,
                  child: Text(
                    'Swap',
                    style: VivType.caption.copyWith(color: c.primary, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
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
          Text(value, style: VivType.headline.copyWith(color: c.textPrimary, fontSize: 22)),
        ],
      ),
    );
  }
}
