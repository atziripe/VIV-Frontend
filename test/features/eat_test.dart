import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:viv/data/models/nutrition.dart';
import 'package:viv/features/nutrition/meal_image.dart';
import 'package:viv/features/nutrition/eat_screen.dart';
import 'package:viv/features/nutrition/full_targets_screen.dart';
import 'package:viv/features/nutrition/meal_detail_screen.dart';
import 'package:viv/features/nutrition/nutrition_format.dart';

import '../helpers/fakes.dart';

final _mealRoute = GoRoute(
  path: '/eat/meal/:weekday/:slot',
  builder: (_, s) => MealDetailScreen(
    weekday: s.pathParameters['weekday']!,
    slotIndex: int.parse(s.pathParameters['slot']!),
  ),
);

void main() {
  test('nutrition numbers are rounded on purpose', () {
    expect(grams(136.6), '137 g');
    expect(liters(3.0), '3 L');
    expect(liters(3.46), '3.5 L');
    expect(kcal(2470), '~2,470 kcal');
  });

  testWidgets('Eat: protein field, meals, and the targets link', (tester) async {
    await pumpScreen(tester, const EatScreen());
    expect(find.text('PROTEIN TODAY'), findsOneWidget);
    expect(find.text('137 g'), findsOneWidget);
    expect(find.text('about 69 g\na meal'), findsOneWidget);
    expect(find.text('0 g in'), findsOneWidget);
    expect(find.text('BREAKFAST · 38 G'), findsOneWidget);
    expect(find.text('Greek yogurt, apple & peanut butter bowl'), findsOneWidget);
    expect(find.text('Full targets · water 3.5 L'), findsOneWidget);
    // Only slots with alternatives offer a swap.
    expect(find.text('Swap'), findsOneWidget);
  });

  testWidgets('Cooked it fills the protein bar back on Eat', (tester) async {
    await pumpScreen(tester, const EatScreen(), extraRoutes: [_mealRoute]);
    await tester.tap(find.text('Greek yogurt, apple & peanut butter bowl'));
    await tester.pumpAndSettle();

    expect(find.text('Cooked it'), findsOneWidget);
    await tester.tap(find.text('Cooked it'));
    await tester.pumpAndSettle();
    expect(find.text('Cooked'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('38 g in · breakfast done'), findsOneWidget);
  });

  testWidgets('Swap sheet lists the options with protein only', (tester) async {
    await pumpScreen(tester, const EatScreen());
    await tester.tap(find.text('Swap'));
    await tester.pumpAndSettle();
    expect(find.text('Swap breakfast'), findsOneWidget);
    expect(find.text('Eggs on toast, twice over'), findsOneWidget);
    expect(find.text('38 g'), findsNWidgets(2));
    expect(find.text('Swap it in'), findsOneWidget);
    expect(find.textContaining('suggest'), findsNothing);
  });

  testWidgets('Full targets toggles between training and rest day', (tester) async {
    await pumpScreen(tester, const FullTargetsScreen());
    expect(find.text('137 g'), findsOneWidget);
    expect(find.text('~2,470 kcal'), findsOneWidget);
    await tester.tap(find.text('Rest day'));
    await tester.pumpAndSettle();
    expect(find.text('130 g'), findsOneWidget);
    expect(find.text('~2,100 kcal'), findsOneWidget);
  });

  test('plan parses dish and ingredient images, option macros and selections', () {
    final plan = NutritionPlan.fromJson({
      'meal_selections': {
        'Monday': {'breakfast': 1, 'lunch': 0},
      },
      'days': [
        {
          'weekday': 'monday',
          'meals': [
            {
              'meal_name': 'Breakfast',
              'options': [
                {
                  'name': 'Asian Bowl',
                  'macros': {'calories': 450, 'protein_g': 35},
                  'image_url': 'https://img.example/bowl.jpg',
                  'ingredients': [
                    {'name': 'Chicken breast', 'image_url': 'https://img.example/chicken.jpg'},
                    {'name': 'Avocado'},
                  ],
                },
              ],
            },
          ],
        },
      ],
    });
    expect(plan.mealSelections, {
      'monday': {'breakfast': 1, 'lunch': 0},
    });
    final option = plan.days.single.meals.single.options.single;
    expect(option.imageUrl, 'https://img.example/bowl.jpg');
    expect(option.macros?.proteinG, 35);
    expect(option.ingredients.first.imageUrl, 'https://img.example/chicken.jpg');
    expect(option.ingredients.last.imageUrl, isNull);
  });

  testWidgets('dish photos show on Eat and in the meal detail, with ingredients', (tester) async {
    await pumpScreen(tester, const EatScreen(), extraRoutes: [_mealRoute]);
    final rowImage = tester.widget<MealImage>(find.byType(MealImage).first);
    expect(rowImage.url, 'https://img.example/breakfast_bowl.jpg');

    await tester.tap(find.text('Greek yogurt, apple & peanut butter bowl'));
    await tester.pumpAndSettle();
    final urls = tester.widgetList<MealImage>(find.byType(MealImage)).map((m) => m.url).toList();
    // Hero, then one per ingredient: a missing image keeps the placeholder.
    expect(urls, [
      'https://img.example/breakfast_bowl.jpg',
      'https://img.example/yogurt.jpg',
      null,
    ]);
  });

  testWidgets('the backend\'s meal_selections picks the option shown', (tester) async {
    final weekday = todayWeekday();
    final base = fakeNutrition;
    final plan = NutritionPlan(
      targets: base.targets,
      copyEnriched: true,
      mealSelections: {
        weekday: {'breakfast': 1},
      },
      days: base.days,
    );
    await pumpScreen(tester, const EatScreen(), nutrition: plan);
    expect(find.text('Eggs on toast, twice over'), findsOneWidget);
    expect(find.text('Greek yogurt, apple & peanut butter bowl'), findsNothing);
  });
}
