import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/viv_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/nutrition.dart';
import '../../data/providers.dart';
import 'eat_screen.dart';
import 'nutrition_format.dart';
import 'nutrition_providers.dart';
import 'swap_meal_sheet.dart';

/// 05 · Meal detail: photo slot, the dish, protein, what you need, and
/// "Cooked it" (today only, device only) + "Swap".
class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({super.key, required this.weekday, required this.slotIndex});

  final String weekday;
  final int slotIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.viv;
    final plan = ref.watch(nutritionPlanProvider).value;
    ref.watch(mealSelectionsProvider);
    final cooked = ref.watch(cookedMealsProvider);
    final day = plan?.dayFor(weekday);
    final MealSlot? slot = (day != null && slotIndex < day.meals.length)
        ? day.meals[slotIndex]
        : null;
    if (slot == null || slot.options.isEmpty) {
      return const VivPage(showBack: true, children: [PageHeader(title: 'Meal not found')]);
    }
    final option = optionAt(
      slot,
      ref.read(mealSelectionsProvider.notifier).selected(weekday, slot.slotKey),
    )!;
    final m = slot.macroTargets;
    final isToday = weekday.toLowerCase() == todayWeekday();
    final isCooked = isToday && cooked.contains(slot.slotKey);
    final canSwap = slot.options.length > 1;
    final top = MediaQuery.paddingOf(context).top;

    final actions = [
      if (isToday)
        Expanded(
          child: PillButton(
            label: isCooked ? 'Cooked' : 'Cooked it',
            icon: isCooked ? const Icon(Icons.check_rounded) : null,
            variant: isCooked ? PillVariant.tint : PillVariant.primary,
            onPressed: () => ref.read(cookedMealsProvider.notifier).toggle(slot.slotKey),
          ),
        ),
      if (isToday && canSwap) const SizedBox(width: 9),
      if (canSwap)
        Expanded(
          child: PillButton(
            label: 'Swap',
            variant: PillVariant.outline,
            onPressed: () => showSwapMealSheet(context, weekday: weekday, slot: slot),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: c.page,
      body: ResponsiveCenter(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 200 + top,
                          decoration: BoxDecoration(
                            color: c.photo,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                          ),
                          alignment: Alignment.center,
                          padding: EdgeInsets.only(top: top),
                          child: Icon(Icons.restaurant_rounded, size: 34, color: c.faint),
                        ),
                        Positioned(
                          top: top + 4,
                          left: VivSpace.gutter - 2,
                          child: const VivBackButton(),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 22, VivSpace.gutter, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Eyebrow(slot.mealName, accent: true),
                          const SizedBox(height: 12),
                          Semantics(
                            header: true,
                            child: Text(
                              option.name,
                              style: VivType.h1.copyWith(fontSize: 30, color: c.ink),
                            ),
                          ),
                          if (option.summary != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              option.summary!,
                              style: VivType.lead.copyWith(fontSize: 15.5, color: c.muted),
                            ),
                          ],
                          if (m?.proteinG != null || m?.calories != null) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                if (m?.proteinG case final p?)
                                  Expanded(
                                    child: _Tile(label: 'Protein', value: grams(p)),
                                  ),
                                if (m?.proteinG != null && m?.calories != null)
                                  const SizedBox(width: 10),
                                if (m?.calories case final k?)
                                  Expanded(
                                    child: _Tile(label: 'Energy', value: kcal(k)),
                                  ),
                              ],
                            ),
                          ],
                          if (slot.timingWindow != null || slot.phaseNote != null) ...[
                            const SizedBox(height: 14),
                            VivNote(
                              text: [
                                if (slot.timingWindow != null) 'Best around ${slot.timingWindow}.',
                                ?slot.phaseNote,
                              ].join(' '),
                            ),
                          ],
                          if (option.ingredients.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            SettingsGroup(
                              children: [
                                for (final ing in option.ingredients)
                                  _Ingredient(
                                    name: ing.name,
                                    amount:
                                        ing.approx ??
                                        (ing.amountG == null ? '' : grams(ing.amountG!)),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (actions.isNotEmpty)
              SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 12, VivSpace.gutter, 12),
                  child: Row(children: actions),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(VivRadius.tile),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: VivType.eyebrow.copyWith(color: c.subtle)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: VivType.h3.copyWith(fontSize: 24, letterSpacing: -0.72, color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ingredient extends StatelessWidget {
  const _Ingredient({required this.name, required this.amount});

  final String name;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: VivType.body.copyWith(fontWeight: FontWeight.w500, color: c.ink),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            amount,
            style: VivType.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
