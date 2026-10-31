import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/nutrition.dart';
import '../../data/providers.dart';
import 'nutrition_format.dart';

/// 05 · Full targets: training day vs. rest day.
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
          title: 'Full targets',
          subtitle:
              'The detail, if you want it. Day to day, protein is the only one worth watching.',
        ),
        SegmentedPills<bool>(
          options: const {true: 'Training day', false: 'Rest day'},
          selected: _training,
          onChanged: (v) => setState(() => _training = v),
        ),
        const SizedBox(height: 14),
        SettingsGroup(
          children: [
            _Row(label: 'Protein', hint: 'the one to protect', value: _g(m?.proteinG)),
            _Row(label: 'Carbohydrate', value: _g(m?.carbsG)),
            _Row(label: 'Fat', value: _g(m?.fatG)),
            _Row(
              label: 'Water',
              hint: _training ? 'plus electrolytes on hard days' : null,
              value: water == null ? '—' : liters(water),
            ),
            _Row(
              label: 'Energy',
              hint: 'a range, not a rule',
              value: m?.calories == null ? '—' : kcal(m!.calories!),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const VivNote(
          eyebrow: 'Where these come from',
          text:
              'Your weight, your session load this week, and where you are in your cycle. '
              'They move on their own, you don\'t need to recalculate anything.',
        ),
        const SizedBox(height: 14),
        Text(
          'Rounded on purpose. Anything more precise than this is noise at your training volume.',
          style: VivType.meta.copyWith(color: c.subtle),
        ),
      ],
    );
  }

  String _g(double? v) => v == null ? '—' : grams(v);
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.hint});

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: VivType.body.copyWith(fontWeight: FontWeight.w500, color: c.ink),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 3),
                  Text(hint!, style: VivType.meta.copyWith(fontSize: 13, color: c.subtle)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            value,
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
