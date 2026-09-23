import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viv/core/theme/viv_theme.dart';
import 'package:viv/core/utils/dates.dart';
import 'package:viv/data/models/me.dart';
import 'package:viv/data/models/nutrition.dart';
import 'package:viv/data/models/recovery.dart';
import 'package:viv/data/models/weekly_plan.dart';
import 'package:viv/data/providers.dart';
import 'package:viv/features/auth/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements User {}

final fakeMe = Me.fromJson({
  'id': 'u1',
  'name': 'Atziri',
  'onboarding_completed': true,
  'cycle_day': 3,
  'cycle_phase': 'menstrual',
  'cycle_duration': '29',
  'days_late': 2,
  'expected_period_date': Dates.ymd(Dates.today().subtract(const Duration(days: 2))),
  'weight_kg': 64,
  'height_cm': 168,
  'dob': '1991-05-02',
  'training_often': '3-4 times a week',
  'goal_id': 'consistency_wellbeing',
  'created_at': DateTime.now().subtract(const Duration(days: 40)).toIso8601String(),
});

WeeklyPlan fakeWeek() {
  final today = Dates.today();
  final monday = today.subtract(Duration(days: today.weekday - 1));
  final days = <Map<String, dynamic>>[];
  for (var i = 0; i < 7; i++) {
    final d = monday.add(Duration(days: i));
    final training = i.isEven && i < 6;
    days.add({
      'weekday': Dates.longWeekday(d).toLowerCase(),
      'date': Dates.ymd(d),
      'is_today': Dates.ymd(d) == Dates.todayYmd(),
      'is_rest_day': !training,
      if (training) ...{
        'activity_type': i == 2 ? 'yoga' : 'strength',
        'muscle_group': i == 0 ? 'lower' : 'upper',
        'intensity': i == 2 ? 'L' : 'M',
        if (i == 2) 'duration_minutes': 25,
      },
    });
  }
  return WeeklyPlan.fromJson({
    'draft_id': 'd1',
    'start_date': Dates.ymd(monday),
    'end_date': Dates.ymd(monday.add(const Duration(days: 6))),
    'days': days,
  });
}

final fakeDay = DayDetail.fromJson({
  'date': Dates.todayYmd(),
  'weekday': Dates.longWeekday(Dates.today()).toLowerCase(),
  'is_rest_day': false,
  'activity_type': 'strength',
  'muscle_group': 'lower',
  'intensity': 'M',
  'loggable': true,
  'title': 'Lower strength',
  'load_label': 'Moderate load',
  'duration_minutes': 60,
  'warmup': {
    'duration_minutes': 8,
    'movements': ['World\'s greatest stretch', 'Glute bridges'],
  },
  'main_exercises': [
    {
      'id': 'e1',
      'name': 'Front foot elevated split squat',
      'sets': 3,
      'reps': '8-10 / leg',
      'rest_seconds': 90,
    },
    {
      'id': 'e2',
      'name': 'Single-leg Romanian deadlift',
      'sets': 3,
      'reps': '8-10',
      'rest_seconds': 90,
      'form_cue': 'Hinge at the hips, hips square to the floor.',
    },
  ],
  'cooldown': {
    'duration_minutes': 5,
    'movements': ['Deep squat hold', 'Pigeon stretch'],
  },
});

final fakeNutrition = NutritionPlan.fromJson({
  'phase': 'menstrual',
  'targets': {
    'training_day': {'calories': 2470, 'protein_g': 137, 'carbs_g': 249, 'fat_g': 74},
    'rest_day': {'calories': 2100, 'protein_g': 130, 'carbs_g': 200, 'fat_g': 70},
  },
  'water_base_liters': 3.5,
  'copy_enriched': true,
  'days': [
    for (final w in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'])
      {
        'weekday': w,
        'is_training_day': true,
        'macros': {'calories': 2470, 'protein_g': 137},
        'hydration': {'liters': 3.5},
        'meals': [
          {
            'meal_name': 'Breakfast',
            'macro_targets': {'calories': 595, 'protein_g': 38},
            'options': [
              {
                'name': 'Greek yogurt, apple & peanut butter bowl',
                'ingredients': [
                  {'name': 'Greek yogurt', 'amount_g': 200, 'approx': '1 cup'},
                ],
              },
              {'name': 'Eggs on toast, twice over'},
            ],
          },
          {
            'meal_name': 'Lunch',
            'macro_targets': {'calories': 673},
            'options': [
              {'name': 'Almond butter, broccoli & brown rice bowl'},
            ],
          },
        ],
      },
  ],
});

final fakeRecovery = RecoveryCard.fromJson({
  'date': Dates.todayYmd(),
  'is_rest_day': true,
  'cost_tier': 'medium',
  'headline': 'Three things tonight. That\'s the whole list.',
  'primary': {'title': 'Protein within two hours', 'detail': 'A real meal beats a shake.'},
  'secondary': [
    {'title': 'Lights out by 23:00', 'detail': 'Sleep is where strength happens.'},
    {'title': 'Tomorrow is a walk, not a session', 'detail': 'Twenty minutes outside.'},
  ],
  'available_actions': [
    {'kind': 'done', 'label': 'Done'},
    {'kind': 'not_today', 'label': 'Not today'},
  ],
});

/// Signed-in, fully onboarded user with a built week and nutrition plan.
Future<List<Override>> appOverrides() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final auth = MockAuthRepository();
  when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(null));
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    authRepositoryProvider.overrideWithValue(auth),
    authStateProvider.overrideWith((_) => Stream<User?>.value(MockUser())),
    meProvider.overrideWith((_) async => fakeMe),
    currentWeekProvider.overrideWith((_) async => fakeWeek()),
    weeklyNoteProvider.overrideWith((_) async => null),
    dayDetailProvider.overrideWith((_, _) async => fakeDay),
    nutritionPlanProvider.overrideWith((_) async => fakeNutrition),
    recoveryCardProvider.overrideWith((_, _) async => fakeRecovery),
  ];
}

/// Pumps [screen] inside a minimal router + VIV theme.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(390, 844),
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => screen)],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: await appOverrides(),
      child: MaterialApp.router(
        theme: VivTheme.light(),
        darkTheme: VivTheme.dark(),
        themeMode: brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
