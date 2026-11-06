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

/// "What changes" under each edit sheet: fixed per field.
abstract final class WhatChanges {
  static const weight = 'Your protein and energy targets are worked out from it.';
  static const height = 'Your energy targets are worked out from it.';
  static const daysPerWeek = 'This week\'s plan is rebuilt from tomorrow. Today\'s is untouched.';
  static const activity = 'Your energy targets take it into account.';
  static const cycleLength = 'Your next period estimate moves with it.';
}

/// 08 · Your info: grouped fields with their values; an empty one reads
/// "+ Add". Tap a field to edit it in a sheet. No equipment or contraception
/// fields: the API doesn't store them.
class YourInfoScreen extends ConsumerWidget {
  const YourInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.viv;
    final me = ref.watch(meProvider).value;
    if (me == null) return const Scaffold(body: LoadingView());

    String? num(double? v) => v?.toStringAsFixed(v % 1 == 0 ? 0 : 1);
    final lastPeriod = me.cycleDay == null
        ? null
        : Dates.today().subtract(Duration(days: me.cycleDay! - 1));

    return VivPage(
      showBack: true,
      children: [
        const PageHeader(
          title: 'Your info',
          subtitle: 'Tap anything to change it. Your plan updates from the next session on.',
        ),
        const SettingsLabel('Body', first: true),
        SettingsGroup(
          children: [
            SettingsRow(
              label: 'Weight',
              value: num(me.weightKg),
              unit: 'kg',
              onTap: () => showEditNumberSheet(
                context,
                title: 'Weight',
                unit: 'kg',
                initial: me.weightKg ?? 60,
                step: 0.5,
                min: 30,
                max: 250,
                whatChanges: WhatChanges.weight,
                build: (v) => ProfileUpdate(weightKg: v),
              ),
            ),
            SettingsRow(
              label: 'Height',
              value: num(me.heightCm),
              unit: 'cm',
              onTap: () => showEditNumberSheet(
                context,
                title: 'Height',
                unit: 'cm',
                initial: me.heightCm ?? 165,
                step: 1,
                min: 120,
                max: 220,
                whatChanges: WhatChanges.height,
                build: (v) => ProfileUpdate(heightCm: v),
              ),
            ),
            SettingsRow(label: 'Age', value: me.age?.toString()),
          ],
        ),
        const SettingsLabel('Training'),
        SettingsGroup(
          children: [
            SettingsRow(
              label: 'Days per week',
              value: _label(
                DaysPerWeek.values,
                me.trainingOften,
                (d) => d.apiValue,
                (d) => d.label,
              ),
              onTap: () => showEditChoiceSheet(
                context,
                title: 'Days per week',
                body: 'How many sessions you can realistically protect.',
                options: {for (final d in DaysPerWeek.values) d.apiValue: d.label},
                selected: me.trainingOften,
                whatChanges: WhatChanges.daysPerWeek,
                build: (v) => ProfileUpdate(trainingOften: v),
              ),
            ),
            SettingsRow(
              label: 'Outside training',
              value: _label(
                ActivityLevel.values,
                me.dailyActivityLevel,
                (l) => l.apiValue,
                (l) => l.label,
              ),
              onTap: () => showEditChoiceSheet(
                context,
                title: 'Outside training',
                body: 'Your days are mostly…',
                options: {for (final l in ActivityLevel.values) l.apiValue: l.label},
                selected: me.dailyActivityLevel,
                whatChanges: WhatChanges.activity,
                build: (v) => ProfileUpdate(dailyActivityLevel: v),
              ),
            ),
          ],
        ),
        const SettingsLabel('Cycle'),
        SettingsGroup(
          children: [
            SettingsRow(
              label: 'Typical length',
              value: me.cycleDuration,
              unit: 'days',
              onTap: () => showEditNumberSheet(
                context,
                title: 'Typical cycle length',
                unit: 'days',
                initial: double.tryParse(me.cycleDuration ?? '') ?? 28,
                step: 1,
                min: 15,
                max: 60,
                whatChanges: WhatChanges.cycleLength,
                build: (v) => ProfileUpdate(cycleDuration: v.round().toString()),
              ),
            ),
            SettingsRow(
              label: 'Last period',
              value: lastPeriod == null ? null : Dates.dayMonth(lastPeriod),
              onTap: () => showPeriodStartSheet(context),
            ),
            SettingsRow(
              label: 'Cycle estimates',
              value: me.cycleEstimationDisabled ? 'Off' : 'On',
              onTap: () async {
                try {
                  await ref
                      .read(vivApiProvider)
                      .updateMe(
                        ProfileUpdate(cycleEstimationDisabled: !me.cycleEstimationDisabled),
                      );
                  ref.invalidate(meProvider);
                } catch (e) {
                  if (context.mounted) showErrorSnack(context, e);
                }
              },
            ),
          ],
        ),
        if (me.expectedPeriodDate != null && !me.cycleEstimationDisabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Text(
              'Next period expected around '
              '${Dates.dayMonth(Dates.parseYmd(me.expectedPeriodDate!))}.',
              style: VivType.meta.copyWith(color: c.subtle),
            ),
          ),
        const SizedBox(height: 22),
        const VivNote(
          text:
              'Nothing here is required. Anything you leave out, VIV estimates and gets '
              'better at estimating as you go.',
        ),
      ],
    );
  }

  static String? _label<T>(
    List<T> values,
    String? apiValue,
    String Function(T) api,
    String Function(T) label,
  ) {
    for (final v in values) {
      if (api(v) == apiValue) return label(v);
    }
    return apiValue;
  }
}

