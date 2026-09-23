import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/nutrition.dart';
import '../../data/providers.dart';

/// 05 · Full targets — training day vs. rest day.
class FullTargetsScreen extends ConsumerStatefulWidget {
  const FullTargetsScreen({super.key});

  @override
  ConsumerState<FullTargetsScreen> createState() => _FullTargetsScreenState();
}

class _FullTargetsScreenState extends ConsumerState<FullTargetsScreen> {
  bool _training = true;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final plan = ref.watch(nutritionPlanProvider).value;
    final DayMacros? m = _training ? plan?.targets?.trainingDay : plan?.targets?.restDay;
    final water = plan?.waterBaseLiters;

    return VivPage(
      showBack: true,
      children: [
        const PageHeader(
          eyebrow: Eyebrow('Nutrition'),
          title: 'Full targets',
          subtitle:
              'The detail, if you want it. Day to day, protein is the only one worth watching.',
        ),
        PillRow(
          children: [
            ChoicePill(
              label: 'Training day',
              selected: _training,
              onTap: () => setState(() => _training = true),
            ),
            ChoicePill(
              label: 'Rest day',
              selected: !_training,
              onTap: () => setState(() => _training = false),
            ),
          ],
        ),
        const SizedBox(height: VivSpace.md),
        _Row(label: 'Protein', hint: 'the one to protect', value: _g(m?.proteinG)),
        _Row(label: 'Carbohydrate', value: _g(m?.carbsG)),
        _Row(label: 'Fat', value: _g(m?.fatG)),
        _Row(
          label: 'Water',
          hint: _training ? 'plus electrolytes on hard days' : null,
          value: water == null ? '—' : '${water.toStringAsFixed(1)} L',
        ),
        _Row(
          label: 'Energy',
          hint: 'a range, not a rule',
          value: m?.calories == null ? '—' : '~${m!.calories} kcal',
        ),
        const SizedBox(height: VivSpace.lg),
        const VivNote(
          eyebrow: 'Where these come from',
          highlight: true,
          text:
              'Your weight, your session load this week, and where you are in your cycle. '
              'They move on their own — you don\'t need to recalculate anything.',
        ),
        const SizedBox(height: VivSpace.sm),
        Text(
          'Rounded on purpose. Anything more precise than this is noise at your training volume.',
          style: VivType.caption.copyWith(color: c.textTertiary),
        ),
      ],
    );
  }

  String _g(double? v) => v == null ? '—' : '${v.round()} g';
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.hint});

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: VivSpace.sm + 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: VivType.bodySmall.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hint != null)
                    Text(
                      hint!,
                      style: VivType.caption.copyWith(color: c.textTertiary, fontSize: 12),
                    ),
                ],
              ),
            ),
            Text(value, style: VivType.cardTitle.copyWith(color: c.textPrimary)),
          ],
        ),
      ),
    );
  }
}
