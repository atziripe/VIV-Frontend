import 'package:flutter_test/flutter_test.dart';
import 'package:viv/core/utils/dates.dart';
import 'package:viv/data/models/catalog.dart';
import 'package:viv/features/onboarding/onboarding_draft.dart';

void main() {
  final complete = OnboardingDraft(
    situation: CycleSituation.natural,
    name: '  Atziri ',
    dob: DateTime(1996, 4, 12),
    activities: const [ActivityChoice.pilatesBarre, ActivityChoice.strength],
    goal: Goal.strengthMuscle,
    daysPerWeek: DaysPerWeek.threeFour,
    activityLevel: ActivityLevel.deskBound,
    lastPeriod: LastPeriod.aboutAWeek,
    cycleLength: CycleLength.typical,
    periodLength: 5,
  );

  test('maps answers to the exact POST /onboarding values', () {
    final json = complete.toRequest().toJson();
    expect(json['name'], 'Atziri');
    expect(json['dob'], '1996-04-12');
    expect(json['cycle_type'], 'I have a natural menstrual cycle');
    // Tap order is kept (activities[0] = first training day); one pill can
    // expand to several taxonomy ids.
    expect(json['activities'], ['pilates', 'barre', 'strength']);
    expect(json['goal_id'], 'strength_muscle');
    expect(json['training_often'], '3-4 times a week');
    expect(json['daily_activity_level'], 'Desk-bound');
    expect(json['cycle_duration'], '28');
    expect(json['period_duration'], '5');
    expect(json['last_cycle_start'], Dates.ymd(Dates.today().subtract(const Duration(days: 7))));
    // Unset optional fields are omitted, not sent as null.
    expect(json.containsKey('weight_kg'), isFalse);
  });

  test('"Varies" cycle length lets the backend default', () {
    final json = complete.copyWith(cycleLength: CycleLength.varies).toRequest().toJson();
    expect(json.containsKey('cycle_duration'), isFalse);
  });

  test('exact date overrides the rough bucket', () {
    final d = complete.copyWith(lastPeriodExact: DateTime(2026, 9, 2));
    expect(d.toRequest().lastCycleStart, '2026-09-02');
  });

  test('only natural / not sure pass the fit check', () {
    expect(CycleSituation.values.where((s) => s.isFit), [
      CycleSituation.natural,
      CycleSituation.notSure,
    ]);
    expect(CycleSituation.notSure.apiValue, 'not_sure');
  });

  test('step completeness gates Continue', () {
    const empty = OnboardingDraft();
    expect(empty.aboutYouComplete, isFalse);
    expect(empty.trainingComplete, isFalse);
    expect(complete.aboutYouComplete && complete.trainingComplete, isTrue);
    expect(complete.weekComplete && complete.cycleComplete, isTrue);
  });

  test('every activity id is one of the 11 the backend accepts', () {
    const accepted = {
      'strength',
      'pilates',
      'barre',
      'running',
      'cycling',
      'hiit',
      'functional',
      'yoga',
      'mobility',
      'swimming',
      'team_racket_sports',
    };
    final ids = {for (final c in ActivityChoice.values) ...c.activities.map((a) => a.id)};
    expect(ids, accepted);
  });
}
