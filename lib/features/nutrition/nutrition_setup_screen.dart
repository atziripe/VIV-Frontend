import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/models/nutrition.dart';
import '../../data/providers.dart';

/// Opt-in diet questions → `POST /nutrition/onboarding` (fast, synchronous).
// TODO(design): no Figma frame yet — built from the existing components.
class NutritionSetupScreen extends ConsumerStatefulWidget {
  const NutritionSetupScreen({super.key});

  @override
  ConsumerState<NutritionSetupScreen> createState() => _NutritionSetupScreenState();
}

class _NutritionSetupScreenState extends ConsumerState<NutritionSetupScreen> {
  static const _restrictions = ['Vegetarian', 'Vegan', 'Gluten-free', 'Dairy-free', 'Nut-free'];
  static const _digestion = ['Sensitive stomach', 'Reflux', 'IBS'];

  ProteinSource? _protein;
  String _meals = '3';
  final _diet = <String>{};
  final _gut = <String>{};
  bool _saving = false;

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(vivApiProvider)
          .submitNutritionPreferences(
            NutritionPreferences(
              proteinSource: _protein!,
              mealsPerDay: _meals,
              dietRestrictions: _diet.toList(),
              digestionConditions: _gut.toList(),
            ),
            date: Dates.todayYmd(),
          );
      ref.invalidate(nutritionPlanProvider);
      ref.invalidate(meProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VivPage(
      showBack: true,
      bottom: VivButton(
        label: 'Build my meals',
        loading: _saving,
        onPressed: _protein == null ? null : _submit,
      ),
      children: [
        const PageHeader(
          title: 'How you eat',
          subtitle: 'Rough is fine. You can change any of this in your profile.',
        ),
        const FieldLabel('Where does most of your protein come from?'),
        for (final p in ProteinSource.values) ...[
          OptionTile(
            title: p.value,
            selected: _protein == p,
            onTap: () => setState(() => _protein = p),
          ),
          const SizedBox(height: VivSpace.xs),
        ],
        const SizedBox(height: VivSpace.lg),
        const FieldLabel('Meals a day'),
        PillRow(
          children: [
            for (final n in ['2', '3', '4', '5'])
              ChoicePill(label: n, selected: _meals == n, onTap: () => setState(() => _meals = n)),
          ],
        ),
        const SizedBox(height: VivSpace.lg),
        const FieldLabel('Anything you don\'t eat?'),
        _MultiPills(options: _restrictions, selected: _diet, onChanged: () => setState(() {})),
        const SizedBox(height: VivSpace.lg),
        const FieldLabel('Anything your gut is picky about?'),
        _MultiPills(options: _digestion, selected: _gut, onChanged: () => setState(() {})),
      ],
    );
  }
}

class _MultiPills extends StatelessWidget {
  const _MultiPills({required this.options, required this.selected, required this.onChanged});

  final List<String> options;
  final Set<String> selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: VivSpace.xs,
      runSpacing: VivSpace.xs,
      children: [
        for (final o in options)
          ChoicePill(
            label: o,
            showCheck: true,
            selected: selected.contains(o),
            onTap: () {
              selected.contains(o) ? selected.remove(o) : selected.add(o);
              onChanged();
            },
          ),
      ],
    );
  }
}
