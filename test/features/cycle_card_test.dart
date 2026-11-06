import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viv/core/utils/dates.dart';
import 'package:viv/data/models/catalog.dart';
import 'package:viv/data/models/me.dart';
import 'package:viv/features/home/cycle_card.dart';
import 'package:viv/features/home/today_screen.dart';

import '../helpers/fakes.dart';

Me _me({int day = 9, int daysLate = 0, bool disabled = false}) => Me.fromJson({
  'id': 'u1',
  'name': 'Atziri',
  'onboarding_completed': true,
  'cycle_day': day,
  'cycle_phase': 'follicular',
  'cycle_duration': '29',
  'period_duration': '5',
  'days_late': daysLate,
  'cycle_estimation_disabled': disabled,
  'expected_period_date': Dates.ymd(Dates.today().add(Duration(days: 29 - day + 1))),
});

void main() {
  test('phase spans follow the backend phaseForDay boundaries', () {
    // 29-day cycle, 5-day period: ovulation on day 15.
    final spans = CycleEstimate.phaseSpans(29, 5);
    expect(
      [for (final s in spans) (s.phase, s.start, s.end)],
      [
        (CyclePhase.menstrual, 1, 5),
        (CyclePhase.follicular, 6, 13),
        (CyclePhase.ovulatory, 14, 16),
        (CyclePhase.earlyLuteal, 17, 20),
        (CyclePhase.lateLuteal, 21, 29),
      ],
    );
  });

  test('day 9 of 29: late follicular, ovulatory in 5 days', () {
    final e = CycleEstimate.from(_me())!;
    expect(e.phase, CyclePhase.follicular);
    expect(e.countdown(), 'Ovulatory in about 5 days');
    expect(e.countdown(short: true), 'Ovulatory in ~5 days');
    expect(Dates.ymd(e.periodStart), Dates.ymd(Dates.today().subtract(const Duration(days: 8))));
  });

  test('no card when estimates are off or the period is late', () {
    expect(CycleEstimate.from(_me(disabled: true)), isNull);
    expect(CycleEstimate.from(_me(daysLate: 2)), isNull);
  });

  testWidgets('Today shows the cycle card and opens the briefing', (tester) async {
    await pumpScreen(tester, const TodayScreen(), me: _me());
    await tester.ensureVisible(find.text('Late follicular · day 9'));
    await tester.pumpAndSettle();
    expect(find.text('YOUR CYCLE'), findsOneWidget);
    expect(find.textContaining('Energy usually climbs from here.'), findsOneWidget);

    await tester.tap(find.text('Briefing ›'));
    await tester.pumpAndSettle();
    expect(find.text('YOUR CYCLE · DAY 9 OF ~29'), findsOneWidget);
    expect(find.text('Late follicular'), findsOneWidget);
    expect(find.text('THIS WEEK FOR YOU'), findsOneWidget);
    expect(find.text('TRAINING'), findsOneWidget);
    expect(find.text('WHAT\'S GOING ON'), findsOneWidget);
    expect(find.text('Period came early? Log it'), findsOneWidget);

    await tester.ensureVisible(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('THIS WEEK FOR YOU'), findsNothing);
  });

  testWidgets('every phase renders its briefing copy', (tester) async {
    for (final phase in CyclePhase.values) {
      final day = switch (phase) {
        CyclePhase.menstrual => 2,
        CyclePhase.follicular => 9,
        CyclePhase.ovulatory => 15,
        CyclePhase.earlyLuteal => 18,
        CyclePhase.lateLuteal => 25,
      };
      final me = Me.fromJson({
        'id': 'u1',
        'cycle_day': day,
        'cycle_phase': phase.id,
        'cycle_duration': '29',
        'period_duration': '5',
      });
      await pumpScreen(tester, CycleCard(estimate: CycleEstimate.from(me)!));
      expect(find.text('${phase.displayName} · day $day'), findsOneWidget);
    }
  });

  for (final brightness in Brightness.values) {
    testWidgets('card and briefing lay out on a 360 pt phone (${brightness.name})', (tester) async {
      await pumpScreen(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CycleCard(estimate: CycleEstimate.from(_me())!),
          ),
        ),
        size: const Size(360, 740),
        brightness: brightness,
      );
      await tester.tap(find.text('Briefing ›'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
