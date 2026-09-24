import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/models/me.dart';
import '../../data/providers.dart';
import '../home/period_start_sheet.dart';
import '../onboarding/onboarding_draft.dart';

/// 02 · Your info — tap a row to edit it (03 · Edit a field).
class YourInfoScreen extends ConsumerWidget {
  const YourInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).value;
    if (me == null) return const Scaffold(body: LoadingView());

    String num(double? v) => v == null ? 'Add' : v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

    void edit(Widget sheet) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => sheet,
    );

    return VivPage(
      showBack: true,
      children: [
        const PageHeader(
          title: 'Your info',
          subtitle: 'Tap anything to change it. Your plan updates from the next session on.',
        ),
        const Eyebrow('Body'),
        _InfoRow(
          label: 'Weight',
          value: num(me.weightKg),
          unit: me.weightKg == null ? null : 'kg',
          onTap: () => edit(
            _NumberSheet(
              title: 'Weight',
              unit: 'kg',
              initial: me.weightKg ?? 60,
              step: 0.5,
              build: (v) => ProfileUpdate(weightKg: v),
            ),
          ),
        ),
        _InfoRow(
          label: 'Height',
          value: num(me.heightCm),
          unit: me.heightCm == null ? null : 'cm',
          onTap: () => edit(
            _NumberSheet(
              title: 'Height',
              unit: 'cm',
              initial: me.heightCm ?? 165,
              step: 1,
              build: (v) => ProfileUpdate(heightCm: v),
            ),
          ),
        ),
        _InfoRow(label: 'Age', value: me.age?.toString() ?? '—'),
        const SizedBox(height: VivSpace.lg),
        const Eyebrow('Training'),
        _InfoRow(
          label: 'Days per week',
          value: _daysLabel(me.trainingOften),
          onTap: () => edit(
            _ChoiceSheet(
              title: 'Days per week',
              subtitle: 'How many sessions you can realistically protect — not the ideal number.',
              note: 'This week\'s plan is rebuilt from tomorrow — today\'s is untouched.',
              options: {for (final d in DaysPerWeek.values) d.apiValue: d.label},
              selected: me.trainingOften,
              build: (v) => ProfileUpdate(trainingOften: v),
            ),
          ),
        ),
        _InfoRow(
          label: 'Outside training',
          value: me.dailyActivityLevel ?? 'Add',
          onTap: () => edit(
            _ChoiceSheet(
              title: 'Outside training',
              subtitle: 'Your days are mostly…',
              options: {for (final l in ActivityLevel.values) l.label: l.label},
              selected: me.dailyActivityLevel,
              build: (v) => ProfileUpdate(dailyActivityLevel: v),
            ),
          ),
        ),
        const SizedBox(height: VivSpace.lg),
        const Eyebrow('Cycle'),
        _InfoRow(
          label: 'Typical cycle length',
          value: me.cycleDuration ?? 'Add',
          unit: me.cycleDuration == null ? null : 'days',
          onTap: () => edit(
            _NumberSheet(
              title: 'Typical cycle length',
              unit: 'days',
              initial: double.tryParse(me.cycleDuration ?? '') ?? 28,
              step: 1,
              min: 15,
              max: 60,
              build: (v) => ProfileUpdate(cycleDuration: v.round().toString()),
            ),
          ),
        ),
        _InfoRow(
          label: 'Period started',
          value: 'Log it',
          accent: true,
          onTap: () => showPeriodStartSheet(context),
        ),
        _InfoRow(
          label: 'Cycle estimates',
          value: me.cycleEstimationDisabled ? 'Off' : 'On',
          onTap: () async {
            try {
              await ref
                  .read(vivApiProvider)
                  .updateMe(ProfileUpdate(cycleEstimationDisabled: !me.cycleEstimationDisabled));
              ref.invalidate(meProvider);
            } catch (e) {
              if (context.mounted) showErrorSnack(context, e);
            }
          },
        ),
        if (me.expectedPeriodDate != null && !me.cycleEstimationDisabled)
          Padding(
            padding: const EdgeInsets.only(top: VivSpace.xs),
            child: Text(
              'Next period expected around '
              '${Dates.dayMonth(Dates.parseYmd(me.expectedPeriodDate!))}.',
              style: VivType.caption.copyWith(color: context.viv.textTertiary),
            ),
          ),
        const SizedBox(height: VivSpace.lg),
        const VivNote(
          text:
              'Nothing here is required. Anything you leave out, VIV estimates — and gets '
              'better at estimating as you go.',
          highlight: true,
        ),
      ],
    );
  }

  static String _daysLabel(String? apiValue) {
    for (final d in DaysPerWeek.values) {
      if (d.apiValue == apiValue) return d.label;
    }
    return apiValue ?? 'Add';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.unit,
    this.onTap,
    this.accent = false,
  });

  final String label;
  final String value;
  final String? unit;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final isAdd = value == 'Add';
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: VivSpace.sm + 2),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: VivType.bodySmall.copyWith(color: c.textPrimary)),
              ),
              Text(
                value,
                style: VivType.bodySmall.copyWith(
                  color: isAdd || accent ? c.primary : c.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(unit!, style: VivType.caption.copyWith(color: c.textTertiary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared save logic for profile edit sheets.
mixin _SaveProfile<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool saving = false;

  Future<void> save(ProfileUpdate update) async {
    setState(() => saving = true);
    try {
      await ref.read(vivApiProvider).updateMe(update);
      ref.invalidate(meProvider);
      ref.invalidate(nutritionPlanProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _NumberSheet extends ConsumerStatefulWidget {
  const _NumberSheet({
    required this.title,
    required this.unit,
    required this.initial,
    required this.step,
    required this.build,
    this.min = 0,
    this.max = 400,
  });

  final String title;
  final String unit;
  final double initial;
  final double step;
  final double min;
  final double max;
  final ProfileUpdate Function(double value) build;

  @override
  ConsumerState<_NumberSheet> createState() => _NumberSheetState();
}

class _NumberSheetState extends ConsumerState<_NumberSheet> with _SaveProfile {
  late double _value = widget.initial.clamp(widget.min, widget.max);

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final display = _value.toStringAsFixed(widget.step < 1 ? 1 : 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 0, VivSpace.gutter, VivSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: VivType.headline.copyWith(color: c.textPrimary)),
          const SizedBox(height: VivSpace.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                tooltip: 'Decrease',
                onPressed: () =>
                    setState(() => _value = (_value - widget.step).clamp(widget.min, widget.max)),
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 140,
                child: Text(
                  '$display ${widget.unit}',
                  textAlign: TextAlign.center,
                  style: VivType.headline.copyWith(color: c.textPrimary),
                ),
              ),
              IconButton.outlined(
                tooltip: 'Increase',
                onPressed: () =>
                    setState(() => _value = (_value + widget.step).clamp(widget.min, widget.max)),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: VivSpace.xl),
          VivButton(label: 'Save', loading: saving, onPressed: () => save(widget.build(_value))),
        ],
      ),
    );
  }
}

class _ChoiceSheet extends ConsumerStatefulWidget {
  const _ChoiceSheet({
    required this.title,
    required this.options,
    required this.build,
    this.subtitle,
    this.note,
    this.selected,
  });

  final String title;
  final String? subtitle;
  final String? note;

  /// API value → label.
  final Map<String, String> options;
  final String? selected;
  final ProfileUpdate Function(String value) build;

  @override
  ConsumerState<_ChoiceSheet> createState() => _ChoiceSheetState();
}

class _ChoiceSheetState extends ConsumerState<_ChoiceSheet> with _SaveProfile {
  late String? _value = widget.selected;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Padding(
      padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 0, VivSpace.gutter, VivSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: VivType.headline.copyWith(color: c.textPrimary)),
          if (widget.subtitle != null) ...[
            const SizedBox(height: VivSpace.xxs),
            Text(widget.subtitle!, style: VivType.bodySmall.copyWith(color: c.textSecondary)),
          ],
          const SizedBox(height: VivSpace.lg),
          Wrap(
            spacing: VivSpace.xs,
            runSpacing: VivSpace.xs,
            children: [
              for (final e in widget.options.entries)
                ChoicePill(
                  label: e.value,
                  minWidth: 64,
                  selected: _value == e.key,
                  onTap: () => setState(() => _value = e.key),
                ),
            ],
          ),
          if (widget.note != null) ...[
            const SizedBox(height: VivSpace.md),
            VivNote(eyebrow: 'What changes', text: widget.note!, highlight: true),
          ],
          const SizedBox(height: VivSpace.lg),
          VivButton(
            label: 'Save',
            loading: saving,
            onPressed: _value == null || _value == widget.selected
                ? null
                : () => save(widget.build(_value!)),
          ),
        ],
      ),
    );
  }
}
