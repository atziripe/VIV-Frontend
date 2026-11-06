import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:viv/core/utils/dates.dart';
import 'package:viv/data/api/viv_api.dart';
import 'package:viv/data/models/session.dart';
import 'package:viv/data/models/weekly_plan.dart';
import 'package:viv/data/providers.dart';
import 'package:viv/features/training/in_session_screen.dart';
import 'package:viv/features/training/session_detail_screen.dart';

import '../helpers/fakes.dart';

class _MockVivApi extends Mock implements VivApi {}

/// A Strength day served by the real assembly path (VIV-112).
DayDetail _realStrengthDay({String? session}) => DayDetail.fromJson({
  'date': Dates.todayYmd(),
  'weekday': Dates.longWeekday(Dates.today()).toLowerCase(),
  'is_rest_day': false,
  'activity_type': 'strength',
  'muscle_group': 'lower',
  'loggable': true,
  'strength_block_number': 2,
  'strength_week': 3,
  'strength_config_status': 'draft_not_reviewed_by_sport_scientist',
  'strength_warmup_cooldown_status': 'draft_not_reviewed_by_sport_scientist',
  'strength_rest_seconds_status': 'draft_not_reviewed_by_sport_scientist',
  'strength_tier_changes': [
    {'lever': 'load_reduced', 'detail': 'Lighter loads today after a short night.'},
  ],
  'strength_ramp_up_note': 'First week back: keep two reps in reserve on every set.',
  'main_exercises': [
    {
      'id': 'ex1',
      'name': 'Back squat',
      'sets': 2,
      'reps': '',
      'rest_seconds': 120,
      'slot': 'Squat',
      'priority': 'Main',
      'equipment': ['Barbell', 'Rack'],
      'prescription_text': '2 × 8–10 @ RIR 3',
    },
    {
      'id': 'ex2',
      'name': 'Calf raise',
      'sets': 1,
      'priority': 'Optional',
      'rest_seconds': 0,
      'prescription_text': '1 × 15 @ RIR 2',
    },
  ],
  if (session != null) 'session': {'status': session, 'sets': <Object>[]},
});

void main() {
  test('real Strength path fields parse; rest comes from the plan', () {
    final d = _realStrengthDay();
    expect(d.strengthBlockNumber, 2);
    expect(d.strengthWeek, 3);
    expect(d.strengthTierChanges.single.lever, 'load_reduced');
    expect(d.strengthRestSecondsStatus, 'draft_not_reviewed_by_sport_scientist');
    final e = d.mainExercises.first;
    expect(e.restSeconds, 120);
    // 0 is never valid rest: read as "not given".
    expect(d.mainExercises.last.restSeconds, isNull);
    expect(e.reps, isNull);
    expect(e.priority, ExercisePriority.main);
    expect(e.equipment, ['Barbell', 'Rack']);
    expect(e.prescription, '2 × 8–10 @ RIR 3');
    expect(e.takesRir, isTrue);
    // The older path is unchanged.
    expect(fakeDay.mainExercises.first.takesRir, isFalse);
  });

  test('traceability flags read as words, never dropped', () {
    expect(
      strengthStatusText('draft_not_reviewed_by_sport_scientist'),
      'Draft program, not yet reviewed by a sport scientist.',
    );
    expect(strengthStatusText('something_new'), 'Something new.');
  });

  testWidgets('session detail shows the real Strength path', (tester) async {
    final day = _realStrengthDay();
    await pumpScreen(
      tester,
      SessionDetailScreen(date: day.date),
      extra: [dayDetailProvider(day.date).overrideWith((_) async => day)],
    );
    expect(find.text('Block 2 · week 3'), findsOneWidget);
    expect(find.text('ADJUSTED TODAY'), findsOneWidget);
    expect(find.text('Lighter loads today after a short night.'), findsOneWidget);
    expect(find.text('First week back: keep two reps in reserve on every set.'), findsOneWidget);
    expect(find.text('2 × 8–10 @ RIR 3'), findsOneWidget);
    expect(find.text('Barbell · Rack'), findsOneWidget);
    expect(find.text('Optional'), findsOneWidget);
    expect(find.textContaining('not yet reviewed by a sport scientist'), findsOneWidget);
    expect(find.textContaining('Rest times: draft program'), findsOneWidget);
  });

  group('live session', () {
    late _MockVivApi api;
    final empty = SessionLog.fromJson({'status': 'in_progress', 'sets': <Object>[]});

    setUp(() {
      api = _MockVivApi();
      when(() => api.startSession(any())).thenAnswer((_) async => empty);
      when(
        () => api.logSet(
          date: any(named: 'date'),
          exerciseId: any(named: 'exerciseId'),
          setNumber: any(named: 'setNumber'),
          weightKg: any(named: 'weightKg'),
          reps: any(named: 'reps'),
          rir: any(named: 'rir'),
        ),
      ).thenAnswer((_) async => empty);
    });

    Future<void> pumpLive(WidgetTester tester) async {
      final day = _realStrengthDay();
      await pumpScreen(
        tester,
        InSessionScreen(date: day.date),
        extra: [
          vivApiProvider.overrideWithValue(api),
          dayDetailProvider(day.date).overrideWith((_) async => day),
        ],
      );
    }

    testWidgets('back mid-workout asks before leaving', (tester) async {
      await pumpLive(tester);
      final popped = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(popped, isTrue); // handled by the session, not the system
      expect(find.text('End session?'), findsOneWidget);
      expect(find.text('Keep going'), findsOneWidget);
    });

    testWidgets('ramp-up note before the first set; RIR sent only when picked', (tester) async {
      await pumpLive(tester);
      expect(find.text('2 × 8–10 @ RIR 3'), findsOneWidget);
      expect(find.text('First week back: keep two reps in reserve on every set.'), findsOneWidget);
      expect(find.text('REPS LEFT IN THE TANK'), findsOneWidget);

      // Nothing picked → rir omitted.
      await tester.tap(find.text('Log set 1'));
      await tester.pump();
      verify(
        () => api.logSet(
          date: any(named: 'date'),
          exerciseId: 'ex1',
          setNumber: 1,
          weightKg: any(named: 'weightKg'),
          reps: any(named: 'reps'),
          rir: null,
        ),
      ).called(1);

      // The plan's own rest for this exercise.
      expect(find.text('2:00'), findsOneWidget);
      await tester.tap(find.text('Skip rest'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('Log set 2'));
      await tester.pump();
      verify(
        () => api.logSet(
          date: any(named: 'date'),
          exerciseId: 'ex1',
          setNumber: 2,
          weightKg: any(named: 'weightKg'),
          reps: any(named: 'reps'),
          rir: 2,
        ),
      ).called(1);
    });
  });
}
