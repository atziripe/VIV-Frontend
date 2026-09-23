import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';
import 'edit_day_sheet.dart';

/// 02 · Your week
class WeekScreen extends ConsumerStatefulWidget {
  const WeekScreen({super.key});

  @override
  ConsumerState<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends ConsumerState<WeekScreen> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final week = ref.watch(currentWeekProvider);
    final note = ref.watch(weeklyNoteProvider).value;

    return VivPage(
      topTrailing: week.value == null
          ? null
          : VivButton.text(
              label: _editing ? 'Done' : 'Edit days',
              onPressed: () => setState(() => _editing = !_editing),
            ),
      children: [
        AsyncView<WeeklyPlan?>(
          value: week,
          onRetry: () => ref.invalidate(currentWeekProvider),
          data: (plan) {
            if (plan == null) {
              return const PageHeader(
                title: 'This week',
                subtitle: 'Nothing planned yet. Check in on Today and VIV builds it.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'This week',
                  subtitle:
                      note ??
                      '${plan.sessionCount} sessions, all moveable. Rest days fill in around them.',
                ),
                if (_editing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: VivSpace.sm),
                    child: Text(
                      'Tap a day to change it.',
                      style: VivType.caption.copyWith(color: c.primary),
                    ),
                  ),
                for (final day in plan.days) ...[
                  _DayRow(
                    day: day,
                    editing: _editing,
                    onTap: () => _editing
                        ? showEditDaySheet(context, day)
                        : day.isRestDay
                        ? null
                        : context.push(Routes.sessionDetail(day.date)),
                  ),
                  const SizedBox(height: VivSpace.xs),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.editing, required this.onTap});

  final WeekDay day;
  final bool editing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final weekday = Dates.shortWeekday(day.dateTime);
    final isPast = day.date.compareTo(Dates.todayYmd()) < 0;

    if (day.isRestDay) {
      return VivCard(
        tone: VivCardTone.muted,
        onTap: editing ? onTap : null,
        padding: const EdgeInsets.symmetric(horizontal: VivSpace.md, vertical: VivSpace.sm),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(weekday, style: VivType.caption.copyWith(color: c.textTertiary)),
            ),
            Expanded(
              child: Text(
                'Rest',
                style: VivType.caption.copyWith(color: c.textTertiary, fontSize: 13),
              ),
            ),
            if (editing) Icon(Icons.edit_outlined, size: 16, color: c.textTertiary),
          ],
        ),
      );
    }

    return VivCard(
      tone: day.isToday ? VivCardTone.highlight : VivCardTone.surface,
      onTap: onTap,
      padding: const EdgeInsets.all(VivSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  weekday,
                  style: VivType.caption.copyWith(
                    color: day.isToday ? c.textPrimary : c.textTertiary,
                    fontWeight: day.isToday ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.title,
                      style: VivType.bodySmall.copyWith(
                        color: isPast ? c.textSecondary : c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [
                        day.subtitle,
                        if (day.isToday) 'today',
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: VivType.caption.copyWith(color: c.textTertiary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(
                editing ? Icons.edit_outlined : Icons.chevron_right_rounded,
                size: editing ? 16 : 20,
                color: c.textTertiary,
              ),
            ],
          ),
          if (day.warning != null) ...[
            const SizedBox(height: VivSpace.xs),
            Text(day.warning!, style: VivType.caption.copyWith(color: c.primary)),
          ],
          if (day.isToday && !editing) ...[
            const SizedBox(height: VivSpace.sm),
            VivButton(
              label: 'Start session',
              height: 44,
              onPressed: () => context.push(Routes.sessionDetail(day.date)),
            ),
          ],
        ],
      ),
    );
  }
}
