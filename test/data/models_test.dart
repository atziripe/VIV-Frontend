import 'package:flutter_test/flutter_test.dart';
import 'package:viv/data/models/catalog.dart';
import 'package:viv/data/models/checkin.dart';
import 'package:viv/data/models/cycle.dart';
import 'package:viv/data/models/me.dart';
import 'package:viv/data/models/nutrition.dart';
import 'package:viv/data/models/onboarding.dart';
import 'package:viv/data/models/recovery.dart';
import 'package:viv/data/models/weekly_plan.dart';

// Payloads below are the worked examples from the VIV API reference.
void main() {
  test('Me parses GET /me', () {
    final me = Me.fromJson({
      'id': 'uid',
      'username': '',
      'name': 'Ana Test',
      'onboarding_completed': true,
      'onboarding_completed_int': 1,
      'dob': '1996-04-12',
      'weight_kg': 62,
      'height_cm': 165,
      'cycle_type': 'natural',
      'cycle_day': 12,
      'cycle_phase': 'follicular',
      'cycle_duration': '28',
      'days_late': 0,
      'expected_period_date': '2026-10-20',
      'activities': ['strength', 'yoga', 'running'],
      'goal_id': 'consistency_wellbeing',
      'created_at': '2026-09-01T10:00:00Z',
    });
    expect(me.firstName, 'Ana');
    expect(me.onboardingCompleted, isTrue);
    expect(me.weightKg, 62.0);
    expect(me.cyclePhase, CyclePhase.follicular);
    expect(me.activities, ['strength', 'yoga', 'running']);
    expect(me.hasNutritionPreferences, isFalse);
  });

  test('ProfileUpdate omits unset fields', () {
    expect(const ProfileUpdate(weightKg: 63.5).toJson(), {'weight_kg': 63.5});
    expect(const ProfileUpdate(cycleEstimationDisabled: true).toJson(), {
      'cycle_estimation_disabled': true,
    });
  });

  test('DailyCheckinResult round-trips (used for on-device cache)', () {
    final json = {
      'date': '2026-09-23',
      'recovery_capacity': 'moderate',
      'life_bandwidth': 'moderate',
      'build_readiness': 'maintain',
      'regenerated': false,
      'is_rest_day': false,
      'assignment': {'activity_type': 'strength', 'intensity': 'M', 'impact': 'H'},
      'suggestion': {
        'assignment': {'activity_type': 'yoga', 'intensity': 'L', 'impact': 'L'},
        'reason': 'Low recovery capacity today',
      },
    };
    final r = DailyCheckinResult.fromJson(json);
    expect(r.assignment?.activityType, 'strength');
    expect(r.suggestion?.assignment.activityType, 'yoga');
    final again = DailyCheckinResult.fromJson(r.toJson());
    expect(again.suggestion?.reason, 'Low recovery capacity today');
    expect(again.date, '2026-09-23');
  });

  test('DailyCheckinRequest sends API enum values', () {
    const req = DailyCheckinRequest(
      date: '2026-09-23',
      sleep: SleepAnswer.restless,
      body: BodyAnswer.heavierThanUsual,
      demand: DemandAnswer.packed,
      need: NeedAnswer.meetMeWhereImAt,
    );
    expect(req.toJson(), {
      'date': '2026-09-23',
      'sleep': 'restless',
      'body': 'heavier_than_usual',
      'demand': 'packed',
      'need': 'meet_me_where_im_at',
    });
  });

  test('WeeklyPlan parses current week and finds today/next', () {
    final plan = WeeklyPlan.fromJson({
      'draft_id': 'draft_abc',
      'start_date': '2026-09-21',
      'end_date': '2026-09-27',
      'days': [
        {
          'weekday': 'monday',
          'date': '2026-09-21',
          'is_today': true,
          'is_rest_day': false,
          'activity_type': 'strength',
          'muscle_group': 'lower',
          'intensity': 'M',
          'impact': 'H',
        },
        {'weekday': 'tuesday', 'date': '2026-09-22', 'is_today': false, 'is_rest_day': true},
        {
          'weekday': 'wednesday',
          'date': '2099-01-01',
          'is_today': false,
          'is_rest_day': false,
          'activity_type': 'yoga',
          'intensity': 'L',
          'duration_minutes': 25,
        },
      ],
    });
    expect(plan.today?.title, 'Lower strength');
    expect(plan.today?.subtitle, 'Moderate');
    expect(plan.sessionCount, 2);
    expect(plan.nextSession?.title, 'Easy yoga');
    expect(plan.nextSession?.subtitle, 'Light · 25 min');
  });

  test('DayDetail parses exercises and a resumed session', () {
    final d = DayDetail.fromJson({
      'date': '2026-09-23',
      'weekday': 'tuesday',
      'is_rest_day': false,
      'activity_type': 'strength',
      'muscle_group': 'full_body',
      'loggable': true,
      'title': 'Full Body Strength',
      'duration_minutes': 40,
      'duration_is_estimated': true,
      'warmup': {
        'duration_minutes': 5,
        'description': '...',
        'movements': ['a', 'b'],
      },
      'main_exercises': [
        {'id': 'ex_001', 'name': 'Goblet Squat', 'sets': 3, 'reps': '10-12', 'rest_seconds': 60},
      ],
      'session': {
        'status': 'in_progress',
        'started_at': '2026-09-23T14:00:00Z',
        'sets': [
          {'exercise_id': 'ex_001', 'set_number': 1, 'weight_kg': 18, 'reps': 10},
        ],
      },
    });
    expect(d.loggable, isTrue);
    expect(d.mainExercises.single.prescription, '3 × 10–12');
    expect(d.warmup?.movements, ['a', 'b']);
    expect(d.session?.setFor('ex_001', 1)?.weightKg, 18);
    expect(d.session?.setFor('ex_001', 2), isNull);
  });

  test('NutritionPlan parses a day', () {
    final p = NutritionPlan.fromJson({
      'phase': 'follicular',
      'targets': {
        'training_day': {'calories': 2100, 'protein_g': 130, 'carbs_g': 220, 'fat_g': 65},
        'rest_day': {'calories': 1900, 'protein_g': 120, 'carbs_g': 180, 'fat_g': 62},
      },
      'water_base_liters': 2.2,
      'copy_enriched': false,
      'days': [
        {
          'weekday': 'monday',
          'is_training_day': true,
          'macros': {'calories': 2100, 'protein_g': 130, 'carbs_g': 220, 'fat_g': 65},
          'hydration': {'liters': 2.4, 'glasses': 10, 'show_electrolyte': true},
          'meals': [
            {
              'meal_name': 'Breakfast',
              'timing_window': '7-9am',
              'options': [
                {
                  'name': 'Greek Yogurt Power Bowl',
                  'flag': null,
                  'ingredients': [
                    {'name': 'Greek yogurt', 'amount_g': 200, 'approx': '1 cup'},
                  ],
                },
              ],
            },
          ],
        },
      ],
    });
    expect(p.copyEnriched, isFalse);
    expect(p.targets?.restDay?.proteinG, 120);
    final monday = p.dayFor('Monday')!;
    expect(monday.meals.single.slotKey, 'breakfast');
    expect(monday.meals.single.options.single.ingredients.single.approx, '1 cup');
    expect(p.dayFor('sunday'), isNull);
  });

  test('RecoveryCard keeps only known action kinds', () {
    final r = RecoveryCard.fromJson({
      'date': '2026-09-24',
      'is_rest_day': true,
      'cost_tier': 'medium',
      'headline': 'Your body is still converting yesterday\'s work',
      'primary': {'title': 'Prioritize protein', 'detail': '...'},
      'secondary': [
        {'title': 'Walk', 'detail': '...'},
      ],
      'available_actions': [
        {'kind': 'done', 'label': 'Done'},
        {'kind': 'not_today', 'label': 'Not today'},
        {'kind': 'something_new', 'label': '?'},
      ],
    });
    expect(r.items.map((i) => i.title), ['Prioritize protein', 'Walk']);
    expect(r.availableActions.map((a) => a.kind), [
      RecoveryActionKind.done,
      RecoveryActionKind.notToday,
    ]);
    expect(r.loggedAction, isNull);
  });

  test('PeriodStartResult parses moved days', () {
    final r = PeriodStartResult.fromJson({
      'cycle_day': 1,
      'cycle_summary': {'current_phase': 'menstrual'},
      'cycle_duration_changed': true,
      'previous_cycle_duration': 28,
      'cycle_duration': 34,
      'week_rebuilt': true,
      'moved': [
        {'weekday': 'tuesday', 'date': '2026-09-22', 'is_rest_day': true},
        {
          'weekday': 'wednesday',
          'date': '2026-09-23',
          'is_rest_day': false,
          'title': 'Strength — full body',
          'duration_minutes': 40,
        },
      ],
    });
    expect(r.cycleSummary?.currentPhase, CyclePhase.menstrual);
    expect(r.moved, hasLength(2));
    expect(r.moved.last.durationMinutes, 40);
  });

  test('JobStatus maps states', () {
    expect(JobStatus.fromJson({'status': 'running'}).isFinished, isFalse);
    final done = JobStatus.fromJson({'status': 'done', 'draft_id': 'd1'});
    expect(done.state, JobState.done);
    expect(done.draftId, 'd1');
  });
}
