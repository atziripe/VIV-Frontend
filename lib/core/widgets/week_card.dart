import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

enum WeekMark {
  /// Session done: accent fill with ✓.
  done,

  /// A session still to come: ring outline.
  planned,

  /// A session that didn't happen: dashed ring. Never red, never counted.
  missed,

  /// Rest day: 5 px dot.
  rest,
}

class WeekCardDay {
  const WeekCardDay({required this.letter, required this.mark, this.isToday = false});

  /// "M", "T", …
  final String letter;
  final WeekMark mark;

  /// Today gets the 2.5 px accent ring (unless it's already done).
  final bool isToday;
}

/// "This week · N of 3 sessions" with seven 28 px day circles. Never a
/// streak.
class WeekCard extends StatelessWidget {
  const WeekCard({
    super.key,
    required this.days,
    required this.completed,
    required this.total,
    this.title = 'This week',
  });

  final List<WeekCardDay> days;
  final int completed;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(VivRadius.group),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(title.toUpperCase(), style: VivType.eyebrow.copyWith(color: c.subtle)),
              ),
              Text(
                '$completed of $total sessions',
                style: VivType.rowTitle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final d in days)
                Expanded(
                  child: Semantics(
                    label: '${d.letter}: ${d.mark.name}${d.isToday ? ', today' : ''}',
                    child: Column(
                      children: [
                        _DayCircle(day: d),
                        const SizedBox(height: 6),
                        Text(
                          d.letter,
                          style: VivType.meta.copyWith(
                            fontSize: 11.5,
                            fontWeight: d.isToday ? FontWeight.w800 : FontWeight.w500,
                            color: d.isToday ? c.ink : c.subtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({required this.day});

  final WeekCardDay day;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    const size = 28.0;
    if (day.mark == WeekMark.done) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
        child: Icon(Icons.check_rounded, size: 15, color: c.ctaText),
      );
    }
    if (day.isToday) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.accent, width: 2.5),
        ),
      );
    }
    return SizedBox.square(
      dimension: size,
      child: switch (day.mark) {
        WeekMark.rest => Center(
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: c.ring, shape: BoxShape.circle),
          ),
        ),
        WeekMark.missed => CustomPaint(painter: _DashedRing(color: c.ring)),
        _ => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c.ring, width: 1.5),
          ),
        ),
      },
    );
  }
}

class _DashedRing extends CustomPainter {
  const _DashedRing({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 1.5;
    const dashes = 12;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) => old.color != color;
}