/// 08 · Edit a field, number version: a big stepper, "What changes", Save.
Future<void> showEditNumberSheet(
  BuildContext context, {
  required String title,
  required String unit,
  required double initial,
  required double step,
  required ProfileUpdate Function(double value) build,
  double min = 0,
  double max = 400,
  String? whatChanges,
}) => showVivSheet<void>(
  context,
  builder: (_) => _NumberSheet(
    title: title,
    unit: unit,
    initial: initial,
    step: step,
    min: min,
    max: max,
    whatChanges: whatChanges,
    build: build,
  ),
);

/// 08 · Edit a field, choice version: pills, "What changes", Save.
Future<void> showEditChoiceSheet(
  BuildContext context, {
  required String title,
  required Map<String, String> options,
  required ProfileUpdate Function(String value) build,
  String? body,
  String? selected,
  String? whatChanges,
}) => showVivSheet<void>(
  context,
  builder: (_) => _ChoiceSheet(
    title: title,
    body: body,
    options: options,
    selected: selected,
    whatChanges: whatChanges,
    build: build,
  ),
);

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

class _WhatChanges extends StatelessWidget {
  const _WhatChanges(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => VivNote(eyebrow: 'What changes', text: text);
}

class _NumberSheet extends ConsumerStatefulWidget {
  const _NumberSheet({
    required this.title,
    required this.unit,
    required this.initial,
    required this.step,
    required this.min,
    required this.max,
    required this.build,
    this.whatChanges,
  });

  final String title;
  final String unit;
  final double initial;
  final double step;
  final double min;
  final double max;
  final String? whatChanges;
  final ProfileUpdate Function(double value) build;

  @override
  ConsumerState<_NumberSheet> createState() => _NumberSheetState();
}

class _NumberSheetState extends ConsumerState<_NumberSheet> with _SaveProfile {
  late double _value = widget.initial.clamp(widget.min, widget.max);

  void _nudge(double by) => setState(() => _value = (_value + by).clamp(widget.min, widget.max));

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final display = _value.toStringAsFixed(widget.step < 1 && _value % 1 != 0 ? 1 : 0);
    return VivBottomSheet(
      title: widget.title,
      actions: [
        PillButton(label: 'Save', busy: saving, onPressed: () => save(widget.build(_value))),
      ],
      children: [
        Row(
          children: [
            _RoundButton(
              icon: Icons.remove_rounded,
              label: 'Decrease',
              onTap: _value <= widget.min ? null : () => _nudge(-widget.step),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: display,
                  children: [
                    TextSpan(
                      text: ' ${widget.unit}',
                      style: VivType.body.copyWith(fontWeight: FontWeight.w500, color: c.subtle),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: VivType.number.copyWith(fontSize: 44, color: c.ink),
              ),
            ),
            _RoundButton(
              icon: Icons.add_rounded,
              label: 'Increase',
              onTap: _value >= widget.max ? null : () => _nudge(widget.step),
            ),
          ],
        ),
        if (widget.whatChanges != null) _WhatChanges(widget.whatChanges!),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: VivSize.control,
          height: VivSize.control,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.raised,
            border: Border.all(color: c.line),
          ),
          child: Icon(icon, color: onTap == null ? c.faint : c.ink),
        ),
      ),
    );
  }
}

class _ChoiceSheet extends ConsumerStatefulWidget {
  const _ChoiceSheet({
    required this.title,
    required this.options,
    required this.build,
    this.body,
    this.selected,
    this.whatChanges,
  });

  final String title;
  final String? body;
  final String? whatChanges;

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
    return VivBottomSheet(
      title: widget.title,
      body: widget.body,
      actions: [
        PillButton(
          label: 'Save',
          busy: saving,
          onPressed: _value == null || _value == widget.selected
              ? null
              : () => save(widget.build(_value!)),
        ),
      ],
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
        if (widget.whatChanges != null) _WhatChanges(widget.whatChanges!),
      ],
    );
  }
}
