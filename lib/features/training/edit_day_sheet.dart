import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/models/catalog.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/providers.dart';

/// Manually replace one day's slot (`PATCH /training/weekly-plan/day`).
Future<void> showEditDaySheet(BuildContext context, WeekDay day) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EditDaySheet(day: day),
  );
}

class _EditDaySheet extends ConsumerStatefulWidget {
  const _EditDaySheet({required this.day});

  final WeekDay day;

  @override
  ConsumerState<_EditDaySheet> createState() => _EditDaySheetState();
}

class _EditDaySheetState extends ConsumerState<_EditDaySheet> {
  /// Null = rest day.
  late Activity? _activity = widget.day.isRestDay ? null : Activity.fromId(widget.day.activityType);
  late Intensity _intensity = Intensity.values.firstWhere(
    (i) => i.code == widget.day.intensity,
    orElse: () => Intensity.moderate,
  );
  late MuscleGroup _group = MuscleGroup.values.firstWhere(
    (m) => m.id == widget.day.muscleGroup,
    orElse: () => MuscleGroup.fullBody,
  );
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(vivApiProvider)
          .editDay(
            DaySlotEdit(
              date: widget.day.date,
              activityType: _activity?.id,
              intensity: _activity == null ? null : _intensity.code,
              muscleGroup: _activity == Activity.strength ? _group.id : null,
            ),
          );
      ref.invalidate(currentWeekProvider);
      ref.invalidate(weeklyNoteProvider);
      ref.invalidate(dayDetailProvider(widget.day.date));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 0, VivSpace.gutter, VivSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            Dates.longWeekday(widget.day.dateTime),
            style: VivType.headline.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: VivSpace.xxs),
          Text(
            'Only this day changes. The other six stay put.',
            style: VivType.bodySmall.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: VivSpace.lg),
          const FieldLabel('Activity'),
          Wrap(
            spacing: VivSpace.xs,
            runSpacing: VivSpace.xs,
            children: [
              ChoicePill(
                label: 'Rest',
                selected: _activity == null,
                onTap: () => setState(() => _activity = null),
              ),
              for (final a in Activity.values)
                ChoicePill(
                  label: a.label,
                  selected: _activity == a,
                  onTap: () => setState(() => _activity = a),
                ),
            ],
          ),
          if (_activity != null) ...[
            const SizedBox(height: VivSpace.lg),
            const FieldLabel('Intensity'),
            Wrap(
              spacing: VivSpace.xs,
              runSpacing: VivSpace.xs,
              children: [
                for (final i in Intensity.values)
                  ChoicePill(
                    label: i.label,
                    selected: _intensity == i,
                    onTap: () => setState(() => _intensity = i),
                  ),
              ],
            ),
          ],
          if (_activity == Activity.strength) ...[
            const SizedBox(height: VivSpace.lg),
            const FieldLabel('Focus'),
            PillRow(
              children: [
                for (final m in MuscleGroup.values)
                  ChoicePill(
                    label: m.label,
                    selected: _group == m,
                    onTap: () => setState(() => _group = m),
                  ),
              ],
            ),
          ],
          const SizedBox(height: VivSpace.xl),
          VivButton(label: 'Save', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
