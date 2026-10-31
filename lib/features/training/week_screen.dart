import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/home.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';
import 'edit_day_sheet.dart';

const _numberWords = ['No', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven'];

/// 04 · This week: one column. Today is the wine field with Start; done days
/// get an accent check; rest days shrink to slim pills.
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
    // Done flags come from Home's week progress (same week, Monday first).
    final progress = ref.watch(homeTodayProvider).value?.weekProgress?.days ?? const [];

    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: AsyncView<WeeklyPlan?>(
            value: week,
            onRetry: () => ref.invalidate(currentWeekProvider),
            loading: const _WeekSkeleton(),
            data: (plan) => ListView(
              padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 16, VivSpace.gutter, 24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text('This week', style: VivType.h1.copyWith(color: c.ink)),
                      ),
                    ),
                    if (plan != null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _editing = !_editing),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 0, 4),
                          child: Text(
                            _editing ? 'Done' : 'Edit days',
                            style: VivType.body.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: c.accent,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  plan == null
                      ? 'Nothing planned yet. Check in on Today and VIV builds it.'
                      : _editing
                      ? 'Tap a day to change it.'
                      : note ??
                            '${plan.sessionCount < _numberWords.length ? _numberWords[plan.sessionCount] : plan.sessionCount} '
                                'sessions, all moveable. Rest days fill in around them.',
                  style: VivType.lead.copyWith(fontSize: 15.5, color: c.muted),
                ),
                const SizedBox(height: 18),
                if (plan != null)
                  for (final (i, day) in plan.days.indexed) ...[
                    _DayRow(
                      day: day,
                      done: i < progress.length && progress[i].status == DayDotStatus.done,
                      editing: _editing,
                      onTap: () => _editing
                          ? showEditDaySheet(context, day)
                          : day.isRestDay
                          ? null
                          : context.push(Routes.sessionDetail(day.date)),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.done,
    required this.editing,
    required this.onTap,
  });

  final WeekDay day;
  final bool done;
  final bool editing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final weekday = Dates.shortWeekday(day.dateTime);
    final meta = [
      day.subtitle,
      if (day.substituted) 'adjusted',
    ].where((s) => s.isNotEmpty).join(' · ');
    Widget dayLabel(Color color, {bool bold = false}) => SizedBox(
      width: 34,
      child: Text(
        weekday,
        style: VivType.meta.copyWith(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
          color: color,
        ),
      ),
    );

    if (day.isRestDay) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: editing ? onTap : null,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: ShapeDecoration(color: c.sunken, shape: const StadiumBorder()),
          child: Row(
            children: [
              dayLabel(c.subtle),
              const SizedBox(width: 14),
              Expanded(
                child: Text('Rest', style: VivType.body.copyWith(fontSize: 14.5, color: c.subtle)),
              ),
              if (editing) Icon(Icons.edit_outlined, size: 16, color: c.subtle),
            ],
          ),
        ),
      );
    }

    if (day.isToday && !editing) {
      return WineField(
        radius: VivRadius.group,
        compact: true,
        animateIn: false,
        children: [
          Row(
            children: [
              dayLabel(VivColors.onField, bold: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.title,
                      style: VivType.h3.copyWith(
                        fontSize: 19,
                        letterSpacing: -0.38,
                        color: VivColors.onField,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      style: VivType.meta.copyWith(fontSize: 13.5, color: VivColors.onFieldSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!done)
            PillButton(
              label: 'Start session',
              arrow: true,
              variant: PillVariant.onField,
              size: PillSize.compact,
              onPressed: onTap,
            ),
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: c.raised,
          borderRadius: BorderRadius.circular(VivRadius.tile),
          boxShadow: c.cardShadow,
        ),
        child: Row(
          children: [
            dayLabel(c.subtle),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.title,
                    style: VivType.rowTitle.copyWith(fontWeight: FontWeight.w700, color: c.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(meta, style: VivType.meta.copyWith(fontSize: 13.5, color: c.muted)),
                  if (day.warning != null) ...[
                    const SizedBox(height: 4),
                    Text(day.warning!, style: VivType.meta.copyWith(color: c.tintInk)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            if (editing)
              Icon(Icons.edit_outlined, size: 18, color: c.subtle)
            else if (done)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, size: 16, color: c.ctaText),
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.ring, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeekSkeleton extends StatelessWidget {
  const _WeekSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 16, VivSpace.gutter, 0),
      child: Skeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 180, height: 34, radius: VivRadius.md),
            const SizedBox(height: 12),
            const SkeletonBox.line(),
            const SizedBox(height: 22),
            for (var i = 0; i < 6; i++) ...[
              SkeletonBox(height: i.isEven ? 64 : 46, radius: VivRadius.tile),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
