import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics.dart';
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
  late String _intensity = widget.day.intensity ?? 'M';
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(vivApiProvider).editDay(switch (_activity) {
        null => DaySlotEdit(date: widget.day.date),
        final a => DaySlotEdit.forActivity(
          date: widget.day.date,
          activity: a,
          intensity: _intensity,
          impact: widget.day.activityType == a.id ? widget.day.impact : null,
        ),
      });
      ref.read(analyticsProvider).weekDayEdited(toRest: _activity == null);
      ref.invalidate(currentWeekProvider);
      ref.invalidate(homeTodayProvider);
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
            style: VivType.headline.copyWith(color: c.ink),
          ),
          const SizedBox(height: VivSpace.xxs),
          Text(
            'Only this day changes. The other six stay put.',
            style: VivType.bodySmall.copyWith(color: c.muted),
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
          // Only the intensities this activity takes; none to pick when
          // there's just one (HIIT is always high). No muscle-group picker:
          // the backend only accepts each activity's default for now.
          if (_activity case final a? when a.intensities.length > 1) ...[
            const SizedBox(height: VivSpace.lg),
            const FieldLabel('Intensity'),
            Wrap(
              spacing: VivSpace.xs,
              runSpacing: VivSpace.xs,
              children: [
                for (final code in a.intensities)
                  ChoicePill(
                    label: Intensity.labelFor(code),
                    selected: a.intensityFor(_intensity) == code,
                    onTap: () => setState(() => _intensity = code),
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
