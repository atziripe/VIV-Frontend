import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/nutrition.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';
import 'meal_image.dart';
import 'nutrition_format.dart';
import 'nutrition_providers.dart';
import 'swap_meal_sheet.dart';

String todayWeekday() => Dates.longWeekday(Dates.today()).toLowerCase();

/// 05 · Eat today
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
          loading: const _EatSkeleton(),
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
              'training and your cycle. Optional, training works without it.',
        ),
        PillButton(
          label: 'Set up meals',
          arrow: true,
          onPressed: () => context.push(Routes.nutritionSetup),
        ),
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
    final cooked = ref.watch(cookedMealsProvider);

    if (day == null) {
      return const PageHeader(title: 'Eat today', subtitle: 'No meals planned for today.');
    }
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
        if (day.macros?.proteinG case final total?) ...[
          _ProteinField(
            total: total,
            day: day,
            cooked: cooked,
            proteinOf: (slot) =>
                proteinOf(slot, optionAt(slot, selections.selected(weekday, slot.slotKey))),
          ),
          const SizedBox(height: 14),
        ],
        if (day.meals.isNotEmpty)
          SettingsGroup(
            children: [
              for (final (i, slot) in day.meals.indexed)
                _MealRow(
                  slot: slot,
                  option: optionAt(slot, selections.selected(weekday, slot.slotKey)),
                  cooked: cooked.contains(slot.slotKey),
                  onOpen: () => context.push(Routes.meal(weekday, i)),
                  onSwap: () => showSwapMealSheet(context, weekday: weekday, slot: slot),
                ),
            ],
          ),
        const SizedBox(height: 14),
        const VivNote(
          text: 'Eating the same thing twice isn\'t lazy. Fewer food decisions is the point this week.',
        ),
        const SizedBox(height: 6),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push(Routes.fullTargets),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: VivSize.minTap),
              child: Center(
                widthFactor: 1,
                child: Text(
                  ['Full targets', if (water != null) 'water ${liters(water)}'].join(' · '),
                  style: VivType.body.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!plan.copyEnriched)
          Text(
            'Meal names are still being polished…',
            textAlign: TextAlign.center,
            style: VivType.meta.copyWith(color: c.subtle),
          ),
      ],
    );
  }
}

MealOption? optionAt(MealSlot slot, int index) =>
    slot.options.isEmpty ? null : slot.options[index.clamp(0, slot.options.length - 1)];

/// The picked option's own protein, else the slot's target.
double? proteinOf(MealSlot slot, MealOption? option) =>
    option?.macros?.proteinG ?? slot.macroTargets?.proteinG;

/// "PROTEIN TODAY · 137 g", the per-meal hint and a bar filled by the meals
/// marked "Cooked it" on this device.
class _ProteinField extends StatelessWidget {
  const _ProteinField({
    required this.total,
    required this.day,
    required this.cooked,
    required this.proteinOf,
  });

  final double total;
  final NutritionDay day;
  final Set<String> cooked;
  final double? Function(MealSlot slot) proteinOf;

  @override
  Widget build(BuildContext context) {
    final done = [
      for (final m in day.meals)
        if (cooked.contains(m.slotKey)) m,
    ];
    final eaten = done.fold<double>(0, (sum, m) => sum + (proteinOf(m) ?? 0));
    final perMeal = day.meals.isEmpty ? null : total / day.meals.length;
    final fraction = total <= 0 ? 0.0 : (eaten / total).clamp(0.0, 1.0);
    final doneLine = done.isEmpty
        ? '${grams(eaten)} in'
        : '${grams(eaten)} in · ${done.map((m) => m.mealName.toLowerCase()).join(', ')} done';

    return WineField(
      pulse: false,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROTEIN TODAY', style: VivType.eyebrow.copyWith(color: VivColors.onField)),
                  const SizedBox(height: 4),
                  Text(grams(total), style: VivType.number.copyWith(color: VivColors.onField)),
                ],
              ),
            ),
            if (perMeal != null)
              Text(
                'about ${grams(perMeal)}\na meal',
                textAlign: TextAlign.right,
                style: VivType.meta.copyWith(fontSize: 13.5, color: VivColors.onFieldSoft),
              ),
          ],
        ),
        _ProgressBar(fraction: fraction),
        Text(doneLine, style: VivType.meta.copyWith(fontSize: 13.5, color: VivColors.onFieldSoft)),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final reduced = VivMotion.reduced(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(VivRadius.pill),
      child: SizedBox(
        height: 8,
        child: ColoredBox(
          color: VivColors.onFieldTrack,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: fraction),
            duration: reduced ? Duration.zero : const Duration(milliseconds: 700),
            curve: VivMotion.curve,
            builder: (_, v, _) => FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: const ColoredBox(color: VivColors.onField),
            ),
          ),
        ),
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.slot,
    required this.option,
    required this.cooked,
    required this.onOpen,
    required this.onSwap,
  });

  final MealSlot slot;
  final MealOption? option;
  final bool cooked;
  final VoidCallback onOpen;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final protein = proteinOf(slot, option);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            MealImage(
              url: option?.imageUrl,
              width: 56,
              height: 56,
              done: cooked,
              semanticLabel: option?.name,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [slot.mealName, if (protein != null) grams(protein)].join(' · ').toUpperCase(),
                    style: VivType.eyebrow.copyWith(color: c.subtle),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option?.name ?? 'Not planned',
                    style: VivType.rowTitle.copyWith(color: c.ink),
                  ),
                ],
              ),
            ),
            if (slot.options.length > 1)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSwap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: VivSize.minTap,
                    minWidth: VivSize.minTap,
                  ),
                  child: Center(
                    child: Text(
                      'Swap',
                      style: VivType.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.accent,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EatSkeleton extends StatelessWidget {
  const _EatSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox.line(width: 170, height: 32),
          SizedBox(height: 12),
          SkeletonBox.line(width: 260),
          SizedBox(height: 22),
          SkeletonBox.field(height: 180),
          SizedBox(height: 14),
          SkeletonBox(height: 86, radius: VivRadius.group),
          SizedBox(height: 10),
          SkeletonBox(height: 86, radius: VivRadius.group),
          SizedBox(height: 10),
          SkeletonBox(height: 86, radius: VivRadius.group),
        ],
      ),
    );
  }
}
